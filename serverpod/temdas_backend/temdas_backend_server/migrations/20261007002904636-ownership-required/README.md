# Ownership obrigatório

Esta migration sucede `20260928204126156-ownership-foundation` e não faz
backfill, atualização ou exclusão de dados de negócio.

Dentro de uma transação, bloqueia `demandas`, `sprints` e `sprints_demandas`,
valida os owners e somente então aplica `NOT NULL`. Havendo owners ausentes,
vínculos divergentes ou hierarquias divergentes, aborta com SQLSTATE `23514`
e informa as quatro contagens. Uma falha posterior também reverte todo o DDL.

Remove os dois índices e a exclusion constraint exclusivos de owners NULL.
Mantém o índice único `(usuarioId, nomeNormalizado)` e recria, com os mesmos
nomes, o índice de Sprint ativa e a exclusion constraint de períodos por
usuário. Apenas o predicado redundante `usuarioId IS NOT NULL` foi retirado:
os períodos continuam inclusivos e protegidos nos estados `planejada`,
`ativa` e `concluida`.

As FKs, checks e triggers de ownership e ciclo de vida permanecem. A nova
`definition.sql` também inclui esses objetos para criação de um banco novo.
Os snapshots JSON do Serverpod não representam os objetos customizados;
`sprint_custom_schema.dart` registra em memória os dois índices customizados
restantes, inclusive o índice GiST que representa a exclusion constraint.

Validação realizada no PostgreSQL local de teste: quatro cenários isolados
de abortagem defensiva, aplicação pelo Serverpod 3.4.11, owners `NOT NULL`,
rejeição de inserts NULL, FKs e objetos de Sprint preservados. Passaram os
testes de ownership/AAL2 e os 65 testes de integração. A inicialização real
em development, com override para o banco local de teste, permaneceu ativa
e respondeu HTTP 200 sem avisos de schema. O harness gerado de integração
não chama o registro customizado e ainda exibe avisos falsos para os dois
índices customizados presentes no PostgreSQL.

O Supabase DEV não recebeu esta migration. Para a aplicação futura, prever
uma janela para os locks exclusivos, a auditoria e a reconstrução do GiST;
transações longas podem atrasar a operação. Atualizar o backend e os
protocolos regenerados junto da mudança de schema. Não usar repair migration.
