# Schema customizado de Sprints no Serverpod 3.4.11

## Regras atuais

Além da PK, FK de proprietário e índice composto de nome, Sprint exige:

| Objeto | Semântica |
| --- | --- |
| `sprints_uma_ativa_por_usuario_idx` | UNIQUE btree em `usuarioId`, somente quando `status = 'ativa'` |
| `sprints_periodos_sem_sobreposicao_por_usuario` | EXCLUDE GiST: mesmo proprietário (`=`) e interseção (`&&`) de `daterange(dataInicio::date, dataFim::date, '[]')`, para `planejada`, `ativa` e `concluida` |

O intervalo inclui os dois dias extremos: terminar e começar no mesmo dia
constitui sobreposição. Sprints canceladas não participam da exclusão. Usuários
diferentes permanecem independentes. A regra de uma ativa também se aplica a
períodos disjuntos.

## Histórico e causa da divergência

`20260928204126156-ownership-foundation` introduziu cinco objetos customizados,
incluindo o bucket temporário para proprietário nulo.
`20261007002904636-ownership-required` tornou o proprietário obrigatório, removeu
os três objetos desse bucket e manteve os dois objetos atuais. Não reescrever
essas migrations.

Os dois objetos ainda constam da definição completa de
`20261008000720453-usuario-admin`, mas foram omitidos do `definition.sql` seguinte,
`20261009000123093-convite-cooldown`. O SQL incremental de cooldown não os remove.
Serverpod 3.4.11 inicializa banco vazio pela definição completa mais recente;
somente bancos já versionados recebem os SQLs incrementais posteriores. Assim,
uma instalação limpa podia registrar a versão cooldown sem criar essas proteções.
Esse caminho explica o estado observado; não há nesta auditoria evidência do
comando histórico exato de bootstrap para excluir remoção posterior.

Em 29/10/2026 a auditoria somente leitura confirmou ausência dos dois objetos e
de `btree_gist` em PROD, também ausentes no backup. Havia uma Sprint e nenhuma
violação encontrada. O histórico contém a última versão por módulo, não uma
trilha de cada arquivo SQL executado.

## Correção versionada e aplicada em PROD

Aplicada em 29/10/2026, após autorização específica e preflight/ensaio aprovados.
Histórico, extensão, objetos, contagens e hashes foram conferidos no PROD;
detalhes e pendências no [registro de aplicação PROD-02](migrations-prod.md#aplicação-autorizada-em-prod--29102026).
Esta confirmação não autoriza aplicar a migration em DEV ou em outro ambiente.

`20261029113025000-sprint-integrity` é uma migration SQL aditiva específica para
o baseline cooldown incompleto. Instala `btree_gist` 1.7 no schema `extensions`,
cria os dois objetos e atualiza somente a versão do módulo TEMDAS. PKs, FKs,
checks, triggers, demais índices e dados não são substituídos. Uma transação
protege o conjunto; conflitos ou precondições inesperadas causam rollback.

A operator class `extensions.gist_int8_ops` é qualificada explicitamente.
Não se depende de `extensions` no search_path global, não se move extensão já
existente e não se concedem privilégios no SQL. Extensão preexistente em schema
ou versão incompatível bloqueia a execução. Objetos já existentes também
bloqueiam: não se usa IF NOT EXISTS para aceitar silenciosamente uma definição
incorreta de índice/constraint. Ambientes já completos precisam de avaliação
própria; esta tarefa não aplica alterações em DEV.

O `definition.sql` da nova versão contém o mesmo bloco customizado para criação
limpa. Os JSONs conservam o schema gerenciado e atualizam a versão do módulo;
`migration.json` tem ações geradas vazias, pois os objetos são SQL customizado.
Não foi usada repair migration nem modificado qualquer artefato histórico.

## Integração com o backend e futuras migrations

Serverpod 3.4.11 não representa esses índices parciais/de expressão e exclusion
constraints no modelo `sprint.spy.yaml`. PostgreSQL registra a exclusion constraint
também como índice GiST. `sprint_custom_schema.dart` acrescenta as duas definições
ao target em memória antes de construir o Serverpod; não executa DDL.

Não inserir os objetos customizados nos JSONs consumidos pelo gerador: ele pode
gerar substituições incorretas. Não marcar toda a tabela como
`managedMigration: false`. O índice `sprints_nome_normalizado_idx` permanece
gerenciado normalmente.

Ao gerar cada nova migration, preservar o bloco customizado no **novo**
`definition.sql` e testar tanto instalação limpa quanto upgrade. O gerador não
transporta automaticamente esse SQL. Nunca corrigir a recorrência reescrevendo
migrations já aplicadas. Os testes comparam o JSON completo com
`Protocol.targetTableDefinitions`, o registro customizado do runtime e os
predicados/elementos efetivamente criados em PostgreSQL 17.11.

Consultas de leitura para conferência:

```sql
SELECT indexname, indexdef FROM pg_indexes
WHERE schemaname = 'public' AND tablename = 'sprints' ORDER BY indexname;
SELECT conname, contype, convalidated, pg_get_constraintdef(oid)
FROM pg_constraint WHERE conrelid = 'public.sprints'::regclass ORDER BY conname;
SELECT module, version FROM public.serverpod_migrations ORDER BY module;
SELECT e.extname, e.extversion, n.nspname
FROM pg_extension e JOIN pg_namespace n ON n.oid = e.extnamespace
WHERE e.extname = 'btree_gist';
```

Pré-requisitos, locks, recuperação e aprovação separada estão no
[runbook PROD-02](migrations-prod.md). A existência desta migration no Git não
autoriza nem dispara sua execução em produção.
