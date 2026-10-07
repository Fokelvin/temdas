BEGIN;

-- Keep the audit and schema changes atomic, including concurrent writers.
LOCK TABLE "demandas", "sprints", "sprints_demandas" IN ACCESS EXCLUSIVE MODE;

DO $$
DECLARE
    demandas_sem_usuario bigint;
    sprints_sem_usuario bigint;
    vinculos_divergentes bigint;
    hierarquias_divergentes bigint;
BEGIN
    SELECT count(*) INTO demandas_sem_usuario
      FROM "demandas" WHERE "usuarioId" IS NULL;
    SELECT count(*) INTO sprints_sem_usuario
      FROM "sprints" WHERE "usuarioId" IS NULL;
    SELECT count(*) INTO vinculos_divergentes
      FROM "sprints_demandas" AS sd
      JOIN "sprints" AS s ON s."id" = sd."sprintId"
      JOIN "demandas" AS d ON d."id" = sd."demandaId"
     WHERE s."usuarioId" IS DISTINCT FROM d."usuarioId";
    SELECT count(*) INTO hierarquias_divergentes
      FROM "demandas" AS filha
      JOIN "demandas" AS pai ON pai."id" = filha."demandaPaiId"
     WHERE filha."usuarioId" IS DISTINCT FROM pai."usuarioId";

    IF demandas_sem_usuario > 0 OR sprints_sem_usuario > 0
       OR vinculos_divergentes > 0 OR hierarquias_divergentes > 0 THEN
        RAISE EXCEPTION
            'ownership-required abortada: demandas sem usuário=%, sprints sem usuário=%, vínculos Sprint/Demanda divergentes=%, hierarquias pai/filha divergentes=%. Corrija as inconsistências antes de aplicar a migration.',
            demandas_sem_usuario, sprints_sem_usuario,
            vinculos_divergentes, hierarquias_divergentes
            USING ERRCODE = '23514';
    END IF;
END;
$$;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "demandas" ALTER COLUMN "usuarioId" SET NOT NULL;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "sprints" ALTER COLUMN "usuarioId" SET NOT NULL;

-- The legacy NULL bucket is no longer a valid domain state.
DROP INDEX "sprints_nome_normalizado_sem_usuario_idx";
DROP INDEX "sprints_uma_ativa_sem_usuario_idx";
ALTER TABLE "sprints"
    DROP CONSTRAINT "sprints_periodos_sem_sobreposicao_sem_usuario";

-- Keep the per-user rules and remove their now-redundant owner predicates.
-- sprints_nome_normalizado_idx (usuarioId, nomeNormalizado) is unchanged.
DROP INDEX "sprints_uma_ativa_por_usuario_idx";
CREATE UNIQUE INDEX "sprints_uma_ativa_por_usuario_idx"
    ON "sprints" ("usuarioId") WHERE "status" = 'ativa';

ALTER TABLE "sprints"
    DROP CONSTRAINT "sprints_periodos_sem_sobreposicao_por_usuario";
ALTER TABLE "sprints"
    ADD CONSTRAINT "sprints_periodos_sem_sobreposicao_por_usuario"
    EXCLUDE USING gist (
        "usuarioId" WITH =,
        daterange("dataInicio"::date, "dataFim"::date, '[]') WITH &&
    ) WHERE ("status" IN ('planejada', 'ativa', 'concluida'));

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261007002904636-ownership-required', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261007002904636-ownership-required', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
