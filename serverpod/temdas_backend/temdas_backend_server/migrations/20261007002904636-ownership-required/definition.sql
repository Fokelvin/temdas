BEGIN;

--
-- Class Demanda as table demandas
--
CREATE TABLE "demandas" (
    "id" bigserial PRIMARY KEY,
    "usuarioId" bigint NOT NULL,
    "demandaPaiId" bigint,
    "ordem" bigint,
    "titulo" text NOT NULL,
    "descricao" text,
    "status" text NOT NULL,
    "motivoCancelamento" text,
    "prioridade" text NOT NULL,
    "tempoEstimadoMinutos" bigint NOT NULL,
    "tempoExecutadoMinutos" bigint NOT NULL,
    "observacoes" text,
    "criadoEm" timestamp without time zone NOT NULL,
    "atualizadoEm" timestamp without time zone NOT NULL,
    "concluidoEm" timestamp without time zone
);

-- Indexes
CREATE INDEX "demandas_demanda_pai_id_idx" ON "demandas" USING btree ("demandaPaiId");

--
-- Class EmailWhitelist as table emails_whitelist
--
CREATE TABLE "emails_whitelist" (
    "id" bigserial PRIMARY KEY,
    "emailNormalizado" text NOT NULL,
    "utilizadoEm" timestamp without time zone,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "emails_whitelist_email_normalizado_idx" ON "emails_whitelist" USING btree ("emailNormalizado");

--
-- Class RegistroTempo as table registros_tempo
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
-- Class Sprint as table sprints
--
CREATE TABLE "sprints" (
    "id" bigserial PRIMARY KEY,
    "usuarioId" bigint NOT NULL,
    "nome" text NOT NULL,
    "nomeNormalizado" text,
    "dataInicio" timestamp without time zone NOT NULL,
    "dataFim" timestamp without time zone NOT NULL,
    "tempoPrevistoMinutos" bigint,
    "status" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "sprints_nome_normalizado_idx" ON "sprints" USING btree ("usuarioId", "nomeNormalizado");

--
-- Class SprintDemanda as table sprints_demandas
--
CREATE TABLE "sprints_demandas" (
    "id" bigserial PRIMARY KEY,
    "sprintId" bigint NOT NULL,
    "demandaId" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "sprints_demandas_sprint_demanda_idx" ON "sprints_demandas" USING btree ("sprintId", "demandaId");

--
-- Class Usuario as table usuarios
--
CREATE TABLE "usuarios" (
    "id" bigserial PRIMARY KEY,
    "supabaseUserId" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "usuarios_supabase_user_id_idx" ON "usuarios" USING btree ("supabaseUserId");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Foreign relations for "demandas" table
--
ALTER TABLE ONLY "demandas"
    ADD CONSTRAINT "demandas_fk_0"
    FOREIGN KEY("usuarioId")
    REFERENCES "usuarios"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "demandas"
    ADD CONSTRAINT "demandas_fk_1"
    FOREIGN KEY("demandaPaiId")
    REFERENCES "demandas"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "registros_tempo" table
--
ALTER TABLE ONLY "registros_tempo"
    ADD CONSTRAINT "registros_tempo_fk_0"
    FOREIGN KEY("demandaId")
    REFERENCES "demandas"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "sprints" table
--
ALTER TABLE ONLY "sprints"
    ADD CONSTRAINT "sprints_fk_0"
    FOREIGN KEY("usuarioId")
    REFERENCES "usuarios"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "sprints_demandas" table
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

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


ALTER TABLE "sprints"
    ADD CONSTRAINT "sprints_periodo_valido_check"
    CHECK ("dataInicio" <= "dataFim");
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


CREATE UNIQUE INDEX "sprints_uma_ativa_por_usuario_idx"
    ON "sprints" ("usuarioId")
    WHERE "status" = 'ativa';
CREATE EXTENSION IF NOT EXISTS btree_gist;
ALTER TABLE "sprints"
    ADD CONSTRAINT "sprints_periodos_sem_sobreposicao_por_usuario"
    EXCLUDE USING gist (
        "usuarioId" WITH =,
        daterange("dataInicio"::date, "dataFim"::date, '[]') WITH &&
    ) WHERE (
        "status" IN ('planejada', 'ativa', 'concluida')
    );
-- Only normalized, non-empty e-mails may enter the whitelist.
ALTER TABLE "emails_whitelist"
    ADD CONSTRAINT "emails_whitelist_email_normalizado_check"
    CHECK (
        "emailNormalizado" <> ''
        AND "emailNormalizado" = lower(btrim("emailNormalizado"))
    );

-- Deferred validation permits a complete parent/child tree to be assigned
-- to one owner in a single backfill transaction.
CREATE OR REPLACE FUNCTION "temdas_validar_owner_demanda_filha"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    pai_id bigint;
    owner_id bigint;
    owner_pai bigint;
BEGIN
    SELECT "demandaPaiId", "usuarioId"
      INTO pai_id, owner_id
      FROM "demandas"
     WHERE "id" = NEW."id";

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    IF pai_id IS NOT NULL THEN
        SELECT "usuarioId" INTO owner_pai
          FROM "demandas"
         WHERE "id" = pai_id;

        IF owner_id IS DISTINCT FROM owner_pai THEN
            RAISE EXCEPTION 'Demanda filha e demanda pai devem ter o mesmo usuário.'
                USING ERRCODE = '23514';
        END IF;
    END IF;

    IF EXISTS (
        SELECT 1
          FROM "demandas" AS filha
         WHERE filha."demandaPaiId" = NEW."id"
           AND filha."usuarioId" IS DISTINCT FROM owner_id
    ) THEN
        RAISE EXCEPTION 'Demanda filha e demanda pai devem ter o mesmo usuário.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER "demandas_validar_owner_filha"
AFTER INSERT OR UPDATE ON "demandas"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_owner_demanda_filha"();

-- A link inherits ownership from both sides; neither side may be reassigned
-- to a different user while the link remains.
CREATE OR REPLACE FUNCTION "temdas_validar_owner_vinculo_sprint"()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    owners_diferentes boolean;
BEGIN
    IF TG_TABLE_NAME = 'sprints_demandas' THEN
        SELECT s."usuarioId" IS DISTINCT FROM d."usuarioId"
          INTO owners_diferentes
          FROM "sprints_demandas" AS sd
          JOIN "sprints" AS s ON s."id" = sd."sprintId"
          JOIN "demandas" AS d ON d."id" = sd."demandaId"
         WHERE sd."id" = NEW."id";
    ELSIF TG_TABLE_NAME = 'sprints' THEN
        SELECT EXISTS (
            SELECT 1
              FROM "sprints_demandas" AS sd
              JOIN "demandas" AS d ON d."id" = sd."demandaId"
             WHERE sd."sprintId" = NEW."id"
               AND d."usuarioId" IS DISTINCT FROM
                   (SELECT "usuarioId" FROM "sprints" WHERE "id" = NEW."id")
        ) INTO owners_diferentes;
    ELSE
        SELECT EXISTS (
            SELECT 1
              FROM "sprints_demandas" AS sd
              JOIN "sprints" AS s ON s."id" = sd."sprintId"
             WHERE sd."demandaId" = NEW."id"
               AND s."usuarioId" IS DISTINCT FROM
                   (SELECT "usuarioId" FROM "demandas" WHERE "id" = NEW."id")
        ) INTO owners_diferentes;
    END IF;

    IF owners_diferentes THEN
        RAISE EXCEPTION 'Sprint e demanda vinculadas devem ter o mesmo usuário.'
            USING ERRCODE = '23514';
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER "sprints_demandas_validar_owner"
AFTER INSERT OR UPDATE ON "sprints_demandas"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_owner_vinculo_sprint"();

CREATE CONSTRAINT TRIGGER "sprints_validar_owner_vinculos"
AFTER UPDATE ON "sprints"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_owner_vinculo_sprint"();

CREATE CONSTRAINT TRIGGER "demandas_validar_owner_vinculos"
AFTER UPDATE ON "demandas"
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW
EXECUTE FUNCTION "temdas_validar_owner_vinculo_sprint"();

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261007002904636-ownership-required', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261007002904636-ownership-required', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
