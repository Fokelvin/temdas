BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "demandas" ADD COLUMN "localizacao" text NOT NULL DEFAULT 'demandas'::text;

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261111180305263-backlog-p2-01', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261111180305263-backlog-p2-01', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
