# Pacote 4 — Painel de Demandas

Implementação na branch `feat/pacote-4-painel-demandas`, preservando o commit
`c77bed4`. Nenhuma publicação, alteração de secrets, infraestrutura ou aplicação
em PROD faz parte desta entrega.

## Comportamento

- Painel à direita com 50% da largura a partir de 840 px; abaixo disso, tela
  cheia. Cabeçalho e abas fixos, listas com rolagem independente. Corpo do card
  abre detalhes; somente o ícone expande/recolhe. URL e nova aba preservadas.
  Ao fechar, o quadro é reconsultado sem desmontar os cards/estado de expansão.
- Visão geral reutiliza os controles do card, ViewModel e diálogos existentes
  para edição, status/cascata, reabertura, exclusão, criação de filha e Log Time.
  Sprint usa exclusivamente `SprintDemanda`, consultado pelo fluxo existente.
- Anotações ordenadas por criação e ID descendentes; conteúdo integral,
  última edição e exclusão lógica. O autor vem da sessão AAL2. A consulta exige
  ownership da Demanda; editar/excluir também exige autoria. Status terminal
  não impede anotações. Mãe e filhas têm consultas independentes.
- Horas mostra data, início/fim, duração, total e observação. Apenas o texto
  pode ser editado nessa aba; o endpoint atualiza colunas específicas, sem
  normalizar intervalos nem recalcular tempos. Compartilha o lock da agenda
  com a normalização para evitar perda de texto em uniões concorrentes. Edição temporal/exclusão ficam
  exclusivamente no Log Time. Criação e edição existentes recebem observação.

Compartilhamento, organizações, equipes e permissões colaborativas continuam
fora do escopo e reservados ao roadmap futuro.

## Dados e contrato

Migration: `20261029183226724-pacote4-demandas`.

- Cria `anotacoes_demanda`, com FKs para Demanda e autor, datas de criação,
  edição e exclusão lógica e índice por Demanda/criação.
- Adiciona `registros_tempo.observacao` e `observacaoOrigens`, ambas opcionais.
  A segunda contém proveniência JSON privada (`scope=serverOnly`); não é
  controlável pelos DTOs nem exposta na serialização de resposta ao cliente.
- A normalização preserva as regras temporais existentes. Concatena textos
  integrais com os intervalos originais em UTC, ordenados por início, fim e
  texto; deduplica a mesma origem (intervalo/texto). Metadados preservam as
  origens em uniões consecutivas, evitando envolver novamente texto já unido.
  Editar explicitamente uma observação substitui seu texto/proveniência;
  arrastar ou editar horários sem informar texto preserva a observação.
  Falhas de conflito ou metadados inválidos abortam antes das gravações.
- Migra `Demanda.observacoes` integralmente para a descrição vazia ou acrescenta
  `\n\nObservações anteriores\n` e o texto antigo quando ambas existem. Não cria
  anotações artificiais e não altera status, datas ou tempos da Demanda.
- A coluna antiga permanece como arquivo legado somente leitura, sem consumo
  pelo frontend. Remoção física fica para outra migration após validação em
  ambiente real. O endpoint não permite novas escritas; atualizações de clientes
  antigos podem reenviar o mesmo valor arquivado, sem regravá-lo ou duplicá-lo.
- O upgrade exige a revisão anterior exata, usa transação, `lock_timeout=5s` e
  `statement_timeout=60s`; reaplicação é rejeitada antes de duplicar descrições.
  SQL de transformação de dados é customizado; o JSON gerado descreve o DDL.
- A instalação limpa preserva checks/triggers customizados históricos e os
  índices/exclusão de Sprints. O upgrade não modifica esses objetos existentes.
  Não foram alteradas migrations anteriores.

## Validação local

Resultados: análise Flutter completa e análise Dart do workspace Serverpod
sem problemas; suíte Flutter completa com 476 testes, 144 testes
Dart do backend e quatro ensaios SQL aprovados. Build Web release com definições
públicas existentes, sem publicação. Sem mudanças de dependências ou configuração.
O build mantém o aviso anterior, não bloqueante, de fonte CupertinoIcons; a
aplicação compila e os ícones Material utilizados estão presentes. Os ensaios SQL
usam PostgreSQL 17.11 descartável, sem rede/volumes e somente dados sintéticos:

```bash
TEMDAS_MIGRATION_DOCKER_TESTS=1 python3 -m unittest discover \
  -s scripts/migrations -p test_pacote4.py -v
```

Cobertura SQL: instalação limpa, upgrade com campos vazios/preenchidos,
acentos/quebras/espaços, preservação dos demais dados, rollback conjunto de
schema/textos/revisão e bloqueio de reaplicação.

A suíte Dart do backend foi executada com host, porta aleatória em loopback,
nome e senha de banco descartável definidos via `SERVERPOD_DATABASE_*` apenas
no processo dos testes. Nenhum arquivo de configuração/credencial foi editado.
O harness gerado de alguns testes não registra os índices customizados como o
bootstrap de produção e emite avisos de comparação de schema; os testes reais
de constraints/triggers e ownership passam. Log local completo:
`/tmp/temdas-p4-backend-test.log`.

Os testes Flutter cobrem desktop/celular, claro/escuro, abas/cabeçalho, separação
de clique/expansão, CRUD/erros/autoria de anotações, respostas atrasadas e edição
isolada da observação. As regressões antigas mantêm seus asserts e usam o ícone
para expansão. A suíte completa também cobre autenticação, Sprints, Demandas,
agenda, drag-and-drop e as melhorias anteriores.

## Aplicação futura segura — exige autorização específica

1. Homologar visualmente painel, URL/nova aba, teclado/toque, ações de status e
   cascata, anotações e observações em ambiente de teste com frontend/backend
   desta branch. Confirmar o baseline `20261029113025000-sprint-integrity`.
2. Antes de qualquer aplicação real, seguir o procedimento de backup já
   existente e guardar uma cópia verificável das descrições/observações
   anteriores. Ensaiar o upgrade com dados representativos isolados para medir
   volume e duração; os testes desta entrega usam somente dados sintéticos.
3. Revisar a migration e os objetos customizados com o responsável. Aplicar
   somente após aprovação, em janela adequada; lock/statement timeout abortam
   integralmente se a janela for insuficiente. Não usar `--force` para contornar
   falhas. Não reaplicar o SQL manualmente.
4. Verificar a revisão, contagens/FKs, textos migrados e ausência de anotações
   artificiais antes de liberar escritas. Conferir que todo texto legado não
   vazio está contido na descrição e que os objetos de Sprint não mudaram.
5. Disponibilizar backend compatível antes do frontend; verificar a entrega da
   versão correta ao navegador. A pendência anterior de cache HTTP do domínio
   continua separada deste pacote e não foi alterada aqui.
6. Se houver falha, parar e pedir parecer. Não executar rollback automático.
   Reverter o aplicativo/backend pode manter as colunas aditivas; não excluir
   anotações/observações novas. Desfazer uma transformação já confirmada de
   descrição exige a cópia anterior, nunca dividir texto por subtítulos.

## Pendências

Homologação visual em navegador/dispositivo real, ensaio com volume
representativo e aprovação específica para migration/merge/publicação. Não
houve uso de credenciais pessoais, mudanças de permissões ou acesso a dados
PROD. Nenhuma nova dependência foi adicionada.

## Arquivos alterados

Lista exata desta entrega, incluindo modelos/clientes gerados:

- `app/lib/data/repositories/anotacao_demanda_repository.dart`
- `app/lib/data/repositories/demanda_repository.dart`
- `app/lib/data/repositories/registro_tempo_repository.dart`
- `app/lib/view/demanda_detalhe_page.dart`
- `app/lib/view/demandas_page.dart`
- `app/lib/view/log_time_page.dart`
- `app/lib/view/widgets/demanda_card.dart`
- `app/lib/view/widgets/demanda_painel_acoes.dart`
- `app/lib/view/widgets/demanda_texto_dialog.dart`
- `app/lib/view/widgets/log_time_dialog.dart`
- `app/lib/view_model/agenda_view_model.dart`
- `app/lib/view_model/demanda_detalhe_view_model.dart`
- `app/lib/view_model/demandas_view_model.dart`
- `app/lib/view_model/log_time_form_data.dart`
- `app/test/demanda_card_test.dart`
- `app/test/demanda_detalhe_test.dart`
- `app/test/demanda_painel_test.dart`
- `app/test/demanda_reabertura_test.dart`
- `app/test/demanda_status_controls_test.dart`
- `app/test/demandas_atualizacao_local_widget_test.dart`
- `app/test/demandas_tempo_local_widget_test.dart`
- `app/test/demandas_view_model_test.dart`
- `app/test/log_time_calendar_creation_test.dart`
- `app/test/support/fake_agenda_repositories.dart`
- `app/test/support/fake_demanda_repository.dart`
- `app/test/ux_card_surfaces_test.dart`
- `app/test/widget_test.dart`
- `docs/pacote4-painel-demandas.md`
- `docs/roadmap.md`
- `scripts/migrations/test_pacote4.py`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/anotacoes/anotacao_demanda.dart`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/client.dart`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/protocol.dart`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/registros_tempo/registro_tempo.dart`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/registros_tempo/registro_tempo_create_request.dart`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/registros_tempo/registro_tempo_update_request.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/anotacoes/anotacao_demanda.spy.yaml`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/anotacoes/anotacao_demanda_endpoint.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/demandas/demanda_endpoint.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/anotacoes/anotacao_demanda.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/endpoints.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/protocol.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/protocol.yaml`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/registros_tempo/registro_tempo.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/registros_tempo/registro_tempo_create_request.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/registros_tempo/registro_tempo_update_request.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo.spy.yaml`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo_create_request.spy.yaml`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo_endpoint.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo_normalizacao_service.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo_observacao_service.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo_update_request.spy.yaml`
- `serverpod/temdas_backend/temdas_backend_server/migrations/20261029183226724-pacote4-demandas/definition.json`
- `serverpod/temdas_backend/temdas_backend_server/migrations/20261029183226724-pacote4-demandas/definition.sql`
- `serverpod/temdas_backend/temdas_backend_server/migrations/20261029183226724-pacote4-demandas/definition_project.json`
- `serverpod/temdas_backend/temdas_backend_server/migrations/20261029183226724-pacote4-demandas/migration.json`
- `serverpod/temdas_backend/temdas_backend_server/migrations/20261029183226724-pacote4-demandas/migration.sql`
- `serverpod/temdas_backend/temdas_backend_server/migrations/migration_registry.txt`
- `serverpod/temdas_backend/temdas_backend_server/test/integration/demanda_status_test.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/integration/demanda_v1_endpoint_test.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/integration/pacote4_endpoint_test.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/integration/pacote4_observacao_concorrencia_test.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/integration/relatorio_endpoint_test.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/integration/test_tools/serverpod_test_tools.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/unit/registro_tempo_observacao_test.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/unit/sprint_integrity_migration_test.dart`
