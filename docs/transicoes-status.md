# Transições de status

O fluxo existente é View → DemandasViewModel → DemandaRepository → client
gerado → DemandaEndpoint → PostgreSQL. Uma filha é uma Demanda com
`demandaPaiId`; netas e demais níveis usam a mesma relação. O backend busca os
descendentes no banco, sem depender da lista carregada pelo Flutter.

## Fonte de verdade

`DemandaStatusService`, em `temdas_backend_server/lib/src/demandas/`, concentra
validação, percurso da árvore e persistência de status. O endpoint apenas
encaminha as operações. O update genérico usa o mesmo serviço e compartilha
sua transação com a atualização dos demais campos, impedindo desvios das regras.
Não foram criadas camadas de repositório ou infraestrutura no backend.

Os status continuam sendo `aberta`, `emAndamento`, `pausada`, `concluida` e
`cancelada`. Concluída e Cancelada são terminais para estas validações.

## Operações

| Endpoint | Comportamento |
| --- | --- |
| `alterarStatusDemanda(id, status, motivoCancelamento: ...)` | Usa a regra central. Concluir é simples; cancelar inclui a árvore. |
| `atualizarDemanda(request)` | Edita os campos existentes e passa a transição pela mesma regra. |
| `concluirDemandaEmCascata(id)` | Conclui descendentes ativos e depois a raiz. |
| `cancelarDemandaEmCascata(id, motivoCancelamento)` | Cancela descendentes ativos com um motivo comum e depois a raiz. |

A conclusão simples exige que **todos** os descendentes sejam terminais.
Quando há descendentes ativos, lança `TransicaoStatusException` com
`codigo = descendentesAtivos` e `podeConcluirEmCascata = true`. A exceção é
serializável e chega tipada ao client. A aplicação não executa uma cascata
implicitamente ao receber esse erro.

As duas cascatas percorrem todos os níveis, inclusive abaixo de nós terminais.
Descendentes concluídos ou cancelados não são atualizados: preservam status,
motivo e timestamps. A raiz recebe o status solicitado. Transições para estados
ativos e reaberturas mantêm o comportamento anterior, sem propagação aos filhos.
Não foram acrescentadas restrições de criação de filhas ou reabertura.

## Motivo e migration

`motivoCancelamento` é `String?` no modelo e no DTO de edição e `text NULL` na
tabela `demandas`. Uma nova transição para Cancelada exige um motivo explícito
que permaneça não vazio após `trim()`. Ausência ou texto vazio produz
`motivoCancelamentoObrigatorio`. Nos descendentes cancelados pela operação,
persiste o mesmo motivo normalizado. O motivo de descendentes já cancelados
nunca é sobrescrito pela cascata.

Editar uma demanda já cancelada preserva seu motivo quando ele não é enviado.
Dados legados sem motivo continuam editáveis quando não há nova transição;
cancelar descendentes ativos exige o motivo. Uma reabertura preserva o motivo
anterior como dado, mas um novo cancelamento requer um novo motivo explícito.

A migration `20260914133001923-transicoes-status` adiciona apenas essa coluna
opcional. Não cria novos status, não altera dados existentes e não inventa
motivos para registros antigos. Foi aplicada no banco descartável de testes e
no ambiente de desenvolvimento configurado.

## Transações

Cada operação usa `session.db.transaction`. O serviço bloqueia a raiz com
`FOR UPDATE` e carrega/bloqueia filhos por nível antes de validar ou atualizar.
O percurso iterativo admite qualquer profundidade sem recursão na pilha e
protege contra visitas repetidas. Os pais são bloqueados antes da busca de
filhos; a criação existente usa `FOR KEY SHARE` no pai e aguarda esses bloqueios.

Os descendentes são persistidos dos níveis mais profundos aos mais altos e a
raiz por último. Falhas revertem tudo, inclusive a edição de outros campos
quando a chamada vem do update genérico. Os testes provocam falhas por
constraints no PostgreSQL para verificar rollback real, sem simular o banco.
Não houve impedimento arquitetural à atomicidade.

## Integração no app e escopo

O Repository expõe as três novas operações e encaminha o motivo no update.
O ViewModel encaminha o motivo opcional, utiliza a mensagem de recusa recebida
do backend e recarrega a lista após cancelamento para sincronizar descendentes.
As regras permanecem exclusivamente no backend; o fake de apresentação não
as replica.

Nenhum widget, modal, botão ou fluxo visual foi acrescentado nesta etapa.
O formulário atual ainda não coleta motivo: tentar um novo cancelamento por
ele recebe a recusa do backend. Coleta de motivo e confirmação de conclusão
em cascata ficam para a etapa de UX; as operações já estão disponíveis pela API
e pelo Repository.

## Validação e arquivos

`test/integration/demanda_status_test.dart` cobre folhas, terminais, recusa de
conclusão com filhos/netos ativos, quatro níveis, motivos vazios, preservação de
terminais, cancelamento pelos três caminhos, rollback das cascatas e do update,
reabertura e compatibilidade com cancelamentos legados.

No Flutter, `demandas_view_model_test.dart` verifica envio do motivo,
sincronização dos descendentes e propagação de recusa; o fake foi adaptado ao
contrato e `widget_test.dart` considera a recarga após cancelamento. A ferramenta
`app/tool/backend_e2e.dart` verifica o contrato HTTP, recusa tipada e cascatas.
Ela aceita `TEMDAS_BACKEND_URL`, mantendo `http://localhost:8080/` como padrão.

Fontes alteradas/adicionadas nesta etapa:

- `app/lib/data/repositories/demanda_repository.dart`
- `app/lib/view_model/demandas_view_model.dart`
- `app/test/demandas_view_model_test.dart`
- `app/test/support/fake_demanda_repository.dart`
- `app/test/widget_test.dart` (somente expectativa de recarga nesta etapa)
- `app/tool/backend_e2e.dart`
- `temdas_backend_server/lib/src/demandas/demanda_endpoint.dart`
- `temdas_backend_server/lib/src/demandas/demanda_status_service.dart`
- `temdas_backend_server/lib/src/demandas/demanda.spy.yaml`
- `temdas_backend_server/lib/src/demandas/demanda_update_request.spy.yaml`
- `temdas_backend_server/lib/src/demandas/transicao_status_erro_codigo.spy.yaml`
- `temdas_backend_server/lib/src/demandas/transicao_status_exception.spy.yaml`
- `temdas_backend_server/test/integration/demanda_status_test.dart`
- Esta documentação e o link em `docs/arquitetura.md`.

Os caminhos `temdas_backend_server` e `temdas_backend_client` acima/abaixo
ficam sob `serverpod/temdas_backend/`.

Artefatos gerados pelo Serverpod:

- Modelos `Demanda`, `DemandaUpdateRequest`, `TransicaoStatusErroCodigo` e
  `TransicaoStatusException` em `temdas_backend_server/lib/src/generated/demandas/`
  e `temdas_backend_client/lib/src/protocol/demandas/`.
- Protocolos do servidor (`protocol.dart`, `protocol.yaml`) e do client
  (`protocol.dart`), dispatch `endpoints.dart` e client `client.dart`.
- `temdas_backend_server/test/integration/test_tools/serverpod_test_tools.dart`.
- Diretório `migrations/20260914133001923-transicoes-status/` (definitions e
  migration em SQL/JSON) e `migrations/migration_registry.txt`.

Os testes de backend usam `config/test.yaml`, PostgreSQL local na porta 9090
e `SERVERPOD_DATABASE_PASSWORD` definido para o banco de testes. Executar
`dart test --concurrency=1` e `dart analyze` no servidor; executar
`flutter test` e `flutter analyze` em `app/`. Não executar testes de integração
com a configuração de desenvolvimento ou com dados reais.

Validação desta implementação: 22 testes de backend e 52 testes Flutter
aprovados; `dart analyze` e `flutter analyze` sem problemas; E2E com o client
gerado por HTTP aprovado no banco descartável. Os serviços temporários foram
encerrados após os testes.
