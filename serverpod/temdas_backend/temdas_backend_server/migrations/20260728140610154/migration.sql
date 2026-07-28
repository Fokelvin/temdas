BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "demandas" (
    "id" bigserial PRIMARY KEY,
    "titulo" text NOT NULL,
    "descricao" text,
    "status" text NOT NULL,
    "prioridade" text NOT NULL,
    "sprint" text,
    "tempoEstimadoMinutos" bigint NOT NULL,
    "tempoExecutadoMinutos" bigint NOT NULL,
    "observacoes" text,
    "criadoEm" timestamp without time zone NOT NULL,
    "atualizadoEm" timestamp without time zone NOT NULL,
    "concluidoEm" timestamp without time zone
);


--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20260728140610154', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260728140610154', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
