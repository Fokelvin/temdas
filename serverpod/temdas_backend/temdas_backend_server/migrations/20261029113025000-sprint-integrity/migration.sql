BEGIN;

-- Custom Sprint objects are not represented by the Serverpod model generator.
-- Keep this block in the complete definition of future migrations as well.
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
SET LOCAL search_path = pg_catalog, public;
LOCK TABLE public.sprints IN ACCESS EXCLUSIVE MODE;
LOCK TABLE public.serverpod_migrations IN SHARE ROW EXCLUSIVE MODE;

DO $baseline$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.serverpod_migrations
                   WHERE module = 'temdas_backend'
                     AND version = '20261009000123093-convite-cooldown') THEN
        RAISE EXCEPTION 'sprint_integrity_unexpected_baseline';
    END IF;
END;
$baseline$;


DO $sprint_integrity$
BEGIN
    IF to_regclass('public.sprints_uma_ativa_por_usuario_idx') IS NOT NULL
       OR to_regclass('public.sprints_periodos_sem_sobreposicao_por_usuario') IS NOT NULL
       OR EXISTS (SELECT 1 FROM pg_constraint
                  WHERE conrelid = 'public.sprints'::regclass
                    AND conname = 'sprints_periodos_sem_sobreposicao_por_usuario') THEN
        RAISE EXCEPTION 'sprint_integrity_unexpected_existing_object';
    END IF;
    IF EXISTS (SELECT 1 FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
               WHERE e.extname = 'btree_gist'
                 AND (n.nspname <> 'extensions' OR e.extversion <> '1.7')) THEN
        RAISE EXCEPTION 'sprint_integrity_incompatible_extension';
    END IF;
END;
$sprint_integrity$;

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA extensions VERSION '1.7';

CREATE UNIQUE INDEX "sprints_uma_ativa_por_usuario_idx"
    ON public.sprints USING btree ("usuarioId")
    WHERE "status" = 'ativa';

ALTER TABLE public.sprints
    ADD CONSTRAINT "sprints_periodos_sem_sobreposicao_por_usuario"
    EXCLUDE USING gist (
        "usuarioId" extensions.gist_int8_ops WITH =,
        daterange("dataInicio"::date, "dataFim"::date, '[]') WITH &&
    ) WHERE ("status" IN ('planejada', 'ativa', 'concluida'));

-- MIGRATION VERSION FOR temdas_backend
INSERT INTO public.serverpod_migrations ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261029113025000-sprint-integrity', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261029113025000-sprint-integrity', "timestamp" = now();

COMMIT;
