BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "demandas" ADD COLUMN "ordem" bigint;

-- Preserve the existing listing order (criadoEm DESC) for root demands,
-- independently inside each status. Children intentionally remain NULL.
WITH numeradas AS (
    SELECT
        "id",
        ROW_NUMBER() OVER (
            PARTITION BY "status"
            ORDER BY "criadoEm" DESC, "id" DESC
        ) - 1 AS "ordem"
    FROM "demandas"
    WHERE "demandaPaiId" IS NULL
)
UPDATE "demandas" AS demanda
SET "ordem" = numeradas."ordem"
FROM numeradas
WHERE demanda."id" = numeradas."id";

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20260917173648747-etapa3a-ordem', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260917173648747-etapa3a-ordem', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
