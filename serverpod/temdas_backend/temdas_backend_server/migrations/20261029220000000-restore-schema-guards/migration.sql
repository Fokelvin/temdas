BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = public, pg_catalog;
DO $baseline$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.serverpod_migrations
    WHERE module = 'temdas_backend' AND version = '20261029183226724-pacote4-demandas') THEN
    RAISE EXCEPTION 'restore_guards_unexpected_baseline';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname LIKE 'temdas\_%' ESCAPE '\')
    OR EXISTS (SELECT 1 FROM pg_trigger WHERE NOT tgisinternal AND tgrelid IN
      ('public.demandas'::regclass,'public.sprints'::regclass,'public.sprints_demandas'::regclass))
    OR EXISTS (SELECT 1 FROM pg_constraint WHERE conname IN
      ('sprints_periodo_valido_check','emails_whitelist_email_normalizado_check')
      AND connamespace='public'::regnamespace) THEN
    RAISE EXCEPTION 'restore_guards_unexpected_existing_objects';
  END IF;
END;
$baseline$;
LOCK TABLE public.demandas, public.sprints, public.sprints_demandas, public.emails_whitelist IN SHARE ROW EXCLUSIVE MODE;
DO $integrity$
BEGIN
  IF EXISTS (SELECT 1 FROM public.demandas d JOIN public.demandas p ON p.id=d."demandaPaiId"
    WHERE d."usuarioId" IS DISTINCT FROM p."usuarioId")
    OR EXISTS (SELECT 1 FROM public.sprints_demandas sd JOIN public.sprints s ON s.id=sd."sprintId"
      JOIN public.demandas d ON d.id=sd."demandaId" WHERE s."usuarioId" IS DISTINCT FROM d."usuarioId")
    OR EXISTS (SELECT sd."demandaId" FROM public.sprints_demandas sd JOIN public.sprints s ON s.id=sd."sprintId"
      WHERE s.status IN ('planejada','ativa') GROUP BY sd."demandaId" HAVING count(DISTINCT sd."sprintId")>1) THEN
    RAISE EXCEPTION 'restore_guards_existing_data_violates_invariants';
  END IF;
END;
$integrity$;
-- Existing custom triggers/checks retained verbatim for clean installations.
ALTER TABLE "sprints"
    ADD CONSTRAINT "sprints_periodo_valido_check"
    CHECK ("dataInicio" <= "dataFim");
-- PostgreSQL triggers preserve the cross-table invariant that one demand can
-- belong to at most one planned or active sprint. The transaction advisory
-- lock is the same one used by SprintEndpoint and inheritance on child create.
CREATE OR REPLACE FUNCTION "temdas_validar_vinculo_sprint_aberta"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    status_destino text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'));

    SELECT "status"
    INTO status_destino
    FROM "sprints"
    WHERE "id" = NEW."sprintId"
    FOR KEY SHARE;

    IF status_destino NOT IN ('planejada', 'ativa') THEN
        RAISE EXCEPTION 'A sprint não aceita novos vínculos.'
            USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM "sprints_demandas" AS vinculo
        INNER JOIN "sprints" AS sprint ON sprint."id" = vinculo."sprintId"
        WHERE vinculo."demandaId" = NEW."demandaId"
          AND vinculo."sprintId" <> NEW."sprintId"
          AND sprint."status" IN ('planejada', 'ativa')
    ) THEN
        RAISE EXCEPTION 'A demanda já pertence a outra sprint aberta.'
            USING ERRCODE = '23505';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER "sprints_demandas_validar_vinculo_aberto"
BEFORE INSERT OR UPDATE OF "sprintId", "demandaId" ON "sprints_demandas"
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_vinculo_sprint_aberta"();

CREATE OR REPLACE FUNCTION "temdas_validar_reabertura_sprint"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW."status" NOT IN ('planejada', 'ativa') THEN
        RETURN NEW;
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'));

    IF EXISTS (
        SELECT 1
        FROM "sprints_demandas" AS proprio
        INNER JOIN "sprints_demandas" AS outro
            ON outro."demandaId" = proprio."demandaId"
           AND outro."sprintId" <> NEW."id"
        INNER JOIN "sprints" AS sprint ON sprint."id" = outro."sprintId"
        WHERE proprio."sprintId" = NEW."id"
          AND sprint."status" IN ('planejada', 'ativa')
    ) THEN
        RAISE EXCEPTION 'A reabertura criaria demandas em mais de uma sprint aberta.'
            USING ERRCODE = '23505';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER "sprints_validar_reabertura"
BEFORE UPDATE OF "status" ON "sprints"
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_reabertura_sprint"();

-- A conclusão preserva os vínculos como histórico. A exclusão de qualquer
-- demanda desse histórico precisa falhar também fora dos endpoints.
CREATE OR REPLACE FUNCTION "temdas_proteger_historico_sprint_concluida"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'));

    IF EXISTS (
        SELECT 1
        FROM "sprints_demandas" AS vinculo
        INNER JOIN "sprints" AS sprint ON sprint."id" = vinculo."sprintId"
        WHERE vinculo."demandaId" = OLD."id"
          AND sprint."status" = 'concluida'
    ) THEN
        RAISE EXCEPTION 'A demanda possui histórico em sprint concluída e não pode ser excluída.'
            USING ERRCODE = '23503';
    END IF;

    RETURN OLD;
END;
$$;

CREATE TRIGGER "demandas_proteger_historico_sprint_concluida"
BEFORE DELETE ON "demandas"
FOR EACH ROW
EXECUTE FUNCTION "temdas_proteger_historico_sprint_concluida"();


-- Only normalized, non-empty e-mails may enter the whitelist.
ALTER TABLE "emails_whitelist"
    ADD CONSTRAINT "emails_whitelist_email_normalizado_check"
    CHECK (
        "emailNormalizado" <> ''
        AND "emailNormalizado" = lower(btrim("emailNormalizado"))
    );

-- Deferred validation permits a complete parent/child tree to be assigned
-- to one owner in a single backfill transaction.
CREATE OR REPLACE FUNCTION "temdas_validar_owner_demanda_filha"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    pai_id bigint;
    owner_id bigint;
    owner_pai bigint;
BEGIN
    SELECT "demandaPaiId", "usuarioId"
      INTO pai_id, owner_id
      FROM "demandas"
     WHERE "id" = NEW."id";

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    IF pai_id IS NOT NULL THEN
        SELECT "usuarioId" INTO owner_pai
          FROM "demandas"
         WHERE "id" = pai_id;

        IF owner_id IS DISTINCT FROM owner_pai THEN
            RAISE EXCEPTION 'Demanda filha e demanda pai devem ter o mesmo usuário.'
                USING ERRCODE = '23514';
        END IF;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM "demandas" AS filha
         WHERE filha."demandaPaiId" = NEW."id"
           AND filha."usuarioId" IS DISTINCT FROM owner_id
    ) THEN
        RAISE EXCEPTION 'Demanda filha e demanda pai devem ter o mesmo usuário.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER "demandas_validar_owner_filha"
AFTER INSERT OR UPDATE ON "demandas"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_owner_demanda_filha"();

-- A link inherits ownership from both sides; neither side may be reassigned
-- to a different user while the link remains.
CREATE OR REPLACE FUNCTION "temdas_validar_owner_vinculo_sprint"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    owners_diferentes boolean;
BEGIN
    IF TG_TABLE_NAME = 'sprints_demandas' THEN
        SELECT s."usuarioId" IS DISTINCT FROM d."usuarioId"
          INTO owners_diferentes
          FROM "sprints_demandas" AS sd
          JOIN "sprints" AS s ON s."id" = sd."sprintId"
          JOIN "demandas" AS d ON d."id" = sd."demandaId"
         WHERE sd."id" = NEW."id";
    ELSIF TG_TABLE_NAME = 'sprints' THEN
        SELECT EXISTS (
            SELECT 1
              FROM "sprints_demandas" AS sd
              JOIN "demandas" AS d ON d."id" = sd."demandaId"
             WHERE sd."sprintId" = NEW."id"
               AND d."usuarioId" IS DISTINCT FROM
                   (SELECT "usuarioId" FROM "sprints" WHERE "id" = NEW."id")
        ) INTO owners_diferentes;
    ELSE
        SELECT EXISTS (
            SELECT 1
              FROM "sprints_demandas" AS sd
              JOIN "sprints" AS s ON s."id" = sd."sprintId"
             WHERE sd."demandaId" = NEW."id"
               AND s."usuarioId" IS DISTINCT FROM
                   (SELECT "usuarioId" FROM "demandas" WHERE "id" = NEW."id")
        ) INTO owners_diferentes;
    END IF;

    IF owners_diferentes THEN
        RAISE EXCEPTION 'Sprint e demanda vinculadas devem ter o mesmo usuário.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER "sprints_demandas_validar_owner"
AFTER INSERT OR UPDATE ON "sprints_demandas"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_owner_vinculo_sprint"();

CREATE CONSTRAINT TRIGGER "sprints_validar_owner_vinculos"
AFTER UPDATE ON "sprints"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_owner_vinculo_sprint"();

CREATE CONSTRAINT TRIGGER "demandas_validar_owner_vinculos"
AFTER UPDATE ON "demandas"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_owner_vinculo_sprint"();


UPDATE public.serverpod_migrations SET version='20261029220000000-restore-schema-guards', timestamp=now() WHERE module='temdas_backend';
COMMIT;
