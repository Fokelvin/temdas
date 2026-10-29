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
  organizar o histórico. A apresentação do histórico (lista expansível, painel
  lateral ou alternativa) ainda precisa ser escolhida.
- **Prioridade:** P1.
- **Estado:** Aprovado / pendente.
- **Dependências:** decisão da apresentação do histórico; preservar o ciclo de
  vida e as transições de Sprint existentes.
- **Critérios de aceite:** a Sprint ativa é identificável; status distintos
  podem ser reconhecidos visualmente; o histórico fica organizado e acessível.

### UX-P1-02 — Integração visual entre Demandas e Sprints

- **Descrição:** completar a navegação e as ações de associação entre as telas
  de Demandas e Sprints, incluindo acesso à Sprint em nova aba ou alternativa
  de navegação a decidir, e resumo contextual. O resumo de Sprint, painel de
  Demandas vinculadas e abertura dos detalhes já existem.
- **Prioridade:** P1.
- **Estado:** Parcial.
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
- **Estado:** Parcial — resumos e ações de Sprint já existem; painel lateral
  padronizado conforme Demandas ainda não implementado.
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
- **Estado:** Parcial; já há indicadores na carga inicial, detalhes e lista de
  Demandas vinculadas.
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

### AUTH-P2-01 — Simplificar o fluxo MFA/TOTP

- **Descrição:** remover da interface a ação explícita “Iniciar challenge” e
  simplificar a apresentação do fluxo TOTP.
- **Prioridade:** P2.
- **Estado:** Aprovado / pendente; o fluxo TOTP existe e a ação ainda aparece
  na interface atual.
- **Dependências:** preservar a elevação de sessão para AAL2 e os fluxos de
  enrollment e verificação suportados pelo Supabase.
- **Critérios de aceite:** o usuário consegue completar MFA sem a ação
  “Iniciar challenge”; as rotas funcionais continuam exigindo AAL2.

### AUTH-P2-02 — Mensagens e estados de autenticação

- **Descrição:** uniformizar mensagens compreensíveis e estados visuais de
  autenticação, recuperação de senha e falhas recuperáveis, sem expor dados de
  conta ou detalhes sensíveis do provedor.
- **Prioridade:** P2.
- **Estado:** Parcial; há tratamento específico de recuperação e callback,
  restando consolidar os demais estados da interface.
- **Dependências:** contratos de erro documentados em `auth-callback-flutter.md`
  e nas páginas de autenticação.
- **Critérios de aceite:** mensagens preservam proteção contra enumeração;
  falhas de rede/servidor permitem nova tentativa; AAL2 permanece obrigatório.

### UI-P2-03 — Seleção global de texto no Flutter Web

- **Descrição:** habilitar seleção de texto global com `SelectionArea`, sem
  prejudicar menus, botões, campos ou gestos de interação.
- **Prioridade:** P2.
- **Estado:** Parcial; há seleção em áreas como cards e detalhes, mas não uma
  área global do app.
- **Dependências:** validar interações nas telas e componentes interativos.
- **Critérios de aceite:** textos informativos podem ser selecionados nas
  telas principais e ações e campos continuam operáveis.

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
- **Estado:** Parcial / contínuo — melhorias responsivas entregues nos Pacotes 1–4; refinamentos globais do Pacote 5 implementados em branch, aguardando homologação/publicação.
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
- **Estado:** Implementado no Pacote 5 (branch `feat/pacote-5-toolbar-demandas`, commit `b3e67ad`); pendente de homologação visual e publicação.
- **Dependências:** manter os estados, ações e a legibilidade do modo normal;
  definir quais informações podem ser condensadas ou ocultadas.
- **Critérios de aceite:** mais Demandas cabem na área visível sem perda de
  ações essenciais, leitura ou consistência de componentes.

### UX-CONT-03 — Controle manual de tema claro/escuro

- **Descrição:** oferecer um botão acessível para alternar manualmente entre
  os temas claro e escuro já existentes no TEMDAS.
- **Prioridade:** Evolução contínua de UX/UI.
- **Estado:** Alternância e preferência de tema já disponíveis em PROD; botão por ícone fixo na toolbar implementado no Pacote 5, pendente de homologação/publicação.
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
- **Estado:** Aprovado / pendente de definição visual e do conteúdo de privacidade.
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

**Estado:** implementação completa e validada na branch
`feat/pacote-5-toolbar-demandas`, preservando `b3e67ad` e incluindo o refinamento
UX-P5-04 em `b071e4d`. Análise, 72 testes afetados e build Web release aprovados
no fechamento; validação principal anterior reutilizada. Publicação frontend
autorizada após esses gates, via workflow Cloudflare Pages; homologação visual
final em PROD permanece manual. Detalhes em
[pacote5-toolbar-demandas.md](pacote5-toolbar-demandas.md).
Nenhuma migration ou alteração de backend é exigida pelo Pacote 5.

### UX-P5-01 — Barra superior compartilhada e contextual

- **Descrição:** evoluir o `PageScaffold` para uma toolbar comum às telas
  principais, usando o espaço horizontal entre o título da página e as ações
  à direita. O botão de alternância de tema claro/escuro por ícone permanece
  **fixo no canto superior direito em todas as páginas**. Os demais controles
  são contextuais: Demandas (busca, filtros, Kanban/Lista, criar); Sprint
  (ações e controles existentes); Log Time (navegação de datas, Dia/Semana e
  ações da agenda); Relatórios (período, filtros e exportação); Perfil (apenas
  ações aplicáveis). Evitar duplicar controles acima e abaixo da barra.
- **Estado:** implementado e validado; pendente de homologação visual final em PROD.
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
- **Estado:** implementado e validado; pendente de homologação visual final em PROD.
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
- **Estado:** implementado e validado; pendente de homologação visual final em PROD.
- **Critérios de aceite:** busca e filtros funcionam em ambas as visualizações;
  nenhum filtro isolado ocupa permanentemente espaço na toolbar; layout usa
  efetivamente a área horizontal livre da barra superior; responsividade e
  acessibilidade preservadas.

### UX-P5-04 — Painel lateral estreito, condensado e redimensionável

- **Estado:** implementado e validado em `b071e4d`; funcionalidades do
  Pacote 4 preservadas, com 420 px, arraste, ampliação e persistência local.
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
