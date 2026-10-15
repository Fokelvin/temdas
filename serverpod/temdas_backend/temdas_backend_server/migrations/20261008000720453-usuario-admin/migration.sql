BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "usuarios" ADD COLUMN "isAdmin" boolean NOT NULL DEFAULT false;

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261008000720453-usuario-admin', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261008000720453-usuario-admin', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
