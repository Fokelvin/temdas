BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "demandas" ADD COLUMN "demandaPaiId" bigint;
CREATE INDEX "demandas_demanda_pai_id_idx" ON "demandas" USING btree ("demandaPaiId");
--
-- ACTION CREATE TABLE
--
CREATE TABLE "registros_tempo" (
    "id" bigserial PRIMARY KEY,
    "demandaId" bigint NOT NULL,
    "inicioEm" timestamp without time zone NOT NULL,
    "duracaoMinutos" bigint NOT NULL,
    "criadoEm" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "registros_tempo_inicio_em_idx" ON "registros_tempo" USING btree ("inicioEm");
CREATE INDEX "registros_tempo_demanda_inicio_em_idx" ON "registros_tempo" USING btree ("demandaId", "inicioEm");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "demandas"
    ADD CONSTRAINT "demandas_fk_0"
    FOREIGN KEY("demandaPaiId")
    REFERENCES "demandas"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "registros_tempo"
    ADD CONSTRAINT "registros_tempo_fk_0"
    FOREIGN KEY("demandaId")
    REFERENCES "demandas"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20260910015252236-v1-demandas-filhas-tempo', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260910015252236-v1-demandas-filhas-tempo', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
