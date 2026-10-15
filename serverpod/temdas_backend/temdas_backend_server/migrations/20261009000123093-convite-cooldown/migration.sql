BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "emails_whitelist" ADD COLUMN "ultimoConviteEm" timestamp without time zone;
ALTER TABLE "emails_whitelist" ADD COLUMN "conviteReservaId" text;
ALTER TABLE "emails_whitelist" ADD COLUMN "conviteReservadoAte" timestamp without time zone;

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261009000123093-convite-cooldown', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261009000123093-convite-cooldown', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
