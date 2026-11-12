BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "todos" ADD COLUMN "linhas" json;

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261112232344804-todos-checklists', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261112232344804-todos-checklists', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
