BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '60s';

--
-- ACTION CREATE TABLE
--
CREATE TABLE "todos" (
    "id" bigserial PRIMARY KEY,
    "usuarioId" bigint NOT NULL,
    "demandaId" bigint,
    "conteudo" text NOT NULL,
    "data" text,
    "concluido" boolean NOT NULL DEFAULT false,
    "criadoEm" timestamp without time zone NOT NULL,
    "posicao" bigint,
    "largura" double precision NOT NULL DEFAULT 232.0,
    "altura" double precision NOT NULL DEFAULT 232.0
);

-- Indexes
CREATE INDEX "todos_usuario_posicao_idx" ON "todos" USING btree ("usuarioId", "posicao");
CREATE INDEX "todos_demanda_idx" ON "todos" USING btree ("demandaId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "todos"
    ADD CONSTRAINT "todos_fk_0"
    FOREIGN KEY("usuarioId")
    REFERENCES "usuarios"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "todos"
    ADD CONSTRAINT "todos_fk_1"
    FOREIGN KEY("demandaId")
    REFERENCES "demandas"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


-- To-dos are accessed through Serverpod with the authenticated owner.
ALTER TABLE public.todos ENABLE ROW LEVEL SECURITY;

--
-- MIGRATION VERSION FOR temdas_backend
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('temdas_backend', '20261111230242894-todos', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261111230242894-todos', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();


COMMIT;
