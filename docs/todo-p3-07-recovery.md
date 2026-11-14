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

No momento deste registro, testes, builds e ensaio PROD-02 ainda precisam ser
executados sobre os fontes desta branch. Nenhuma migration foi aplicada em
produção e nenhum deploy foi executado.
