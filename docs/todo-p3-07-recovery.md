# TODO-P3-07 — recuperação de fontes

Esta branch recompõe a release a partir da base `0e8638963092e15429eb105b23b3416557c85a62`.

A migration SQL foi recuperada integralmente do transcript da sessão Codex de
13/11/2026 às 17:10:05, conforme `provenance.txt` preservado no diretório de
recuperação local. Seu SHA-256 é
`24377fea1c62a3ab0328f1ae9ba8430856a495a469474871da358e888322e037`.
O arquivo de proveniência não é incluído no repositório porque aponta para
metadados de sessão locais.

Os patches íntegros da sessão de implementação foram reaplicados. Dois patches
de UI estavam truncados no histórico; os comportamentos de título inline e de
autocomplete/hierarquia foram recompostos usando os componentes e formatadores
já existentes. Os modelos e protocolos foram regenerados com Serverpod a partir
do schema atualizado. A revisão PROD-02 da sessão das 19:44 descrevia um bundle
de fontes anterior e não constitui evidência para esta reconstrução.

## Validação da reconstrução — 14/11/2026

Commit da recomposição: `010a72b836e7f9ead024233126559ef2de930d5b`.

- SQL: SHA-256 `24377fea1c62a3ab0328f1ae9ba8430856a495a469474871da358e888322e037`.
- Fingerprint de fontes backend/migrations calculado pelo PROD-02:
  `9aaede384316482524590ff96e723d31bc08c65ed512e80441fd5c3d12931aeb`.
- Bundle Web `main.dart.js`: SHA-256
  `2c3998936b11296ccbc5d4b1cc3eba32d409458966f78bbd159cdb93bb1fca82`.
- Fingerprint das entradas do build Web (159 arquivos):
  `5a0fa1b8de88a42a34b304c5d6494a35bd2c47b86e0128883dce5089b950a474`.
- Flutter: quadro de To-dos passou 12 testes; `flutter analyze` sem problemas.
- Serverpod: testes unitários de schema Sprint passaram (2); `dart analyze` não
  apontou problemas nos arquivos diretamente relacionados. O analyze global
  registrou dois avisos `info` preexistentes em observação de Log Time.
- Python: testes de registry/validação PROD-02 passaram (26).
- O backend compilou como executável local. O SQL está registrado como
  `access_exclusive_lock_and_default_review` pelo analisador oficial e precisa
  da revisão manual específica prevista no PROD-02.
- A integração `todo_endpoint_test.dart` não chegou a executar casos: o runner
  encerrou no carregamento do arquivo, sem diagnóstico. O mesmo ocorreu com o
  teste de controle `greeting_endpoint_test.dart`, usando o runner oficial e
  banco PG17 descartável. Essa validação segue pendente para um ambiente em que
  a suíte Serverpod possa iniciar.

O build Web contém os destinos de produção do workflow e não contém localhost
nem o projeto Supabase de desenvolvimento. Nenhuma migration foi aplicada em
produção e nenhum deploy foi executado. O ensaio PROD-02 completo deve ser
repetido com estes fontes antes de solicitar autorização de publicação.
