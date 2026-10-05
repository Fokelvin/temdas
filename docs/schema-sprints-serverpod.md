# Schema customizado de Sprints no Serverpod 3.4.11

A migration `20260928204126156-ownership-foundation` criou os índices parciais de
`sprints` e as duas exclusion constraints. Seu `migration.sql` atualiza bancos
existentes; seu `definition.sql` cria os mesmos objetos em instalações limpas.
Essa migration já foi aplicada no Supabase de desenvolvimento e não deve ser
reescrita.

O Serverpod 3.4.11 não representa índices parciais, índices sobre expressões ou
exclusion constraints no `sprint.spy.yaml`. O gerador, portanto, não inclui
esses cinco objetos em `Protocol.targetTableDefinitions`. Na inicialização, o
analisador consulta `pg_index` e compara cada índice do banco com o target. O
PostgreSQL também registra cada exclusion constraint como um índice GiST em
`pg_index`; o Serverpod as compara como **índices**, não como foreign keys nem
como um tipo próprio de constraint. Assim, os cinco objetos existentes eram
reportados como `Missing Index` no **target**.

`lib/src/sprints/sprint_custom_schema.dart` registra no target em memória as
cinco definições retornadas pelo analisador do PostgreSQL, incluindo tipo,
unicidade, elementos e predicados normalizados por `pg_get_expr`. A função é
chamada antes de construir o `Serverpod`. Não executa SQL e não altera dados.
O índice composto `sprints_nome_normalizado_idx` continua declarado no
`sprint.spy.yaml` e gerado normalmente.

As cinco definições customizadas **não** devem ser acrescentadas manualmente a
`definition.json` nem a `definition_project.json`: a CLI usa esses arquivos
para calcular migrations futuras. Como a CLI 3.4.11 não consegue gerar o SQL
correto desses objetos, incluí-los ali faria uma migration futura tentar
substituí-los por índices comuns ou descartá-los. Também não se deve marcar
Sprint com `managedMigration: false`: isso transferiria a gestão de toda a
tabela, inclusive colunas e relações, para SQL manual.

Ao criar uma migration futura, conferir se o novo `definition.sql` mantém os
índices parciais e as exclusion constraints customizadas necessários para uma
instalação limpa. A CLI regenera esse arquivo a partir dos modelos e não
transporta automaticamente SQL customizado de migrations anteriores. Se a
estrutura de Sprint mudar, atualizar o SQL da nova migration e as definições
em `sprint_custom_schema.dart` de acordo com a introspecção do PostgreSQL.

Consultas de verificação no PostgreSQL:

```sql
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'sprints'
ORDER BY indexname;

SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'public.sprints'::regclass
ORDER BY conname;

SELECT module, version FROM serverpod_migrations ORDER BY module;
SELECT count(*), coalesce(sum(id), 0) FROM sprints;
```

Validação do backend: `serverpod generate`, `dart analyze` no pacote server,
`dart analyze` no pacote client e `dart run bin/main.dart` no pacote server sem
`--apply-migrations`. A inicialização deve continuar em `development` sem
`Missing Index`.
