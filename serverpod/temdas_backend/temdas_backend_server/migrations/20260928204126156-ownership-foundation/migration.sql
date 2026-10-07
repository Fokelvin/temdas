BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "demandas" DROP CONSTRAINT IF EXISTS "demandas_fk_0";
ALTER TABLE "demandas" ADD COLUMN "usuarioId" bigint;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "emails_whitelist" (
    "id" bigserial PRIMARY KEY,
    "emailNormalizado" text NOT NULL,
    "utilizadoEm" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "emails_whitelist_email_normalizado_idx" ON "emails_whitelist" USING btree ("emailNormalizado");

--
-- ACTION ALTER TABLE
--
DROP INDEX "sprints_nome_normalizado_idx";
ALTER TABLE "sprints" ADD COLUMN "usuarioId" bigint;
CREATE UNIQUE INDEX "sprints_nome_normalizado_idx" ON "sprints" USING btree ("usuarioId", "nomeNormalizado");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "usuarios" (
    "id" bigserial PRIMARY KEY,
    "supabaseUserId" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "usuarios_supabase_user_id_idx" ON "usuarios" USING btree ("supabaseUserId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "demandas"
    ADD CONSTRAINT "demandas_fk_1"
    FOREIGN KEY("demandaPaiId")
    REFERENCES "demandas"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "demandas"
    ADD CONSTRAINT "demandas_fk_0"
    FOREIGN KEY("usuarioId")
    REFERENCES "usuarios"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "sprints"
    ADD CONSTRAINT "sprints_fk_0"
    FOREIGN KEY("usuarioId")
    REFERENCES "usuarios"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

-- Preserve a single legacy bucket while usuarioId is nullable.
CREATE UNIQUE INDEX "sprints_nome_normalizado_sem_usuario_idx"
    ON "sprints" ("nomeNormalizado") WHERE "usuarioId" IS NULL;

DROP INDEX "sprints_uma_ativa_idx";
CREATE UNIQUE INDEX "sprints_uma_ativa_por_usuario_idx"
    ON "sprints" ("usuarioId")
    WHERE "status" = 'ativa' AND "usuarioId" IS NOT NULL;
CREATE UNIQUE INDEX "sprints_uma_ativa_sem_usuario_idx"
    ON "sprints" ((1))
    WHERE "status" = 'ativa' AND "usuarioId" IS NULL;

CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE "sprints" DROP CONSTRAINT "sprints_periodos_sem_sobreposicao";
ALTER TABLE "sprints"
    ADD CONSTRAINT "sprints_periodos_sem_sobreposicao_por_usuario"
    EXCLUDE USING gist (
        "usuarioId" WITH =,
        daterange("dataInicio"::date, "dataFim"::date, '[]') WITH &&
    ) WHERE (
        "usuarioId" IS NOT NULL
        AND "status" IN ('planejada', 'ativa', 'concluida')
    );
ALTER TABLE "sprints"
    ADD CONSTRAINT "sprints_periodos_sem_sobreposicao_sem_usuario"
    EXCLUDE USING gist (
        daterange("dataInicio"::date, "dataFim"::date, '[]') WITH &&
    ) WHERE (
        "usuarioId" IS NULL
        AND "status" IN ('planejada', 'ativa', 'concluida')
    );

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

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20260928204126156-ownership-foundation', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260928204126156-ownership-foundation', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
