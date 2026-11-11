# UX-P2-06 · Revisão visual da Lista

[Galeria comparativa](index.html) · [Comparação automatizada do Kanban](comparacao-kanban.json)

## Evidências

- Capturas do Flutter Web em Chromium, com dados fictícios e os mesmos componentes e fixtures nas duas versões. Desktop de 1440 × 1000 px e mobile de 390 × 1000 px, ambos a 1×.
- A base `2b66feb` tem o mesmo código Flutter que a versão homologada `ce6359f`. Os 16 pares do Kanban (Normal e Compacto, temas claro e escuro, recolhido e expandido) são idênticos byte a byte.
- As 20 capturas da Lista revisada mostram a matriz de densidade, tema, largura e expansão, além dos agrupamentos por Status e Prioridade. O agrupamento por Demanda mostra mãe, filha e neta. Os casos usam títulos longos e três vínculos de Sprint.
- A ação Concluir demanda tem check e rótulo, com separação vertical mínima de 12 px após o progresso. A expansão preserva descrição, comparativo de horas e ações. O recuo e a linha vertical representam a hierarquia.
- `dart format` concluído, `flutter analyze` sem ocorrências e 109 testes direcionados aprovados após as reexecuções afetadas. A suíte completa ficou fora desta etapa.

## Diagnósticos durante a validação

- O teste de Lista Normal encontrou dois `LinearProgressIndicator` sob `demanda-card-24` em `ux_p2_06_test.dart:78`. A primeira abordagem ocultava o medidor da linha com `Opacity`, mantendo-o na árvore de widgets. Um espaçador com as mesmas dimensões agora mantém o alinhamento sem criar o segundo indicador. O teste verifica um único indicador e a distância até a ação.
- A primeira execução do Flutter nas cópias descartáveis encontrou `FileSystemException: Failed to set file modification time (OS Error: Read-only file system, errno = 30)` ao atualizar o estado local de telemetria. As compilações debug concluíram com a permissão de execução local.
- A primeira captura abortou com `TypeError: Failed to fetch dynamically imported module` e timeout no Playwright porque o harness bloqueava o CanvasKit externo. O navegador passou a usar os arquivos CanvasKit das duas compilações locais.
- Em mobile, o agrupamento por Prioridade posicionou a mãe fictícia abaixo do viewport inicial. O roteiro falhou com `AssertionError: Chevron da mãe não encontrado no viewport`. A captura desse cenário foi repetida com rolagem até a mãe, sem alterações no aplicativo.
