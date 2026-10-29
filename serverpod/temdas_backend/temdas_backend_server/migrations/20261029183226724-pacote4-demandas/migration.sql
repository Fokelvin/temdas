BEGIN;
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';
DO $baseline$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.serverpod_migrations
      WHERE module = 'temdas_backend' AND version = '20261029113025000-sprint-integrity') THEN
    RAISE EXCEPTION 'pacote4_unexpected_baseline';
  END IF;
END;
$baseline$;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "anotacoes_demanda" (
    "id" bigserial PRIMARY KEY,
    "demandaId" bigint NOT NULL,
    "autorId" bigint NOT NULL,
    "conteudo" text NOT NULL,
    "criadoEm" timestamp without time zone NOT NULL,
    "editadoEm" timestamp without time zone,
    "excluidoEm" timestamp without time zone
);

-- Indexes
CREATE INDEX "anotacoes_demanda_criacao_idx" ON "anotacoes_demanda" USING btree ("demandaId", "criadoEm");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "registros_tempo" ADD COLUMN "observacao" text;
ALTER TABLE "registros_tempo" ADD COLUMN "observacaoOrigens" text;
--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "anotacoes_demanda"
    ADD CONSTRAINT "anotacoes_demanda_fk_0"
    FOREIGN KEY("demandaId")
    REFERENCES "demandas"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "anotacoes_demanda"
    ADD CONSTRAINT "anotacoes_demanda_fk_1"
    FOREIGN KEY("autorId")
    REFERENCES "usuarios"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


-- Data migration: preserve the legacy column as a read-only archive.
-- Serverpod applies this revision once; both updates and revision history commit
-- atomically. No notes are fabricated and no original text is trimmed.
LOCK TABLE "demandas" IN SHARE ROW EXCLUSIVE MODE;
UPDATE "demandas"
SET "descricao" = CASE
    WHEN "descricao" IS NULL OR "descricao" !~ '[^[:space:]]'
      THEN "observacoes"
    ELSE "descricao" || E'\n\nObservações anteriores\n' || "observacoes"
  END
WHERE "observacoes" IS NOT NULL AND "observacoes" <> '';

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261029183226724-pacote4-demandas', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261029183226724-pacote4-demandas', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
