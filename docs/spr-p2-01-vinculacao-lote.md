# SPR-P2-01 — vinculação em lote e reconciliação de timeout

Implementado em 03/11/2026 na branch
`feat/spr-p2-01-vinculacao-lote-timeout`, a partir de `main` em `1234777`.
**Não integrado, não publicado.** Nenhuma conexão a PROD, migration de upgrade,
alteração de infraestrutura ou dado de negócio real foi executada nesta etapa.

## Problema e implementação

As chamadas reais anteriores concluíram com HTTP 200 em 29,893 s/56 consultas
e 24,656 s/46 consultas, ultrapassando o timeout de 20 s do cliente. Esses
valores históricos não são medições da implementação nova em PROD.

`SprintDemandaService.vincularArvores` mantém a transação da RPC e agora faz:

1. Um advisory lock de ciclo de vida e uma leitura/bloqueio da Sprint de destino.
2. Uma CTE recursiva parametrizada com `UNION` de IDs para carregar o conjunto
   deduplicado de raízes e descendentes. A consulta externa bloqueia as linhas
   reais de `demandas`, ordenadas por ID. Nenhum texto de Demanda é carregado.
3. Uma leitura/bloqueio em lote dos vínculos das Demandas e de seus pais.
   Todos os IDs solicitados precisam existir no escopo do usuário; IDs ausentes
   ou estrangeiros abortam o lote. Uma filha exige mãe no conjunto ou já vinculada
   ao destino. A ordem de seleção filha/mãe não modifica o resultado.
4. Uma leitura/bloqueio das demais Sprints abertas relevantes, se houver.
   O destino já carregado é reutilizado para comparar períodos inclusivos.
   Histórico finalizado/cancelado é preservado e não bloqueia vínculos novos.
5. Um `INSERT ... SELECT ... ON CONFLICT ("sprintId", "demandaId") DO NOTHING
   RETURNING`, somente para pares ausentes, ordenado por ID. Todos os triggers,
   FKs e índices existentes continuam ativos. Conflitos de período/proprietário
   não são ignorados pelo `ON CONFLICT` do par único.
6. Uma consulta posterior retorna os vínculos afetados, novos e preexistentes,
   ordenados por `demandaId`, sem duplicações de árvores sobrepostas. O DTO e a
   assinatura da RPC permanecem iguais. A deduplicação/ordem estável é intencional.

O total máximo do cenário é oito consultas incluindo a consulta de usuário da
autenticação. A RPC autentica uma vez; o serviço adquire o advisory lock uma vez.
O mesmo lock continua sendo adquirido pelos triggers dentro do PostgreSQL por
linha, sem viagens adicionais ao aplicativo. Não foi alterado o protocolo de
locks dos demais endpoints. O fluxo individual `vincularArvore` permanece intacto.
Não há mudança de schema, gerador ou versão do Serverpod.

## Timeout e resultado desconhecido

O código instalado do Serverpod 3.4.11 configura `connectionTimeout` no `Client`;
a chamada gerada de RPC não oferece configuração por operação. O único cliente
compartilhado passou a usar 60 s. Sua integração existente de autenticação/MFA
continua usando a mesma instância; não há cliente paralelo ou edição de gerados.

Em `TimeoutException`, tanto a vinculação individual quanto a de lote fazem uma
consulta de leitura de vínculos. Se todas as Demandas solicitadas estiverem no
destino, a interface confirma o estado persistido. Não ocorre repetição da mutação.
Se a leitura falhar ou ainda estiver incompleta, aparece resultado **inconclusivo**,
sem afirmar rollback ou sugerir reenvio automático. A tentativa fica pendente no
view model; um novo toque com a mesma seleção executa somente a consulta. Outra
seleção não inicia nova vinculação enquanto a anterior estiver inconclusiva.
A atualização manual dos vínculos limpa a pendência apenas quando confirma
todos os IDs; leitura incompleta mantém o aviso.

## Validação exclusivamente descartável

O runner existente inicializa um container novo PostgreSQL 17.11, porta aleatória
somente em 127.0.0.1, sem volumes existentes ou credenciais de origem. Aplica apenas
`definition.sql` do schema aprovado SPR-P2-01 ao banco vazio, com triggers reais;
nunca executa `migration.sql`. Confere nome/label/ID antes de remover somente o
container criado. A migração e as dependências versionadas não foram alteradas.

Cobertura validada:

- Seis mães/quatro filhas, histórico concluído equivalente à Sprint 72 e cancelado;
  idempotência, duplicação de IDs e seleção de árvores sobrepostas.
- Hierarquia de 21 níveis; filha antes da mãe; filha isolada sem mãe rejeitada;
  mãe preexistente aceita; constraints diferidas e imediatas.
- IDs inexistentes, recursos de outro usuário, Sprint fechada, sobreposição
  inclusiva e manutenção dos vínculos históricos.
- Transações independentes concorrentes: mesmo lote, criação de filha e
  cancelamento; reabertura posterior mantendo a integridade.
- Rollback antes da inserção e rollback **no COMMIT**, provocado pelo trigger
  real diferido de proprietário; nenhum vínculo do lote persiste após a falha.
- Timeout após gravação confirmada; leitura incompleta/falha; novo toque sem
  reenviar; seleção diferente enquanto pendente; atualização manual e vínculo
  individual; erros de domínio preservam suas mensagens específicas.

Resultados finais: **43 testes backend únicos**, incluindo benchmark, e
**21 testes frontend únicos** aprovados. Análise estática direcionada sem
ocorrências. O teste de rollback no COMMIT inicialmente esperava o wrapper
Serverpod; o driver expõe `ServerException/23514` diretamente nessa fase.
A expectativa foi corrigida e somente esse teste foi repetido com sucesso.
Nenhuma alteração de aplicação foi necessária para essa correção de expectativa.
Não foi executado build release; os testes compilaram os caminhos alterados.

## Medições comparativas

PostgreSQL 17.11, Serverpod 3.4.11 e dependência travada `postgres` 3.5.16.
Dados sintéticos: seis raízes, quatro filhas de uma raiz, dez vínculos históricos
concluídos e destinos de períodos diferentes. Comparação dentro do mesmo banco
descartável. O legado usa exatamente o algoritmo anterior do lote: lock/leitura
inicial e chamadas sequenciais ao método individual mantido sem alterações.

Um proxy **somente loopback** acrescenta **500 ms a cada `ReadyForQuery`**.
Não é uma medição nem uma reprodução exata da rede Virginia–São Paulo. O driver
também fecha portais dentro da transação, com trocas de protocolo adicionais;
por isso 500 ms por resposta não significa 500 ms por consulta SQL. BEGIN/COMMIT
e essas trocas adicionais entram na duração total, mas não no contador Serverpod.

| Caso | Consultas | Duração total | Soma dos tempos de query |
| --- | ---: | ---: | ---: |
| Legado: inserir | 56 | 56,801 s | 55,777 s |
| Legado: repetir | 46 | 46,741 s | 45,722 s |
| Lote: inserir | 8 | 8,546 s | 7,538 s |
| Lote: repetir | 7 | 7,539 s | 6,532 s |

Redução de consultas: 85,7% e 84,8%. Ganho observado nesse cenário: 6,65× e 6,20×.
Os dois casos novos passaram na asserção de duração inferior a 10 s. A medição
inclui uma consulta real de usuário equivalente à RPC, mas não login/MFA, rede
do navegador ou serialização HTTP. É uma amostra por estado, não um p95/SLA.
Os tempos de query incluem o atraso do proxy; não são tempos puros do motor SQL.
Valores brutos e hashes estão em `evidencias-spr-p2-01-vinculacao-lote.json`.

Reprodução (nenhum comando acessa PROD):

```sh
python3 scripts/testing/run_sprint_tests.py test/integration/sprint_bulk_test.dart test/integration/sprint_endpoint_test.dart test/integration/ownership_aal2_test.dart
TEMDAS_SPR_BENCHMARK=1 TEMDAS_SPR_BENCHMARK_REPORT=/tmp/temdas-spr-bulk-benchmark.json python3 scripts/testing/run_sprint_tests.py test/integration/sprint_bulk_test.dart --name 'benchmark real'
# No diretório app:
rtk test flutter test --no-pub test/sprint_vinculacao_timeout_test.dart test/sprint_view_model_test.dart
```

## Limites e publicação

O advisory lock continua global e pode provocar fila sob concorrência; o lote
reduz o tempo de retenção, mas não remove esse limite. Árvores muito grandes,
contenção e a rede real ainda precisam de observação após uma futura publicação
autorizada. Não há medição nova em PROD nem garantia de duração nesse ambiente.
O timeout compartilhado de 60 s também afeta outras RPCs. A reconciliação é uma
confirmação do estado observado, não um recibo da requisição; a pendência é mantida
em memória e não sobrevive à recriação do view model/recarregamento da página.

Publicação, integração à main, push e qualquer operação em PROD aguardam
autorização separada. Não reaplicar a migration SPR-P2-01 para publicar esta mudança.
