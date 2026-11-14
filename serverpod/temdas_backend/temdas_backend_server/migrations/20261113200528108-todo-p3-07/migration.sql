BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "todos" ADD COLUMN "titulo" text;

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261113200528108-todo-p3-07', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261113200528108-todo-p3-07', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

COMMIT;
