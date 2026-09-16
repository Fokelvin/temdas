BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "demandas" ADD COLUMN "motivoCancelamento" text;

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20260914133001923-transicoes-status', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260914133001923-transicoes-status', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
