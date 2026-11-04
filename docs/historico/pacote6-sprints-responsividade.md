# Pacote 6 — Sprints e responsividade global

Implementação exclusivamente Flutter na branch `feat/pacote-6-sprints-responsividade`,
baseada na main atualizada `543bdba`. Pacotes 4/5 preservados; sem backend, banco,
migrations, dependências ou configuração sensível alterados.

## Sprints

- Lista em grade responsiva (uma, duas ou três colunas), Sprint ativa primeiro
  com cor/borda semânticas; histórico expansível agrupado por status e ordenado
  por fim do período, mais recente primeiro. Datas e nomes podem quebrar linha.
- Card abre o mesmo componente de painel usado por Demandas: 420 px no desktop,
  mínimo 360 px e máximo ~70% da viewport; arraste, ícone, teclado e leitor de tela
  preservados. Em celular (<840 px), tela cheia.
- Preferências independentes: `temdas.sprint.painel.largura` e
  `temdas.sprint.vinculos.largura`; chave original de Demandas preservada.
- O painel reutiliza `SprintDetalhePage`, operações, diálogos e validações atuais.
  Edição, início elegível, conclusão, reabertura, cancelamento, exclusão e vínculos
  continuam submetidos às mesmas regras. A implementação duplicada do resumo
  central foi substituída pelo componente compartilhado, sem novos endpoints.
- Exibe período/status, horas previstas/estimadas/executadas e progresso de
  Demandas concluídas calculado dos vínculos carregados. Progresso é apresentação;
  não conduz nem altera transições ou regras de conclusão.
- Navegação entre painéis preserva a Sprint ao abrir/fechar uma Demanda. Retorno
  atualiza demandas, vínculos e indicadores para evitar resumo desatualizado.
  URL de detalhes e abertura em nova aba no Web permanecem disponíveis.
- Loading, falhas, retry e estados vazios preservam ações habilitadas apenas nas
  condições já existentes; estados vazios/erro podem rolar com texto ampliado.

## Fechamento responsivo

- Demandas: áreas de toque de ações/status com mínimo de 48 px; Kanban/Lista,
  hierarquia, densidades e painel continuam compartilhando dados e operações.
- Toolbar: título preserva quebra de linha; região contextual limita altura com
  texto ampliado, mantendo controles acessíveis por rolagem e corpo utilizável.
- Log Time: indicador tem rótulo compacto em celular, preservando valor/período;
  agenda mantém Dia/Semana, alinhamento, snap, criação, edição e arraste.
- Relatórios: em tela estreita/texto ampliado, resumo e cards hierárquicos usam
  uma única rolagem, exibindo status, prioridade e os três totais; tabela continua
  no desktop. Geração/exportação usam os mesmos dados.
- Perfil: conteúdo autenticado/admin testado em três larguras; erro/sessão expirada
  roláveis, sem perder o acesso à ação. Navegação mantém drawer e tema existentes.
- Login/MFA e confirmação/recuperação: padding menor em celular, sem alterar
  campos, Enter, autofill, autenticação, provisionamento ou tratamento de tokens.
- Formulários de Sprint e Log Time conferidos também com teclado ocupando espaço.

## Evidências e limites

- Rodada principal: **122 testes aprovados**, incluindo matriz de 42 cenários
  (sete telas/formulários × três larguras × dois temas), texto ampliado, Perfil
  autenticado/admin e MFA com fixtures locais, relatórios, Sprints e painéis.
- Regressões dos componentes efetivamente alterados: **150 testes aprovados**,
  em arquivos distintos da rodada principal. Suítes completas anteriores não
  foram repetidas; testes afetados foram reexecutados somente após correções.
- Testes específicos verificam resize sem novas consultas, persistência,
  preferências isoladas, Sprint↔Demanda e cancelamento preservando Demandas.
- Prévias locais usam dados sintéticos e fontes do app, em desktop claro e celular
  escuro; não equivalem à homologação interativa em navegador/dispositivo real.
- Regressão adicional do painel com contexto novo confirma consulta às Sprints
  existentes antes de habilitar início. A URL direta preserva o fluxo existente
  de conflito validado pelo backend e navegação para a Sprint ativa; sem mudar regras.
- Fechamento: **57 testes de revalidação** aprovados após o ajuste de navegação
  e conflitos (sobrepostos às rodadas anteriores, com uma regressão adicional).
  Análise limpa, formatação/diff válidos e build Web release aprovados.
  O aviso preexistente de CupertinoIcons é não bloqueante, sem nova dependência.
- Publicação frontend autorizada: integrar main atualizada, push sem força e
  acompanhar `.github/workflows/deploy-pages.yml`; conferir HTTPS, arquivos do
  commit publicado, revalidação de cache e fallback SPA em `temdas.com.br`.
- Homologação visual autenticada final fica com o responsável; não foram usados
  dados/credenciais pessoais nem executadas mudanças no backend ou infraestrutura.
