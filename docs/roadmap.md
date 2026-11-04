# Roadmap oficial do TEMDAS

Este documento consolida o estado funcional conhecido, melhorias aprovadas e
ideias ainda em avaliação. Ele complementa as regras de domínio e arquitetura;
não as substitui. Quando houver conflito, prevalecem as regras descritas em
`arquitetura.md`, `escopo_temdas_v1_atualizado.md`, `transicoes-status.md` e na
documentação específica de autenticação e Sprint.

## Estados

- **Concluído**: implementado no produto ou na infraestrutura documentada.
- **Parcial**: há suporte atual, mas a melhoria descrita ainda não está completa.
- **Aprovado / pendente**: faz parte da evolução desejada, ainda sem entrega.
- **Em avaliação**: possibilidade documentada, sem compromisso de escopo ou prazo.
- **Recorrente**: verificação exigida quando ocorrer a atividade indicada.

As prioridades P1, P2 e P3 seguem a ordem de produto solicitada. Infraestrutura
usa prioridade operacional, conforme sua relação com homologação e produção.

## Pacote de refinamento UX — novembro de 2026

Implementação Flutter na branch `feat/refinamento-ux-novembro-2026`, sem
mudanças de backend. O commit `fd60790` foi publicado em produção pelo
[workflow do Cloudflare Pages](https://github.com/Fokelvin/temdas/actions/runs/41701908873).
A página e os arquivos de inicialização Flutter responderam HTTP 200 em
`temdas.com.br`.

- Sprint: o resumo abre a Sprint na mesma aba. A lista de vínculos oferece
  somente desvinculação confirmada, conforme estado e hierarquia. A exclusão
  de Demandas não está disponível nos detalhes abertos pela Sprint. Cada
  linha mostra sua estimativa própria ao lado do título, inclusive em
  **Mostrar tudo**, sem recalcular indicadores.
- Log Time: a edição carrega a observação salva. O lançamento abre direto,
  inclusive no calendário sem Demandas. A busca ignora acentos e caixa;
  o formulário compartilhado cria e seleciona a Demanda mantendo o rascunho.
  O registro de horas ainda exige confirmação explícita.
- Seleção de texto: uma área por superfície nas telas principais e painéis,
  com seleção própria dos campos de edição.

Validação local: `flutter analyze --no-pub` sem apontamentos. Os lotes
finais passaram com 41 testes de Log Time, seleção e arraste e 69 de Sprint,
painéis e arraste de Demandas. A cobertura inclui temas claro e escuro,
larguras a partir de 320 px e densidade compacta nas telas de Demandas.
Um único build Web release foi concluído em 40,9 s, com aviso de fonte
Cupertino. SHA-256 de `main.dart.js`:
`3ddc0e9e05b4e22b87c012f60ac3c1fcbdc487153dd676187cbf0a3d7312c80d`.

**Estado:** pacote publicado e homologado funcionalmente pelo responsável
em PROD em 03/11/2026. O ajuste adicional da agenda semanal do Log Time
(domingo a sábado) foi publicado no commit `bc50b1a` e homologado pelo
responsável. Os cenários de seleção/cópia por toque, arraste, títulos longos e
teclado virtual permanecem cobertos pelas validações automatizadas pertinentes
e sujeitos a acompanhamento de regressões em dispositivos reais.

## Resumo das funcionalidades

### Concluídas

- Cadastro, consulta, edição e exclusão de Demandas, inclusive hierarquia de
  demandas filhas e regras de exclusão da árvore.
- Fluxo de status controlado pelo backend, com conclusão, reabertura,
  cancelamento e regras de cascata documentadas.
- Registro manual de tempo, consultas diária e semanal, e comparação entre
  tempo estimado e executado.
- Board de Demandas com movimentação por drag-and-drop e feedback de
  persistência.
- Planejamento e gerenciamento de Sprints, indicadores e vínculos preservados
  por `SprintDemanda`.
- Autenticação Supabase integrada ao app, provisionamento de usuário interno,
  exigência AAL2 nas rotas funcionais, MFA TOTP, recuperação de senha e fluxo de
  convite de administrador implementados e homologados em PROD. Recovery exige
  confirmação explícita do link e TOTP quando há fator verificado; convites
  preservam o onboarding sem privilégio administrativo automático.
- Interface com sistema visual, temas claro/escuro e densidade de cards.
- Home page pública do TEMDAS concluída e aceita em 30/10/2026 (`ebac0323`), com cinco seções, prévias locais e entrada para autenticação existente; refinamentos de login lateral, privacidade e versão seguem no UX-FUT-06.
- Pacote 4 em PROD: painel lateral de Demandas com Visão geral, Anotações e Horas;
  observações opcionais de Log Time e migration aplicada com preservação de dados.
- Publicação em `https://temdas.com.br` (Cloudflare Pages), backend Railway e
  Supabase PROD; SMTP Resend e callbacks alinhados ao domínio oficial.
- Backup PROD automático criptografado no WSL e F:, restauração SQL isolada
  comprovada e controle semiautomatizado de migrations com aprovação separada.

### Melhorias aprovadas

As seções P1, P2, P3 e Infraestrutura registram o trabalho ainda desejado e seu
estado atual. “Aprovado” indica direção de produto, não uma alteração das regras
de domínio existentes.

### Ideias em avaliação

Timer automático, etiquetas, anexos, notificações, integrações com calendário
ou n8n, dashboard avançado, histórico persistente de alterações e promoção de
demanda filha a raiz constam como fora da V1 ou possibilidades futuras na
documentação de escopo. Continuam sem compromisso de implementação até decisão
de escopo.

## P1 — UX/UI e produtividade

### UX-P1-01 — Visão e organização de Sprints

- **Descrição:** destacar a Sprint ativa, diferenciar visualmente os status e
  organizar o histórico. O Pacote 6 usa histórico expansível por status/período
  e painel lateral redimensionável para os detalhes.
- **Prioridade:** P1.
- **Estado:** Concluído e homologado em PROD no Pacote 6: ativa destacada, grade responsiva e histórico expansível por status/período.
- **Dependências:** preservar a apresentação aprovada, o ciclo de
  vida e as transições de Sprint existentes.
- **Critérios de aceite:** a Sprint ativa é identificável; status distintos
  podem ser reconhecidos visualmente; o histórico fica organizado e acessível.

### UX-P1-02 — Integração visual entre Demandas e Sprints

- **Descrição:** completar a navegação e as ações de associação entre as telas
  de Demandas e Sprints, incluindo acesso à Sprint em nova aba ou alternativa
  de navegação a decidir, e resumo contextual. O resumo de Sprint, painel de
  Demandas vinculadas e abertura dos detalhes já existem.
- **Prioridade:** P1.
- **Estado:** Concluído e homologado em PROD no Pacote 6: navegação entre painéis, URL/nova aba e atualização contextual de vínculos e indicadores, exclusivamente via SprintDemanda.
- **Dependências:** usar `SprintDemanda` como fonte do vínculo.
- **Critérios de aceite:** quando uma Demanda tiver Sprint aberta vinculada, a
  interface a identifica; quando não tiver, mostra “Sem Sprint”. Não criar
  campo `sprint` em `Demanda`. As ações de associação e navegação respeitam as
  regras atuais de Sprint.

### UX-P1-03 — Abertura da Demanda em popup e ações completas

- **Descrição:** ao clicar no corpo do card de uma Demanda, abrir sua visualização
  em popup. O ícone de expandir do card deve manter exclusivamente o comportamento
  atual de expansão/recolhimento inline, sem abrir o popup. O popup deve exibir de
  forma visível todas as ações disponíveis para aquela Demanda e seu estado.
- **Prioridade:** P1.
- **Estado:** Concluído e homologado em PROD no Pacote 4; popup entregue como painel lateral responsivo, preservando clique no card e expansão independente.
- **Dependências:** preservar o comportamento atual de expansão do card, as
  permissões e as regras de status, hierarquia, Sprint e exclusão já existentes.
- **Critérios de aceite:** clicar no card abre o popup da Demanda; clicar no ícone
  de expandir apenas expande ou recolhe o card; o popup apresenta todas as ações
  aplicáveis à Demanda sem exigir que o usuário volte ao card para executá-las; as
  ações produzem os mesmos resultados e validações já definidos no fluxo atual.

### Gerenciamento de vínculos de Sprint em Demandas

- **Estado:** Implementado na branch `feat/sprints-na-tela-demandas`.
  Publicado em produção no SHA `417211c`. Homologação funcional
  confirmada pelo responsável.
- O cadastro compartilhado de Demandas, inclusive no Log Time, permite
  selecionar Sprints abertas opcionalmente. A edição exibe o histórico e aplica
  somente as alterações de vínculo solicitadas ao salvar. O painel permite
  vincular e desvincular com confirmação e atualiza a seção de Sprints e o
  contexto da listagem após a operação.
- O modo explícito de seleção usa a RPC `vincularDemandas` e atualiza o filtro
  **Sem Sprint** a partir da leitura dos vínculos. O arraste fica desativado
  enquanto a seleção em lote está ativa.
- Os endpoints existentes mantêm `SprintDemanda` e validam autorização, estado,
  períodos e hierarquia. Cadastro/edição e cada mutação de vínculo são operações
  distintas. Em sucesso parcial, a Demanda e os vínculos já gravados são
  preservados, e as falhas são exibidas por Sprint.
- **Validação local:** `flutter analyze --no-pub` sem apontamentos e 107 testes
  direcionados aprovados, incluindo cadastro com e sem Sprint, conflito após
  gravação parcial, histórico, painel, lote com filtro, Log Time, hierarquia
  e arraste. A cobertura inclui temas claro e escuro, telas estreitas e
  regressões de densidade compacta. Um único build Web release foi concluído
  em 40,9 s, com aviso de fonte Cupertino. SHA-256 de `main.dart.js`:
  `a3aca934c8a4725dcccd1b9e6fb583817e6b045e5ed972816f02715b329e8e9f`.
- **Homologação manual:** verificar conflitos de período e vínculos herdados com
  dados representativos, seleção em Lista e Kanban com teclado e toque e
  retorno ao lançamento de tempo após criar uma Demanda vinculada.

### Enviar para Backlog

- **Estado:** Funcionalidade futura, pendente de definição.
- Definir em que situações a ação estará disponível e quais efeitos terá sobre
  vínculos abertos, histórico e hierarquia de Demandas.

### UX-P1-04 — Painel lateral de Sprint e ações contextuais

- **Descrição:** ao clicar no corpo do card/item de uma Sprint, abrir **painel
  lateral à direita**, reutilizando o mesmo componente e os mesmos comportamentos
  do painel de Demandas (Pacotes 4/5), adaptando apenas o conteúdo ao domínio
  de Sprint. Não abrir modal central para os detalhes. Se existir controle de
  expandir/recolher o item, seu acionamento permanece independente da abertura
  do painel.
- **Comportamento visual:** largura inicial **420 px** no desktop; ajuste
  horizontal arrastando a borda esquerda, ícone no cabeçalho para ampliar/reduzir
  (até cerca de 70% da viewport) e preferência de largura persistida no
  navegador. Em telas pequenas, painel em tela cheia. Cabeçalho fixo, conteúdo
  com rolagem própria, informações condensadas, temas claro/escuro e fechamento
  previsível. Preservar navegação por URL e abertura em nova aba quando aplicável.
- **Conteúdo e ações:** mostrar resumo da Sprint, status, período, progresso,
  horas, Demandas vinculadas e ações contextuais existentes, incluindo
  “Iniciar Sprint” e “Adicionar Demanda” somente quando permitidas. Usar
  organização interna apropriada à Sprint, sem copiar literalmente as três
  abas específicas de Demanda (Visão geral/Anotações/Horas).
- **Prioridade:** P1.
- **Estado:** Concluído e homologado em PROD no Pacote 6: painel compartilhado de 420 px, redimensionamento, preferência independente e ações existentes; sem modal central de detalhes.
- **Dependências:** reutilizar componentes de painel e redimensionamento dos
  Pacotes 4/5, `SprintDemanda` e regras atuais do backend/ciclo de vida da Sprint.
  Sem antecipar mudança de schema ou regras de negócio.
- **Critérios de aceite:** clique no item abre o painel; expansão inline,
  quando existente, continua independente; experiência de largura, arraste,
  ampliação, persistência, responsividade e fechamento é consistente com
  Demandas; ações são oferecidas apenas nos status permitidos; remoções
  respeitam hierarquia e vínculos; dados e indicadores permanecem corretos.

### UX-P1-05 — Indicadores de carregamento em Sprints

- **Descrição:** completar feedback visual durante consultas, especialmente na
  abertura do resumo e no carregamento de indicadores e vínculos.
- **Prioridade:** P1.
- **Estado:** Concluído e homologado em PROD no Pacote 6: feedback nas consultas e operações, erros compreensíveis, retry e estados vazios roláveis.
- **Dependências:** consultas existentes da página de Sprints.
- **Critérios de aceite:** uma consulta em andamento tem feedback visível e
  uma falha oferece estado compreensível e possibilidade de tentar novamente,
  quando aplicável.

### UX-P1-06 — Fechamento de validação da V1

- **Descrição:** concluir as validações funcionais e visuais que a documentação
  da V1 ainda registra como pendentes.
- **Prioridade:** P1.
- **Estado:** Aprovado / pendente de validação documentada.
- **Dependências:** disponibilidade dos ambientes e fluxos de homologação.
- **Critérios de aceite:** validar fluxos V1 de ponta a ponta, regressões de
  status e hierarquia, drag-and-drop em colunas vazias e preenchidas,
  consistência dos temas claro/escuro e comportamento responsivo nas densidades
  normal e compacta.

## P2 — Refinamentos de autenticação e interface

Esta seção reúne refinamentos frontend concluídos e aprovados. A navegação
unificada (UI-P2-04) e o contraste do modo escuro (UI-P2-05) estão pendentes
de implementação; preservar login, MFA obrigatório e interações do Flutter Web.
AUTH-P2-01 permanece adiado para o último item deste roadmap.

### UX-AUTH-03 — Entrada por painel lateral e correção da navegação pública

- **Descrição:** na home page pública, o botão **Entrar** abre um painel
  lateral de login à direita (aprox. 420 px no desktop e tela cheia no
  celular), em vez de substituir a home pela rota `/#/demandas`. Manter a
  URL pública enquanto o painel estiver aberto; fechar com X, Escape ou
  Voltar do navegador, retornando à home sem perder a navegação. Reutilizar
  o formulário e os fluxos existentes de login/recuperação.
- **Prioridade:** P2, antes da consolidação das mensagens de autenticação.
- **Estado:** **Concluído, publicado e homologado manualmente em PROD em 30/10/2026** (commit `23f3ec4`). Painel de 420 px no desktop e tela cheia no mobile, com fechamento por X/Escape/Voltar e preservação da home/URL.
- **Dependências:** UX-FUT-06 (home page já publicada); preservar AuthGate,
  provisioning, AAL2/MFA, callback, convite, recuperação de senha e proteção
  das rotas privadas. Não duplicar AuthGate nem a lógica de autenticação.
- **Critérios de aceite:** Entrar não navega para `/#/demandas` sem sessão;
  painel abre/fecha corretamente, inclusive com Voltar; após login válido
  o fluxo de MFA existente continua e só então libera o aplicativo; links
  profundos privados continuam funcionando sob AuthGate. Somente frontend.

### AUTH-P2-02 — Mensagens e estados de autenticação

- **Descrição:** uniformizar mensagens compreensíveis e estados visuais de
  autenticação, recuperação de senha e falhas recuperáveis, sem expor dados de
  conta ou detalhes sensíveis do provedor.
- **Prioridade:** P2.
- **Estado:** **Concluído, publicado e homologado manualmente em PROD em 30/10/2026** (commit `23f3ec4`). Login, recuperação e MFA compartilham feedback acessível e carregamento explícito; erros do provedor são sanitizados e permitem nova tentativa.
  Recuperação mantém confirmação genérica e login não distingue contas
  inexistentes, credenciais incorretas ou e-mail não confirmado.
  Validação conjunta com UX-AUTH-03: `flutter analyze` sem ocorrências e
  228 testes afetados aprovados, incluindo callbacks, convites, deep links,
  fechamento do painel e exigência de AAL2. AUTH-P2-01 permanece adiado.
- **Dependências:** contratos de erro documentados em `auth-callback-flutter.md`
  e nas páginas de autenticação.
- **Critérios de aceite:** mensagens preservam proteção contra enumeração;
  falhas de rede/servidor permitem nova tentativa; AAL2 permanece obrigatório.

### UI-P2-03 — Seleção global de texto no Flutter Web

- **Descrição:** habilitar seleção de texto global com `SelectionArea`, sem
  prejudicar menus, botões, campos ou gestos de interação.
- **Prioridade:** P2.
- **Estado:** Implementado, publicado e homologado funcionalmente em PROD
  pelo responsável em 03/11/2026 (pacote de refinamento UX de novembro).
- **Dependências:** validar interações nas telas e componentes interativos.
- **Critérios de aceite:** textos informativos podem ser selecionados nas
  telas principais e ações e campos continuam operáveis.

### UI-P2-04 — Navegação lateral unificada em todas as telas

- **Descrição:** substituir os drawers/menus laterais legados nas demais telas
  pelo mesmo menu lateral moderno atualmente utilizado em **Demandas**
  (referência visual aprovada em 04/11/2026). Manter um único componente
  compartilhado para navegação, branding, ícones, textos, estados ativos e
  ações de usuário, evitando implementações divergentes por página.
- **Prioridade:** P2 — correção de consistência do redesign frontend.
- **Estado:** Implementado na branch `feat/ui-p2-04-menu-lateral`. Publicação e
  homologação em produção pendentes. Análise Flutter, testes direcionados
  de navegação, perfil, logout, tema e responsividade e um build Web release
  concluídos localmente.
- **Escopo:** uniformizar a navegação lateral de Demandas, Sprints, Log Time,
  Relatórios e demais rotas autenticadas que exibam o menu. Preservar destinos,
  permissões, seleção da rota ativa, acesso a Meu Perfil e saída da sessão,
  com comportamento responsivo em desktop e mobile.
- **Identidade visual:** corrigir também o cabeçalho do menu moderno de
  Demandas: substituir o avatar quadrado com a letra genérica `T` pela logo
  oficial do TEMDAS. Reutilizar os assets já presentes em `app/assets/images/`
  (por exemplo `temdas_logo.png` para o símbolo e/ou `temdas_texto.png`/
  `temdas_wordmark_transparent.png` para a marca escrita), conferindo o uso
  correto, proporções e contraste nos temas claro/escuro; não criar marca nova
  nem recuperar o layout legado do drawer. Replicar o cabeçalho corrigido em
  todas as telas via componente compartilhado.
- **Tema:** retirar o ícone/controle de alternância claro/escuro do menu
  lateral, inclusive na versão de Demandas, pois o controle já existe na barra
  superior compartilhada. Não remover a alternância da barra superior nem
  alterar a persistência da preferência de tema.
- **Critérios de aceite:** todas as páginas exibem o mesmo componente e estilo
  de menu, com identidade visual oficial do TEMDAS no cabeçalho e item atual
  destacado; navegação funcional sem perder o estado de autenticação; ausência
  de controles de tema duplicados no menu;
  funcionamento consistente em telas pequenas e nos temas claro/escuro.
- **Impacto previsto:** frontend Flutter somente; reutilizar o menu existente
  em vez de redesenhar cada página. Sem alterações de schema, backend ou
  migrations. Publicação e homologação posteriores dependem de aprovação.

### UI-P2-05 — Contraste e hierarquia visual do modo escuro

- **Descrição:** corrigir a baixa distinção visual entre fundo da página,
  colunas e cards do TEMDAS no tema escuro. Melhorar o contraste de bordas,
  textos secundários, ícones, controles, chips de Sprint, indicadores de
  prioridade/status e estados ativos sem redesenhar as telas nem acrescentar
  informações.
- **Prioridade:** P2 — consistência visual, legibilidade e acessibilidade.
- **Estado:** Aprovado em 04/11/2026; **pendente de implementação, validação
  e publicação**. Não considerar concluído por existir um mockup HTML ou uma
  especificação visual.
- **Referência de design:** especificação
  `temdas-contraste-modo-escuro-flutter-codex.md` fornecida nesta conversa,
  versão 1.1 de 04/11/2026. É uma referência visual externa ao repositório:
  anexá-la ao Codex quando executar; não presumir que o arquivo está versionado.
- **Paleta e hierarquia:** fundo `#0b1220` (preservado), colunas/sidebar
  `#111a2b` (preservado), cards `#1a2640`; bordas de cards/colunas
  `#32446a`, controles `#52669a`; texto principal `#e6ebf5` (preservado),
  secundário `#c2cce0`, auxiliar `#a9b6cd`. Chip ativo de Sprint:
  fundo `#22365f`, borda `#2e4f8c`, texto `#9cc2ff`. Reforçar
  estado ativo de sidebar e Kanban/Lista com o azul `#4c8dff` em opacidades
  de 18% (fundo) e 55% (contorno). Preservar verde, âmbar e azul semântico
  atuais em seus demais papéis.
- **Detalhes pontuais:** trilho da barra de progresso `#3b4d75`, altura
  de 3 para **5 pixels lógicos**; bolinhas de prioridade/status de 6 para
  **8 pixels lógicos**; ícones e alças legíveis conforme a especificação.
  Revisar hover, foco, seleção e arraste para não perder visibilidade com
  a nova superfície de card.
- **Escopo técnico:** implementar **somente no Flutter Web/Dart**, convertendo
  os papéis visuais para o `AppTheme.dark`, `ColorScheme`, extensões/tokens
  e widgets reais de `app/lib/theme/` e das páginas. Não implementar
  HTML/CSS, não copiar seletor ilustrativo e não trocar hexadecimais
  globalmente sem identificar seus papéis. Aplicar superfícies equivalentes
  às telas Demandas (Kanban e Lista), Sprints, Log Time, Relatórios e
  componentes compartilhados (modais, popovers, menus).
- **Restrições:** não alterar **modo claro**, dados, textos, funcionalidades,
  rotas, regras de negócio, modelos, API, banco, fontes, espaçamentos, raios
  ou estrutura do layout. Admitir apenas as dimensões pontuais aprovadas na
  especificação e até 2 pixels lógicos de variação de altura do card pela
  barra de progresso. Itens opcionais do documento (botão primário e aviso
  visual para horas acima da estimativa) ficam **fora do escopo**, salvo
  aprovação específica.
- **Dependências:** coordenar com UI-P2-04 para reutilizar o menu lateral
  unificado em vez de criar implementações visuais divergentes. Verificar
  os valores reais dos tokens e widgets antes de editar; a origem dos hex
  foi uma captura, portanto os valores do fonte podem ter outra representação.
- **Critérios de aceite:** texto normal com contraste WCAG AA de pelo menos
  **4,5:1** e informações não textuais essenciais com **3:1**, quando
  aplicável; metas de separação das superfícies e bordas conforme a tabela
  de contrastes da especificação. Validar Kanban (inclusive coluna recolhida),
  Lista, Sprints, Log Time, Relatórios, modais e dropdowns; verificar estados
  interativos, responsividade, não regressão do modo claro, análise, build
  Web e testes afetados. **Sem commit, push ou deploy automático como parte
  da implementação inicial**; publicação exige aprovação posterior.

### SPR-P2-01 — Planejamento antecipado e histórico de múltiplas Sprints por Demanda

- **Contexto:** uma Demanda pode atravessar várias Sprints. Hoje o backend
  impede seu vínculo à Sprint futura planejada enquanto ela participa de
  outra Sprint ativa ou planejada, mesmo com períodos não sobrepostos.
- **Prioridade:** P2 — melhoria funcional aprovada em 30/10/2026.
- **Estado:** Publicado em PROD em 03/11/2026, API liberada para homologação manual.
  Migration original aplicada com ensaios aprovados e dados preservados.
  Otimização de vinculação em lote, timeout de 60 s e reconciliação por leitura
  publicados em `9d5b3af`: Railway `2fab0925` e Cloudflare `c68e8427` em sucesso.
  Saúde HTTPS 200, novo frontend renderizado, rejeição sem token e CORS conferidos;
  API permanece na porta 8080, sem nova migration ou alteração de infraestrutura.
  A vinculação dessa versão e seu desempenho real aguardam homologação manual;
  8,55 s/8 consultas é medição descartável com atraso artificial, não SLA de PROD.
  Histórico em [SPR-P2-01](spr-p2-01-multiplas-sprints.md) e publicação/medição
  em [vinculação em lote](spr-p2-01-vinculacao-lote.md).
- **Regra de vínculo:** permitir uma Demanda vinculada à Sprint ativa e
  simultaneamente a Sprints futuras planejadas, inclusive mais de uma, desde
  que os períodos não se sobreponham. Preservar o histórico das Sprints
  concluídas; nunca permitir duas Sprints ativas simultâneas para o usuário.
  O vínculo com uma Sprint futura não remove os vínculos anteriores.
- **Cancelamento:** ao cancelar uma Sprint, manter os registros
  `SprintDemanda` como histórico, sem tratá-los como compromissos atuais.
  Ao reabrir uma Sprint cancelada, revalidar períodos, vínculos e regras de
  ciclo de vida antes da transição. Vínculos de cancelamentos anteriores,
  já removidos pelo sistema, não são reconstruídos automaticamente.
- **Interface na Demanda:** substituir o indicador único **Sprint/Sem Sprint**
  por lista compacta das Sprints vinculadas, com nome/identificador e estado:
  **Ativa, Planejada, Finalizada e Cancelada** (`Finalizada` representa o
  estado interno `concluida`). Mostrar **Ativa** primeiro, com destaque
  discreto por fundo, cor ou negrito; depois futuras planejadas por data
  de início, seguidas de finalizadas e canceladas em ordem decrescente.
  Cada item permite abrir os detalhes da respectiva Sprint. Sem vínculos,
  continuar exibindo **Sem Sprint**.
- **Histórico retroativo e desempenho:** a consulta da Demanda deve retornar
  **todos os vínculos persistidos**, inclusive de Sprints finalizadas
  anteriormente (ex.: Sprint 72), mesmo quando não há Sprint aberta.
  Consultar vínculos e estados em lote no backend, evitando uma RPC por
  Sprint e sem limitar o resultado a um único vínculo por Demanda.
  Validar exibição consistente na listagem e no painel de detalhes.
- **Campo Nome da Sprint:** nos formulários de criação e edição, mostrar
  `Sprint` como prefixo visual fixo, imediatamente antes da parte editável
  (ex.: `Sprint` + `73`), sem permitir alterar o prefixo. Persistir apenas
  a parte editável e exibir `Sprint` uma única vez nas telas. Ao editar
  nomes legados que já contenham `Sprint` no início, normalizar o campo
  exibido para evitar `Sprint Sprint 73`, sem migração de dados obrigatória.
  Rejeitar ou normalizar a digitação/colagem do prefixo duplicado.
- **Interface de planejamento:** na Sprint planejada, permitir selecionar
  Demandas já vinculadas à Sprint ativa ou a outra planejada de período
  diferente. Indicar vínculos existentes e seus estados, sem bloquear
  indevidamente a seleção; manter bloqueio para sobreposição e demais
  regras de negócio.
- **Integridade:** ajustar validação transacional de vínculos, herança da
  árvore mãe/filhas, cancelamento e reabertura. Preservar `SprintDemanda`
  como fonte da verdade, unicidade por par Sprint–Demanda e controle de
  acesso; manter os lançamentos únicos, com horas calculadas no período
  de cada Sprint, sem duplicação. A estimativa total da Demanda permanece
  distinta do tempo previsto da Sprint.
- **Impacto:** alterações de backend e frontend; modelagem atual comporta
  múltiplos vínculos, sem nova entidade prevista. Avaliar migrations somente
  se indispensáveis, com aprovação humana separada para PROD.
- **Critérios de aceite:** planejar a próxima Sprint antes de encerrar a
  atual; manter ambos os vínculos visíveis; concluir Sprint antiga sem
  excluir vínculo futuro; preservar vínculos após cancelamento; exibir
  retroativamente a Sprint 72 finalizada na Demanda correspondente, inclusive
  na listagem e no detalhe, em consulta por lote; criar/editar nome com
  prefixo fixo `Sprint` sem exibição duplicada; exibir corretamente status e
  ordem na Demanda; impedir períodos conflitantes e transições inválidas;
  conservar integridade mãe/filhas, horas e MFA.

## P3 — Evolução funcional

### FUNC-P3-01 — Projeto vinculado à Demanda

- **Descrição:** permitir vincular um Projeto a uma Demanda e permitir que uma
  Sprint contenha Demandas vinculadas a múltiplos Projetos.
- **Prioridade:** P3.
- **Estado:** Aprovado / pendente; modelagem detalhada ainda exige decisão.
- **Dependências:** decidir a modelagem de Projeto e seu vínculo com Demanda;
  manter a relação Demanda–Sprint em `SprintDemanda`.
- **Critérios de aceite:** uma Demanda pode ser vinculada a um Projeto e uma
  Sprint pode conter Demandas vinculadas a múltiplos Projetos.

### ORG-P3-02 — Organizações e equipes

- **Descrição:** introduzir organizações e equipes como escopo de colaboração.
- **Prioridade:** P3.
- **Estado:** Aprovado / pendente de definição funcional.
- **Dependências:** definir modelo e relação entre organização, equipes e
  usuários.

### ORG-P3-03 — Membros e permissões por organização

- **Descrição:** gerir membros e permissões dentro de cada organização.
- **Prioridade:** P3.
- **Estado:** Aprovado / pendente de regras detalhadas.
- **Dependências:** ORG-P3-02 e definição de papéis e permissões.

### AUTH-P3-04 — Recuperação controlada de MFA e evolução do perfil

- **Descrição:** definir recuperação segura de MFA e ampliar as capacidades do
  perfil. A recuperação de senha existente não equivale à recuperação de MFA.
- **Prioridade:** P3.
- **Estado:** Aprovado / pendente de política e fluxo.
- **Dependências:** definir verificação de identidade, autorização e efeitos
  sobre sessões e fatores MFA; manter as exigências AAL2 existentes.

### FUT-P3-05 — Funcionalidades futuras em avaliação

- **Descrição:** timer automático e pausa/retomada; etiquetas; anexos;
  notificações; integrações com calendário e n8n; dashboard avançado; histórico
  persistente de alterações; promoção explícita de Demanda filha a raiz.
- **Prioridade:** P3 — avaliação, sem compromisso de entrega.
- **Estado:** Em avaliação; documentadas como fora da V1 ou futuras.
- **Dependências:** decisão individual de escopo antes de definir modelo,
  regras e critérios de aceite.

## Infraestrutura e débitos técnicos

### INF-01 — Domínio e hospedagem de produção

- **Descrição:** definir domínio próprio e hospedar Flutter Web e Serverpod.
- **Prioridade:** Pré-produção.
- **Estado:** Concluído — Flutter Web na Cloudflare Pages em
  `https://temdas.com.br`, backend Serverpod no Railway e Supabase PROD operacionais.
- **Dependências:** escolha do provedor, ambientes e estratégia de publicação.
- **Critérios de aceite:** app e backend acessíveis pelo domínio público com
  configuração correspondente de autenticação e callback.

### INF-02 — SMTP próprio

- **Descrição:** configurar SMTP próprio para as mensagens de autenticação.
- **Prioridade:** Pré-produção.
- **Estado:** Concluído — SMTP Resend configurado; entrega de convites e
  recuperação confirmada na homologação PROD.
- **Dependências:** domínio e serviço SMTP escolhidos; configuração no Supabase
  Auth.
- **Critérios de aceite:** mensagens de convite e recuperação são entregues
  usando a configuração SMTP aprovada.

### INF-03 — TLS PostgreSQL com `verify-full`

- **Descrição:** confirmar e exigir validação completa de certificado e nome do
  host na conexão PostgreSQL antes de produção.
- **Prioridade:** Bloqueador de produção.
- **Estado:** Parcial — IPv6/TLS de produção comprovados; `verify-full`
  comprovado nos clientes de backup e aplicação controlada de migration.
  A validação negativa de certificado/hostname pelo cliente Serverpod não foi
  repetida nem declarada homologada neste encerramento.
- **Dependências:** certificado confiável, hostname correto e configuração do
  cliente PostgreSQL.
- **Critérios de aceite:** conexão de produção valida cadeia do certificado e
  hostname (`verify-full`); conexão inválida falha fechada.

### INF-04 — Secrets seguros e persistentes

- **Descrição:** definir armazenamento e injeção seguros e persistentes de
  secrets necessários a Serverpod, Supabase, banco e serviços de e-mail.
- **Prioridade:** Pré-produção.
- **Estado:** Concluído na implantação atual — credenciais injetadas no backend,
  configuração privada de backup fora do Git e chave de recuperação preservadas.
  Este estado não declara rotação de todas as credenciais; revisões de segurança
  permanecem pontuais e não foram reabertas neste encerramento.
- **Dependências:** provedor de hospedagem e mecanismo de secrets escolhidos.
- **Critérios de aceite:** secrets não são versionados nem expostos em logs;
  permanecem disponíveis após reinício e rotação conforme a configuração do
  ambiente.

### INF-05 — Fallback SPA para `/auth/callback`

- **Descrição:** configurar no host ou proxy o fallback para entregar o app
  Flutter em `/auth/callback`, preservando query e fragmento do fluxo.
- **Prioridade:** Pré-produção.
- **Estado:** Concluído — fallback SPA publicado para `/auth/callback` e
  `/auth/confirm`, com roteamento, sanitização e confirmação explícita validados.
  Procedimentos em `auth-callback-flutter.md` e `auth-confirmation.md`.
- **Dependências:** INF-01 e URLs de redirect aprovadas no Supabase Auth.
- **Critérios de aceite:** links diretos de convite e recuperação abrem o app
  no callback público configurado.

### INF-06 — Preservação dos objetos customizados de Sprint

- **Descrição:** revisar `definition.sql` e os objetos customizados de Sprint
  em instalações novas e ao preparar cada migração futura.
- **Prioridade:** Recorrente — migrações e releases.
- **Estado:** Correção PROD concluída em 29/10/2026; verificação recorrente a cada
  nova migration. `sprint-integrity` aplicada, objetos/histórico/dados conferidos
  e restaurados a partir de backup posterior. Evidências em
  `schema-sprints-serverpod.md` e `migrations-prod.md`.
- **Dependências:** qualquer alteração de schema de Sprint ou geração de
  `definition.sql`.
- **Critérios de aceite:** preservar os dois objetos customizados atuais:
  índice de uma Sprint ativa por proprietário e exclusion constraint de períodos.
  Os três objetos legados do proprietário nulo foram retirados em
  `ownership-required` e não devem ser recriados. Definição completa e target
  de runtime permanecem coerentes.

### INF-07 — Prova de autenticação real nos ambientes

- **Descrição:** manter a validação E2E local manual já realizada e validar a
  integração publicada com Supabase, incluindo sessão, AAL2,
  `auth.provisionar()` e `auth.me()`.
- **Prioridade:** Pré-produção.
- **Estado:** Concluído — login, recovery e convites com MFA homologados em PROD,
  conforme confirmação do responsável na sessão de encerramento. A homologação
  manual anterior não foi repetida nem substituída por mocks nesta tarefa.
- **Dependências:** INF-04, configuração de Supabase e usuários/fatores de
  teste controlados.
- **Critérios de aceite:** provisionamento autorizado e consulta de perfil
  funcionam com AAL2; falhas de configuração não concedem acesso.

### INF-08 — Rate limit distribuído para convites

- **Descrição:** substituir ou complementar o limite em memória do fluxo de
  convites antes de operar com múltiplas instâncias ou ampliar sua exposição.
- **Prioridade:** Antes de escala horizontal ou exposição ampliada.
- **Estado:** Pendente condicional, registrado em `convites-admin.md`.
- **Dependências:** decisão de operar múltiplas instâncias e mecanismo
  compartilhado de rate limit.
- **Critérios de aceite:** limites são consistentes entre instâncias e não
  dependem da memória de um único processo.

## Referências de decisão

- `arquitetura.md`: arquitetura, limites de entidades e relação entre
  Demandas e Sprints.
- `escopo_temdas_v1_atualizado.md`: funcionalidades V1, critérios de
  validação e itens fora de escopo.
- `transicoes-status.md`: regras de status e cascatas.
- `autenticacao-supabase.md`, `auth-callback-flutter.md` e `convites-admin.md`:
  autenticação, AAL2, callbacks, convites e operação.
- `schema-sprints-serverpod.md`: migração e objetos SQL customizados de Sprint.
- `TEMDAS_HANDOFF_CODEX.md` e `prova-mfa-totp.md` são registros históricos;
  decisões antigas devem ser conferidas com a arquitetura, escopo e código
  atuais antes de virar trabalho pendente.


## Adições aprovadas em 2026-10-27 — UX e pós-produção

Esta seção foi incluída de forma aditiva em 27/10. No encerramento de 29/10, os
estados operacionais INF/PROD foram atualizados com as entregas comprovadas,
preservando o escopo e a prioridade dos itens de produto. Nenhuma tarefa pendente
desta seção autoriza implementação automática.

### UX-P1-07 — Corrigir exibição e ocultação de senha no login

- **Descrição:** corrigir o botão de mostrar/ocultar senha no campo de login,
  atualmente sem funcionamento adequado.
- **Prioridade:** P1 — correção de UX existente.
- **Estado:** Concluído e homologado em PROD (Pacote 1).
- **Dependências:** preservar a autenticação, segurança e acessibilidade;
  conferir componentes compartilhados antes de corrigir outras telas.
- **Critérios de aceite:** o botão alterna entre senha visível e oculta sem
  limpar ou modificar o valor digitado; funciona no Flutter Web e não
  interfere no envio do formulário.

### UX-CONT-01 — Responsividade real em smartphones e tablets

- **Descrição:** adaptar navegação, Demandas, Sprints, cards, formulários,
  modais e ações para smartphones e tablets, com layouts e interações
  apropriados a toque; não apenas reduzir fontes.
- **Prioridade:** Evolução contínua de UX/UI.
- **Estado:** Fechamento frontend publicado e homologado no Pacote 6; navegação mobile complementada em 30/10/2026 (`c8d4cfd`). Testes responsivos automatizados aprovados; cobertura de dispositivos reais permanece acompanhamento contínuo.
- **Dependências:** definir breakpoints e comportamentos por tela após
  avaliação; preservar a experiência desktop.
- **Critérios de aceite:** funções principais permanecem utilizáveis em
  celular e tablet, sem cortes, sobreposições ou rolagem horizontal
  desnecessária; botões e gestos são adequados ao toque.

### UX-CONT-02 — Densidade efetiva do modo compacto

- **Descrição:** evoluir o modo compacto, que hoje reduz principalmente o
  tamanho da fonte, ajustando altura dos cards, espaçamentos, padding,
  margens, disposição e hierarquia das informações.
- **Prioridade:** Evolução contínua de UX/UI.
- **Estado:** Concluído, publicado e homologado em PROD no Pacote 5; refinado no redesign responsivo de 30/10/2026 (`c36e12a`).
- **Dependências:** manter os estados, ações e a legibilidade do modo normal;
  definir quais informações podem ser condensadas ou ocultadas.
- **Critérios de aceite:** mais Demandas cabem na área visível sem perda de
  ações essenciais, leitura ou consistência de componentes.

### UX-CONT-03 — Controle manual de tema claro/escuro

- **Descrição:** oferecer um botão acessível para alternar manualmente entre
  os temas claro e escuro já existentes no TEMDAS.
- **Prioridade:** Evolução contínua de UX/UI.
- **Estado:** Concluído e homologado em PROD no Pacote 5, com botão por ícone e preferência preservada; atualizado visualmente no redesign de 30/10/2026 (`c36e12a`).
- **Dependências:** reaproveitar o sistema visual atual e decidir o escopo
  de persistência da preferência.
- **Critérios de aceite:** o controle altera o tema das telas principais,
  sem inconsistências visuais, e a escolha permanece após recarregar a
  aplicação.

### UX-CONT-04 — Descrição no lançamento de Log Time

- **Descrição:** permitir informar uma descrição opcional em cada lançamento de
  Log Time, registrando de forma curta o que foi realizado naquele apontamento.
- **Prioridade:** Evolução contínua de UX/UI.
- **Estado:** Concluído e homologado em PROD no Pacote 4, com observação opcional no registro e edição isolada de texto.
- **Dependências:** definir limite e apresentação do texto sem prejudicar a
  leitura da agenda e dos detalhes da Demanda.
- **Critérios de aceite:** ao criar ou editar um lançamento, o usuário pode
  registrar uma descrição; a descrição fica associada ao apontamento correto e
  pode ser consultada posteriormente de forma clara.

### LOG-P2-01 — Pré-preencher observação ao editar Log Time

- **Descrição:** ao editar um lançamento de horas existente na agenda de Log
  Time, carregar no campo **Observação (opcional)** o texto já salvo para
  aquele registro; quando não houver observação, mostrar o campo vazio.
- **Prioridade:** P2 — correção de UX.
- **Estado:** Implementado, publicado e homologado funcionalmente em PROD
  pelo responsável em 03/11/2026 (pacote de refinamento UX de novembro).
- **Dependências:** observação opcional de RegistroTempo já entregue no Pacote
  4; preservar associação com o registro, data, horas e regras de edição.
- **Critérios de aceite:** a observação existente aparece integralmente ao
  abrir a edição e permanece vinculada ao registro correto ao salvar;
  lançamentos sem texto exibem campo em branco, sem texto artificial.

### LOG-P2-02 — Lançamento direto de tempo com busca e criação de Demanda

- **Descrição:** remover a etapa intermediária do popup **Selecionar demanda**.
  Ao clicar em **Lançar tempo** ou em uma posição do calendário, abrir
  diretamente o formulário **Lançar tempo**. O campo **Demanda** deve ser
  editável/pesquisável por ID ou título, com opções elegíveis selecionáveis,
  e um botão **+** ao lado para cadastrar uma Demanda sem sair do fluxo.
- **Prioridade:** P2 — melhoria de produtividade.
- **Estado:** Implementado, publicado e homologado funcionalmente em PROD
  pelo responsável em 03/11/2026 (pacote de refinamento UX de novembro).
- **Criação rápida:** o botão **+** deve abrir o **mesmo formulário completo**
  de criação de Demanda da tela de Demandas, preferencialmente extraído como
  componente compartilhado, sem duplicação de regras. Após criação bem-sucedida,
  a nova Demanda deve ficar **automaticamente selecionada** no lançamento;
  a criação não registra tempo automaticamente. Se o cadastro for cancelado
  ou falhar, manter o lançamento aberto com os dados já digitados.
- **Preservação do formulário:** manter data, horários e observação preenchidos
  ao abrir/fechar o cadastro; preservar a data/hora pré-selecionadas pelo
  clique no calendário; exigir Demanda válida antes de salvar o lançamento.
  O diálogo de lançamento deve poder abrir mesmo com a lista de Demandas
  vazia, permitindo criar a primeira Demanda.
- **Dependências:** reutilizar endpoints e validações atuais de criação de
  Demanda e registro de tempo, preservando autorização, hierarquia,
  formulário de edição de Log Time e demais entradas de lançamento.
  Na edição de lançamento existente, preservar o vínculo atual, sem
  introduzir troca de Demanda por este item. Manter LOG-P2-01 separado.
- **Critérios de aceite:** apenas um popup de lançamento no fluxo normal;
  busca por ID/título ignorando maiúsculas e acentos, com teclado/mouse/toque;
  botão **+** chama cadastro compartilhado; seleção automática da Demanda
  criada; campos de data/hora/observação preservados em sucesso, erro e
  cancelamento do cadastro; estados sem Demandas/sem resultados claros;
  validação e salvamento sem regressão.
- **Evolução futura:** prever espaço para filtro por status/projeto caso o
  volume de Demandas justifique. **Não implementar filtros agora.**

### Pacote 4 — Painel lateral de Demandas

- **Estado:** Concluído, publicado e homologado em PROD (29/10/2026). Migration
  do Pacote 4 e correção dos objetos SQL customizados aplicadas com backup
  verificado e preservação de dados; deploy Railway → Cloudflare validado.
  Implementação: [pacote4-painel-demandas.md](pacote4-painel-demandas.md).
  Ensaios complementares: [pacote4-validacao-complementar.md](pacote4-validacao-complementar.md).
  Publicação: [pacote4-publicacao.md](pacote4-publicacao.md).
  A largura de 50% corresponde à versão entregue e será refinada no UX-P5-04.
- **Interface:** painel à direita com aproximadamente metade da largura no
  desktop e tela cheia no celular; cabeçalho fixo, rolagem independente e abas
  Visão geral, Anotações e Horas. Corpo do card abre o painel; expansão continua
  independente. Preservar detalhes por URL/nova aba, ações existentes, Sprint,
  hierarquia, tempos, temas e responsividade.
- **Anotações:** entidade `AnotacaoDemanda` com Demanda, autor, conteúdo,
  criação, última edição e exclusão lógica; ordem mais recente primeiro,
  edição/exclusão apenas pelo autor com validação no backend. Permitir anotações
  em Demandas concluídas/canceladas; históricos de mãe e filhas separados.
- **Horas:** exibir registros e total; nesta aba permitir somente edição isolada
  da observação opcional, inclusive em Demandas concluídas/canceladas. Manter
  correções de horários e exclusões exclusivamente no Log Time e acrescentar
  observação aos formulários existentes, sem alterar regras temporais.
- **Dados:** tornar `Demanda.descricao` oficial. Migrar `observacoes` para a
  descrição vazia ou acrescentar integralmente sob “Observações anteriores”
  quando ambas existirem; não gerar anotações artificiais. Descontinuar o campo
  antigo somente após validar a preservação dos dados. Preparar migrations
  Serverpod para anotações e observação opcional em `RegistroTempo`.
- **Decisões aprovadas e implementadas:** acesso apenas ao proprietário via
  `UsuarioScope`; compartilhamento, organizações, equipes e permissões
  colaborativas ficam para evolução futura. Uniões de Log Time concatenam
  textos integrais com intervalos de origem, ordem determinística e deduplicação,
  preservados transacionalmente. Metadados privados impedem duplicação em
  uniões consecutivas; observações vazias não produzem cabeçalhos artificiais.
- **Validação e aplicação:** testes de permissões/AAL2, persistência, migração,
  observações, concorrência, fusos e interações do painel aprovados; ensaios
  de migration no clone e verificação pós-publicação concluídos. Homologação
  manual em PROD confirmada. Evoluções visuais posteriores ficam no Pacote 5.

### UX-CONT-05 — Inclusão de Log Time diretamente pela agenda

- **Descrição:** facilitar a criação de apontamentos a partir da própria agenda.
  Ao passar o mouse sobre um horário disponível, exibir indicação visual
  discreta, como ícone de `+` ou texto de ação, permitindo iniciar o cadastro
  de Log Time naquele horário.
- **Prioridade:** Evolução contínua de UX/UI.
- **Estado:** Concluído e homologado em PROD (Pacote 3).
- **Dependências:** preservar navegação, rolagem e interação com lançamentos já
  existentes; definir comportamento equivalente para dispositivos de toque.
- **Critérios de aceite:** em desktop, o horário oferece uma ação contextual
  clara no hover; ao acioná-la, o formulário de Log Time é aberto com data e
  horário correspondentes pré-preenchidos; a interação não interfere nos cards
  existentes.

### UX-CONT-06 — Melhor aproveitamento da tela pela agenda de Log Time

- **Descrição:** ampliar a área útil destinada ao calendário/agenda de Log Time,
  reduzindo, reorganizando ou tornando mais compactas informações secundárias
  para priorizar a visualização temporal.
- **Prioridade:** Evolução contínua de UX/UI.
- **Estado:** Concluído e homologado em PROD (Pacote 3).
- **Dependências:** preservar as informações necessárias ao uso diário e a
  responsividade; avaliar separadamente desktop, tablet e celular.
- **Critérios de aceite:** a agenda ocupa uma parcela maior e mais útil da tela,
  com melhor leitura dos horários e lançamentos, sem remover informações
  essenciais nem gerar sobreposição ou rolagem desnecessária.

### UX-CONT-07 — Bordas sutis nos cards de Demandas e Log Time

- **Descrição:** adicionar bordas discretas aos cards de Demandas e aos cards de
  Log Time para reforçar a separação visual entre itens, mantendo o design
  system e evitando aumento de ruído visual.
- **Prioridade:** Evolução contínua de UX/UI.
- **Estado:** Concluído e homologado em PROD (Pacotes 1–3).
- **Dependências:** reutilizar tokens, `ColorScheme` e temas existentes; validar
  contraste nos temas claro e escuro e nas densidades normal e compacta.
- **Critérios de aceite:** cards adjacentes são distinguíveis com mais clareza
  sem depender de cores hardcoded; as bordas permanecem sutis, consistentes nos
  temas claro/escuro e coerentes entre Demandas e Log Time.

### UX-FUT-06 — Página inicial, login lateral, privacidade e versão

- **Descrição:** ao final das melhorias de UX previstas, substituir a
  experiência de entrada atual por uma página inicial real, com apresentação
  e boas-vindas ao TEMDAS na área central e formulário de login lateral.
  Incluir link público para uma página de **Aviso de Privacidade**, acessível
  sem autenticação e também a usuários autenticados. O aviso deve explicar
  o tratamento dos dados, as finalidades, o armazenamento no navegador
  (incluindo sessão e preferências), serviços envolvidos e os direitos dos
  titulares, com conteúdo conferido antes da publicação. Exibir
  discretamente a **versão do sistema** no rodapé da página inicial e no
  menu do aplicativo, com número de versão e SHA curto do commit do build.
- **Prioridade:** P3 — longo prazo, após as demais evoluções de UX.
- **Estado:** **Home page pública concluída e aceita pelo responsável em 30/10/2026** (commit `ebac0323`): apresentação em cinco seções, prévias locais, navegação responsiva, entrada para o login existente, tema e integração ao AuthGate. **Login lateral concluído e homologado em PROD** (UX-AUTH-03, `23f3ec4`). **Ainda pendentes do escopo original:** Aviso de Privacidade público e versão/SHA do build. Não declarar UX-FUT-06 integralmente encerrado até esses itens serem entregues.
- **Dependências:** evolução responsiva, temas, identificação automática
  da versão a partir de `app/pubspec.yaml` e SHA incorporado na compilação
  do Flutter Web, sem versão duplicada manualmente nem consulta ao servidor;
  preservação do fluxo AuthGate,
  senha, recuperação, convite, callback e MFA; verificar os tratamentos
  efetivos e fornecedores antes de redigir/publicar o aviso. Não implementar
  banner de consentimento de cookies sem necessidade comprovada para
  tecnologias opcionais; reavaliar se forem introduzidos rastreamento,
  publicidade ou outras finalidades que o exijam.
- **Critérios de aceite:** visitante não autenticado vê a apresentação e o
  login lateral em desktop; o layout se reorganiza em telas menores; o usuário
  autenticado segue normalmente para o app; os fluxos de autenticação
  existentes continuam funcionando; o Aviso de Privacidade é acessível
  publicamente e pelo app, apresenta informações verificadas e compreensíveis
  sobre dados e armazenamento, sem exigir login; rodapés exibem versão
  e identificador do build efetivamente carregado, com fallback no desenvolvimento.



## Pacote 5 — Redesign visual e aproveitamento da área útil

**Estado:** Concluído, publicado e homologado em PROD pelo responsável antes
 do redesign complementar de 30/10/2026. Inclui os commits `b3e67ad` e
 `b071e4d`, com análise, testes afetados e build Web release aprovados.
 Detalhes em [pacote5-toolbar-demandas.md](pacote5-toolbar-demandas.md).
 O redesign posterior de Lista/Kanban e da navegação mobile está registrado
 separadamente abaixo. Nenhuma migration ou mudança de backend.

### UX-P5-01 — Barra superior compartilhada e contextual

- **Descrição:** evoluir o `PageScaffold` para uma toolbar comum às telas
  principais, usando o espaço horizontal entre o título da página e as ações
  à direita. O botão de alternância de tema claro/escuro por ícone permanece
  **fixo no canto superior direito em todas as páginas**. Os demais controles
  são contextuais: Demandas (busca, filtros, Kanban/Lista, criar); Sprint
  (ações e controles existentes); Log Time (navegação de datas, Dia/Semana e
  ações da agenda); Relatórios (período, filtros e exportação); Perfil (apenas
  ações aplicáveis). Evitar duplicar controles acima e abaixo da barra.
- **Estado:** Concluído, publicado e homologado em PROD no Pacote 5; visual aprimorado em 30/10/2026.
- **Critérios de aceite:** a região central da barra é flexível e preenche o
  espaço disponível, sem grande vazio entre título e busca; controles úteis
  ficam na barra superior no desktop; tema está sempre na mesma posição; em
  tablet/celular a toolbar se reorganiza sem truncar ações ou reduzir áreas
  de toque; não alterar a regra de negócio de nenhuma tela.
- **Dependências:** usar preferências de tema já existentes, preservando a
  opção Sistema em configuração secundária e sua persistência.

### UX-P5-02 — Kanban denso e opção Lista de Demandas

- **Descrição:** manter o Kanban como modo principal/padrão, com drag-and-drop
  e hierarquia atuais; renovar os cards compactos com menos altura, padding
  e ruído visual, preservando título, ID, prioridade, tempos e indicação de
  Sprint de forma hierarquizada. Adicionar uma visualização **Lista**, inspirada
  na densidade e na leitura do Pipeline iVertex, agrupada por status, com
  apresentação da hierarquia mãe/filha. Um seletor Kanban/Lista fica na
  toolbar superior da página; a opção escolhida persiste no navegador.
  Ambas as visualizações abrem o mesmo painel lateral do Pacote 4.
- **Estado:** Concluído, publicado e homologado em PROD no Pacote 5; visual aprimorado em 30/10/2026.
- **Critérios de aceite:** mais Demandas visíveis sem perder legibilidade
  nem ações essenciais; Kanban mantém drag-and-drop e expansão hierárquica;
  Lista oferece abertura dos detalhes e controle de status conforme as regras
  atuais, sem exigir drag-and-drop na primeira entrega; visualizações usam
  os mesmos dados, busca e filtros, sem duplicar lógica de negócio.
- **Dependências:** conclusão do painel lateral do Pacote 4; preservar temas,
  densidades, ownership e regras atuais de status e de Sprint.

### UX-P5-03 — Busca e filtros consolidados na toolbar

- **Descrição:** na página Demandas, campo de busca sempre visível e
  **expansível para ocupar a largura disponível**, seguido de botão único
  de filtros, seletor Kanban/Lista e ação Criar Demanda; botão de tema fixo
  no extremo direito. O botão de filtros agrupa Prioridade, Sprint e futuros
  critérios, mostra a quantidade de filtros ativos e oferece Limpar filtros.
  A busca considera ID/título sem diferenciar maiúsculas ou acentos e combina
  com os filtros, preservando o contexto mãe/filha nos resultados.
- **Estado:** Concluído, publicado e homologado em PROD no Pacote 5; visual aprimorado em 30/10/2026.
- **Critérios de aceite:** busca e filtros funcionam em ambas as visualizações;
  nenhum filtro isolado ocupa permanentemente espaço na toolbar; layout usa
  efetivamente a área horizontal livre da barra superior; responsividade e
  acessibilidade preservadas.

### UX-P5-04 — Painel lateral estreito, condensado e redimensionável

- **Estado:** Concluído, publicado e homologado em PROD (`b071e4d`); funcionalidades do Pacote 4 preservadas, com 420 px, arraste, ampliação e persistência local.
- **Descrição:** substituir a largura inicial de 50% do desktop por **420 px**
  como padrão, respeitando a largura efetivamente disponível. Permitir
  redimensionamento horizontal arrastando a borda esquerda; oferecer ícone
  `move-horizontal` no cabeçalho para alternar entre tamanho padrão e ampliado.
  Persistir a largura escolhida no navegador. Limitar ampliação a cerca de
  **70% da viewport** e evitar largura maior que a tela; no celular, painel
  permanece em tela cheia.
- **Visão geral:** condensar cartões, margens, paddings e informações repetidas.
  Agrupar título, prioridade e status; exibir descrição de maneira econômica;
  concentrar estimado/realizado/restante em um bloco enxuto; apresentar Sprint,
  metadados e ações em linhas compactas. Preservar informações e operações do
  Pacote 4, bem como Anotações e Horas.
- **Critérios de aceite:** painel inicia significativamente menor e deixa o
  Kanban/Lista visível ao fundo; largura ajusta-se pelo arraste e pelo ícone
  sem cortes, saltos ou perda de estado; tamanho persiste após recarga;
  Visão geral tem menos rolagem e nenhuma duplicação desnecessária; bom
  funcionamento em temas claro/escuro e em telas menores.
- **Escopo:** somente frontend Flutter, sem alteração de dados, endpoints,
  migrations ou regras de negócio.

**Sequenciamento:** Pacote 4 preservado em PROD. UX-P5-04 concluído sobre
a implementação existente do Pacote 5; gates de validação aprovados e roadmap
atualizado da main integrado. Publicação de todo o Pacote 5 autorizada pelo
responsável, exclusivamente frontend, com confirmação do workflow e HTTPS.

## Pacote 6 — Modernização de Sprints e fechamento responsivo

- **Estado:** **Concluído, publicado e homologado em PROD pelo responsável** em
  29/10/2026 (commit `764a845`). Análise, testes direcionados, build Web release
  e workflow Cloudflare aprovados. Evidências em
  [pacote6-sprints-responsividade.md](pacote6-sprints-responsividade.md).
  Avaliações adicionais em diferentes aparelhos permanecem contínuas.
- **Objetivo 1 — Sprints (P1):** modernizar a interface de Sprints e concluir os
  itens UX-P1-01 (Sprint ativa e histórico), UX-P1-02 (navegação e vínculos com
  Demandas), UX-P1-04 (painel lateral igual ao de Demandas, com largura ajustável
  e ações contextuais) e UX-P1-05 (feedback de carregamento e erros). Preservar
  as regras de negócio, as transições e os vínculos atuais.
- **Objetivo 2 — Responsividade global (UX-CONT-01):** revisar e corrigir a
  experiência em smartphones e tablets de **todas as telas relevantes**, não
  somente Sprints: Demandas, painel lateral, Log Time, Relatórios, Perfil,
  navegação, login/MFA, formulários e diálogos. Reaproveitar os componentes e
  padrões visuais dos Pacotes 4/5. Evitar cortes, sobreposição, rolagem
  horizontal indevida e controles inacessíveis ao toque.
- **Validação:** conferir fluxos principais em larguras de celular, tablet
  e desktop, temas claro/escuro e interações por toque e teclado; alinhar
  evidências com UX-P1-06 (validação da V1). Preservar as funcionalidades
  existentes, sem antecipar recursos de equipes ou organizações.
- **Sequenciamento:** após o Pacote 5. Antes de implementar, confirmar apenas
  eventuais decisões novas de UX/negócio; usar um prompt Codex objetivo para
  implementar, testar o necessário e, se aprovado, commitar na main e publicar,
  respeitando autorização específica para migrations ou operações sensíveis.

## Redesign complementar de Demandas e navegação mobile — 30/10/2026

- **Estado:** Implementado e publicado em PROD, conforme entregas do Codex;
  conferência HTTP 200 e artefatos Cloudflare Pages confirmados. Homologação
  visual comparativa com mockups e em dispositivos reais ainda não registrada.
- **Commit `c36e12a`:** redesign responsivo das visualizações Lista e Kanban
  de Demandas (desktop/tablet/celular), evolução de tokens, tipografia e
  componentes visuais reutilizáveis; manutenção de ações e regras existentes.
  `flutter analyze`, testes afetados e um build Web release aprovados.
- **Commit `c8d4cfd`:** navegação inferior no mobile nas telas Demandas,
  Sprints, Log Time, Relatórios e Perfil, com destaque para a seção atual;
  análise, testes afetados e build Web release aprovados.
- **Escopo:** frontend; sem alterações de modelo, backend ou migrations.
- **Referência:** [redesign-demandas.md](redesign-demandas.md).

## Pós-produção — Estabilização do MVP

Esta seção reúne as ações operacionais acordadas após a primeira publicação.
Complementa os itens INF existentes. Estados atualizados no encerramento de
29/10/2026, com base nas evidências dos runbooks e na homologação manual de
autenticação confirmada pelo responsável. O objetivo é manter o MVP confiável e
dentro do orçamento inicial; nenhum item pendente foi iniciado neste encerramento.

### PROD-01 — Backup externo automatizado e teste de restauração

- **Prioridade:** P0 — proteção dos dados.
- **Estado:** Concluído no escopo operacional WSL + F: — coleta automática,
  criptografia, cópia SHA-256 e restauração isolada comprovadas. Restaurador
  instalado sincronizado em 29/10; backup posterior à `sprint-integrity`
  restaurado diretamente do F:, com 54 tabelas, dados/schema e os três objetos
  esperados (`btree_gist` e duas proteções de Sprint) conferidos.
- **Descrição:** automatizar cópias de segurança do PostgreSQL Supabase PROD,
  definir retenção e destino seguro, e demonstrar restauração em ambiente
  isolado, sem tocar no DEV nem sobrescrever PROD.
- **Critérios de aceite:** execução recorrente verificada, cópias protegidas
  e procedimento de restauração documentado e testado.

- **Evidências e limites:** [Backup e restauração PROD](backup-restauracao-prod.md).
- **Pendências registradas, não implementadas:** cópia offsite e proteção/cópia
  de recuperação da chave fora deste computador. WSL e F: no mesmo PC não
  protegem contra perda de todo o equipamento nem contra comprometimento da
  conta. Configuração privada, chave e agendamento foram preservados.

### PROD-02 — Deploy seguro e controle de migrations

- **Prioridade:** P0 — proteção dos dados.
- **Estado:** Concluído e homologado operacionalmente — ensaio PG17.11 isolado,
  gates de backup/F:, análise SQL, integridade e aprovação humana separados.
  `sprint-integrity` aplicada em PROD uma única vez, com COMMIT e verificações
  posteriores aprovados. Migrations automáticas permanecem desabilitadas.
- **Descrição:** validar migrations versionadas e compatibilidade antes de
  cada release, realizar backup antes de mudanças estruturais e impedir deploy
  em caso de falha; nenhuma limpeza ou recriação automática do banco PROD.
- **Dependências:** preservar os dois objetos atuais de Sprint conforme INF-06;
  seguir recuperação documentada e obter aprovação específica para **toda**
  migration real. `production_authorized=false` permanece no validador;
  sucesso de ensaio não autoriza aplicação.
- **Critérios de aceite:** testes e verificações bloqueiam publicação
  inconsistente; dados existentes são preservados; recuperação é testável.
- **Evidências:** [Runbook e aplicação PROD-02](migrations-prod.md).

### PROD-03 — Domínio principal e redirects definitivos

- **Prioridade:** P1 — conclusão da publicação.
- **Estado:** Concluído — domínio raiz publicado, Site URL e callbacks de
  `temdas.com.br` alinhados; endereço `temdas-web.pages.dev` preservado.
- **Descrição:** associar o Flutter Web a https://temdas.com.br, sem o prefixo
  app., e alinhar Site URL, redirects e callback do Supabase Auth PROD.
- **Dependências:** INF-01 e INF-05; manter o endereço pages.dev enquanto
  necessário para migração e testes.
- **Critérios de aceite:** aplicação funciona no domínio principal e links
  diretos de autenticação retornam corretamente à aplicação.

### PROD-04 — Validação E2E de recuperação e convites em produção

- **Prioridade:** P1 — conclusão da autenticação publicada.
- **Estado:** Concluído — recovery, convites e login com MFA homologados em PROD,
  conforme confirmação do responsável. Inclui confirmação explícita do link,
  correção de hash routing, elevação TOTP antes de atualizar senha quando exigida
  e remoção da instrumentação temporária. Não foram enviados novos links ou
  convites para repetir a homologação neste encerramento.
- **Descrição:** testar entrega real pelo Resend, recuperação de senha,
  callback, convite administrativo, aceite, provisionamento e MFA com
  contas controladas, preservando a regra de que somente o administrador
  autorizado envia convites.
- **Dependências:** INF-02, INF-07 e PROD-03.
- **Critérios de aceite:** fluxos completos funcionam, erros são tratados e
  convidados permanecem sem privilégios de administrador.

### PROD-05 — Monitoramento, custos e segurança operacional

- **Prioridade:** P2 — operação contínua.
- **Estado:** Aprovado / pendente de definição operacional.
- **Descrição:** acompanhar disponibilidade, logs, falhas e custo Railway
  dentro do orçamento planejado; revisar CORS e exposição pública; comprovar
  requisitos já previstos de TLS PostgreSQL verify-full e secrets seguros
  (INF-03 e INF-04), sem duplicar suas definições.
- **Critérios de aceite:** saúde e gastos são verificáveis; configurações de
  segurança e eventuais exceções ficam documentadas.

### PROD-06 — Documentação e manutenção da publicação

- **Prioridade:** P3 — manutenção.
- **Estado:** Parcial — estado de autenticação, hospedagem, backups e migrations
  atualizado neste encerramento. Diretórios locais `.wrangler/` e `supabase/`,
  eventual domínio `api.temdas.com.br` e aviso não bloqueante de Insights seguem
  somente registrados, sem implementação ou limpeza automática.
- **Descrição:** documentar o estado real de Cloudflare Pages, Railway,
  Supabase PROD e Resend; revisar os diretórios locais não rastreados
  .wrangler/ e supabase/ antes de versionar ou excluir; avaliar o subdomínio
  api.temdas.com.br e o aviso não bloqueante de Serverpod Insights.
- **Critérios de aceite:** documentação reproduz a implantação real sem
  divulgar credenciais, e pendências não bloqueantes têm decisão registrada.

## Última etapa do roadmap — Refinamento final do MFA/TOTP

### AUTH-P2-01 — Simplificar o fluxo MFA/TOTP

- **Descrição:** remover da interface a ação explícita “Iniciar challenge” e
  simplificar a apresentação do fluxo TOTP.
- **Prioridade:** Última etapa do roadmap, por decisão do responsável (manter identificador AUTH-P2-01).
- **Estado:** Aprovado, mas adiado para o encerramento do roadmap; não incluir nos próximos pacotes. A interface atual permanece preservada.
- **Dependências:** preservar a elevação de sessão para AAL2 e os fluxos de
  enrollment e verificação suportados pelo Supabase.
- **Critérios de aceite:** o usuário consegue completar MFA sem a ação
  “Iniciar challenge”; as rotas funcionais continuam exigindo AAL2.
