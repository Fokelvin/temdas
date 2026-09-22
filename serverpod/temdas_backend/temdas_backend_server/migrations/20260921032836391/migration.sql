BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "demandas" DROP COLUMN "sprint";
--
-- ACTION CREATE TABLE
--
CREATE TABLE "sprints" (
    "id" bigserial PRIMARY KEY,
    "nome" text NOT NULL,
    "nomeNormalizado" text,
    "dataInicio" timestamp without time zone NOT NULL,
    "dataFim" timestamp without time zone NOT NULL,
    "tempoPrevistoMinutos" bigint,
    "status" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "sprints_nome_normalizado_idx" ON "sprints" USING btree ("nomeNormalizado");
CREATE UNIQUE INDEX "sprints_uma_ativa_idx" ON "sprints" USING btree ((1))
    WHERE "status" = 'ativa';

-- PostgreSQL constraints for the Sprint lifecycle. Serverpod 3.4.11 does not
-- model partial unique indexes or exclusion constraints in .spy.yaml files.
ALTER TABLE "sprints"
    ADD CONSTRAINT "sprints_periodo_valido_check"
    CHECK ("dataInicio" <= "dataFim");
ALTER TABLE "sprints"
    ADD CONSTRAINT "sprints_periodos_sem_sobreposicao"
    EXCLUDE USING gist (
        daterange("dataInicio"::date, "dataFim"::date, '[]') WITH &&
    ) WHERE ("status" IN ('planejada', 'ativa', 'concluida'));

--
-- ACTION CREATE TABLE
--
CREATE TABLE "sprints_demandas" (
    "id" bigserial PRIMARY KEY,
    "sprintId" bigint NOT NULL,
    "demandaId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "sprints_demandas_sprint_demanda_idx" ON "sprints_demandas" USING btree ("sprintId", "demandaId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "sprints_demandas"
    ADD CONSTRAINT "sprints_demandas_fk_0"
    FOREIGN KEY("sprintId")
    REFERENCES "sprints"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "sprints_demandas"
    ADD CONSTRAINT "sprints_demandas_fk_1"
    FOREIGN KEY("demandaId")
    REFERENCES "demandas"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

-- PostgreSQL triggers preserve the cross-table invariant that one demand can
-- belong to at most one planned or active sprint. The transaction advisory
-- lock is the same one used by SprintEndpoint and inheritance on child create.
CREATE OR REPLACE FUNCTION "temdas_validar_vinculo_sprint_aberta"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    status_destino text;
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'));

    SELECT "status"
    INTO status_destino
    FROM "sprints"
    WHERE "id" = NEW."sprintId"
    FOR KEY SHARE;

    IF status_destino NOT IN ('planejada', 'ativa') THEN
        RAISE EXCEPTION 'A sprint não aceita novos vínculos.'
            USING ERRCODE = '23514';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM "sprints_demandas" AS vinculo
        INNER JOIN "sprints" AS sprint ON sprint."id" = vinculo."sprintId"
        WHERE vinculo."demandaId" = NEW."demandaId"
          AND vinculo."sprintId" <> NEW."sprintId"
          AND sprint."status" IN ('planejada', 'ativa')
    ) THEN
        RAISE EXCEPTION 'A demanda já pertence a outra sprint aberta.'
            USING ERRCODE = '23505';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER "sprints_demandas_validar_vinculo_aberto"
BEFORE INSERT OR UPDATE OF "sprintId", "demandaId" ON "sprints_demandas"
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_vinculo_sprint_aberta"();

CREATE OR REPLACE FUNCTION "temdas_validar_reabertura_sprint"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW."status" NOT IN ('planejada', 'ativa') THEN
        RETURN NEW;
    END IF;

    PERFORM pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'));

    IF EXISTS (
        SELECT 1
        FROM "sprints_demandas" AS proprio
        INNER JOIN "sprints_demandas" AS outro
            ON outro."demandaId" = proprio."demandaId"
           AND outro."sprintId" <> NEW."id"
        INNER JOIN "sprints" AS sprint ON sprint."id" = outro."sprintId"
        WHERE proprio."sprintId" = NEW."id"
          AND sprint."status" IN ('planejada', 'ativa')
    ) THEN
        RAISE EXCEPTION 'A reabertura criaria demandas em mais de uma sprint aberta.'
            USING ERRCODE = '23505';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER "sprints_validar_reabertura"
BEFORE UPDATE OF "status" ON "sprints"
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_reabertura_sprint"();

-- A conclusão preserva os vínculos como histórico. A exclusão de qualquer
-- demanda desse histórico precisa falhar também fora dos endpoints.
CREATE OR REPLACE FUNCTION "temdas_proteger_historico_sprint_concluida"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'));

    IF EXISTS (
        SELECT 1
        FROM "sprints_demandas" AS vinculo
        INNER JOIN "sprints" AS sprint ON sprint."id" = vinculo."sprintId"
        WHERE vinculo."demandaId" = OLD."id"
          AND sprint."status" = 'concluida'
    ) THEN
        RAISE EXCEPTION 'A demanda possui histórico em sprint concluída e não pode ser excluída.'
            USING ERRCODE = '23503';
    END IF;

    RETURN OLD;
END;
$$;

CREATE TRIGGER "demandas_proteger_historico_sprint_concluida"
BEFORE DELETE ON "demandas"
FOR EACH ROW
EXECUTE FUNCTION "temdas_proteger_historico_sprint_concluida"();


--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20260921032836391', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260921032836391', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
