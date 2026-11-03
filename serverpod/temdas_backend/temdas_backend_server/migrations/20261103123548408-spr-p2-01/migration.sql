BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = public, pg_catalog;
DO $baseline$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.serverpod_migrations
    WHERE module = 'temdas_backend' AND version = '20261029220000000-restore-schema-guards')
    OR NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'sprints_demandas_validar_vinculo_aberto' AND tgrelid = 'public.sprints_demandas'::regclass AND NOT tgisinternal)
    OR NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'sprints_validar_reabertura' AND tgrelid = 'public.sprints'::regclass AND NOT tgisinternal) THEN
    RAISE EXCEPTION 'spr_p2_01_unexpected_baseline';
  END IF;
END;
$baseline$;
LOCK TABLE public.demandas, public.sprints, public.sprints_demandas IN SHARE ROW EXCLUSIVE MODE;


--
-- ACTION ALTER TABLE
--
CREATE INDEX "sprints_demandas_demanda_idx" ON "sprints_demandas" USING btree ("demandaId");

CREATE OR REPLACE FUNCTION "temdas_validar_vinculo_sprint_aberta"()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE destino public.sprints%ROWTYPE;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'));
    SELECT * INTO destino FROM public.sprints WHERE id = NEW."sprintId" FOR KEY SHARE;
    IF destino.status NOT IN ('planejada', 'ativa') THEN
        RAISE EXCEPTION 'A sprint não aceita novos vínculos.' USING ERRCODE = '23514';
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.sprints_demandas v
        JOIN public.sprints s ON s.id = v."sprintId"
        WHERE v."demandaId" = NEW."demandaId" AND s.id <> destino.id
          AND s.status IN ('planejada', 'ativa')
          AND s."dataInicio" <= destino."dataFim" AND s."dataFim" >= destino."dataInicio"
    ) THEN
        RAISE EXCEPTION 'O período conflita com outra sprint vinculada.' USING ERRCODE = '23505';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION "temdas_validar_reabertura_sprint"()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.status NOT IN ('planejada', 'ativa') THEN RETURN NEW; END IF;
    PERFORM pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'));
    IF EXISTS (
        SELECT 1 FROM public.sprints_demandas proprio
        JOIN public.sprints_demandas outro ON outro."demandaId" = proprio."demandaId" AND outro."sprintId" <> NEW.id
        JOIN public.sprints s ON s.id = outro."sprintId"
        WHERE proprio."sprintId" = NEW.id AND s.status IN ('planejada', 'ativa')
          AND s."dataInicio" <= NEW."dataFim" AND s."dataFim" >= NEW."dataInicio"
    ) THEN
        RAISE EXCEPTION 'A reabertura conflita com outra sprint vinculada.' USING ERRCODE = '23505';
    END IF;
    IF EXISTS (
        SELECT 1 FROM public.sprints_demandas v JOIN public.demandas d ON d.id = v."demandaId"
        WHERE v."sprintId" = NEW.id AND (d."usuarioId" <> NEW."usuarioId"
          OR (d."demandaPaiId" IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM public.sprints_demandas p WHERE p."sprintId" = NEW.id AND p."demandaId" = d."demandaPaiId"))
          OR EXISTS (SELECT 1 FROM public.demandas f WHERE f."demandaPaiId" = d.id AND NOT EXISTS (
            SELECT 1 FROM public.sprints_demandas vf WHERE vf."sprintId" = NEW.id AND vf."demandaId" = f.id)))
    ) THEN
        RAISE EXCEPTION 'A hierarquia dos vínculos da sprint mudou.' USING ERRCODE = '23514';
    END IF;
    RETURN NEW;
END;
$$;

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261103123548408-spr-p2-01', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261103123548408-spr-p2-01', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
