# Pacote 5 — toolbar contextual e Demandas

Implementação frontend na branch `feat/pacote-5-toolbar-demandas`, baseada na
main `225391028127e10a2e66b6397e2298bc3c488364`, com Pacote 4 preservado.
Sem alteração de backend, migrations, banco, dependências ou configuração PROD.

## Entrega

- `PageScaffold`: título, região contextual flexível e tema sempre no extremo
  superior direito. Desktop aproveita a linha inteira; tablet/celular reorganizam
  controles com Wrap. Em altura reduzida/texto ampliado, apenas a região contextual
  pode rolar; título e tema ficam fixos. O conteúdo mantém sua rolagem independente.
- `PageToolbar`: busca sempre visível, que cresce com a largura disponível.
  Controles existem apenas no cabeçalho, sem duplicação no corpo.
- Tema por ícone usa a preferência existente e trata falha de armazenamento.
  Sistema continua disponível no menu de configuração. A mesma posição do ícone
  está presente em login, MFA, recuperação/convite e estados da sessão; nenhuma
  operação, validação, permissão ou regra de autenticação foi alterada.
- Demandas: pesquisa local por ID/título, caixa/acentos normalizados pelo helper
  existente; ID exato tem precedência, incluindo prefixo `#`. Um único popup
  agrupa prioridade e Sprint aberta/sem Sprint, quantidade ativa e Limpar filtros.
  Limpar filtros preserva a busca; limpar busca preserva os filtros.
- Sprint considera exclusivamente os vínculos `SprintDemanda` de Sprints abertas.
  A lista de Sprints já retornada pelo repositório passa a ser reaproveitada no
  ViewModel, inclusive Sprints sem vínculos; não há uma consulta duplicada.
  O popup acompanha a consulta em andamento e bloqueia seleção em falha.
- Busca/filtros combinados mantêm os ancestrais e expandem o caminho dos
  resultados. Totais de horas usam a árvore completa, inclusive filhas ocultas
  pelos filtros. Movimentação filtrada permanece bloqueada conforme o fluxo atual.
- Kanban segue padrão, com os mesmos handlers de drag-and-drop e hierarquia.
  Compacto usa colunas de 288 px, espaçamento de 8 px, menor padding e separação
  entre cards de 4 px. Normal continua disponível no controle secundário de
  densidade. Prioridade, ID, título, Sprint e tempos continuam acessíveis.
- Lista é sempre compacta, agrupada pelo status da raiz para manter a mesma
  árvore do Kanban; descendentes exibem seu próprio status. Reutiliza expansão,
  ações/transições, totais e abertura do painel lateral. Controle de status fica
  disponível sem expandir; em larguras menores é um ícone com tooltip, mantendo
  área de toque de 48 px. Não há alvos/handles de arraste na Lista.
- Kanban/Lista persiste em `temdas.demandas.visualizacao` via SharedPreferences,
  com Kanban como fallback. Carga inicial não sobrescreve escolha manual; gravações
  rápidas são serializadas. Indisponibilidade local não impede usar a página.
- Sprint: ações da lista e do detalhe no cabeçalho compartilhado. Log Time:
  navegação de datas, Dia/Semana e Lançar tempo no cabeçalho. Relatórios: período,
  filtros, geração e exportação no cabeçalho. Perfil: apenas atualização aplicável.

## Validação

Os testes direcionados cobrem toolbar em desktop/tablet/celular e texto ampliado,
posição/área de toque do tema, persistência e Sistema; busca normalizada, filtros
combinados, ancestrais, Sprint sem vínculos, loading, ausência de resultados,
limpeza independente, alternância, densidade, status, abertura/expansão e totais.
Os testes existentes preservam edição, exclusão, arraste, atualização local,
painel/anotações/horas, Sprint, agenda, relatórios, perfil e autenticação/MFA.

Resultados do fechamento:

- `flutter analyze --no-pub`: sem problemas.
- Rodada final das 21 suítes afetadas: **202 testes aprovados**, incluindo **21
  novos** de toolbar, preferência, filtros e Lista; correções finais de áreas de
  toque/rolagem revalidadas em **49 testes direcionados** (com sobreposição à
  rodada anterior) dos cards, página e toolbar.
- Regressões de login, MFA, sessão e confirmação/recuperação passaram em rodada
  direcionada anterior; não houve mudança das operações de autenticação.
- `flutter build web --release --no-pub --base-href=/` com os defines públicos
  existentes: aprovado. O aviso pré-existente de fonte CupertinoIcons permanece
  não bloqueante; nenhuma dependência foi adicionada para silenciá-lo.
- Formatação e `git diff --check` aprovados; sem arquivos de backend, schema,
  dependências ou infraestrutura no diff.

Prévias locais usam dados fictícios em temas claro/escuro; não equivalem
à homologação interativa em navegador/dispositivo real. Nenhum acesso autenticado
pessoal, operação de dados, push, merge ou deploy faz parte desta execução.

## Revisão e publicação

Revisar o diff e homologar visualmente toolbar, filtros, Kanban/Lista e controles
responsivos antes de autorizar publicação. A integração do Pacote 4 permanece
intacta. Publicação futura é exclusivamente frontend, sem migration ou deploy de
backend exigidos por este pacote.
