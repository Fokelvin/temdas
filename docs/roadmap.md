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
  convite de administrador documentados/implementados.
- Interface com sistema visual, temas claro/escuro e densidade de cards.

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

### UX-P1-03 — Ações no popup expandido de Demanda

- **Descrição:** disponibilizar no popup expandido as mesmas ações disponíveis
  no card de Demanda.
- **Prioridade:** P1.
- **Estado:** Aprovado / pendente.
- **Dependências:** manter as permissões e regras de status e exclusão do fluxo
  atual.
- **Critérios de aceite:** o popup oferece as ações do card compatíveis com a
  Demanda e seu estado, com os mesmos resultados e validações.

### UX-P1-04 — Ações contextuais nos popups de Sprint

- **Descrição:** ações contextuais em resumos e painéis de Sprint, respeitando
  as regras de negócio, incluindo “Iniciar Sprint” e “Adicionar Demanda”.
- **Prioridade:** P1.
- **Estado:** Parcial; o resumo e o painel permitem consultar Demandas e ações
  de vínculo são limitadas a Sprints planejadas ou ativas.
- **Dependências:** regras atuais do backend e do ciclo de vida da Sprint.
- **Critérios de aceite:** “Iniciar Sprint” e “Adicionar Demanda” são
  oferecidas apenas quando permitidas pelo status e pelas regras atuais;
  remoções seguem as regras de hierarquia e vínculo existentes.

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
- **Estado:** Aprovado / pendente.
- **Dependências:** escolha do provedor, ambientes e estratégia de publicação.
- **Critérios de aceite:** app e backend acessíveis pelo domínio público com
  configuração correspondente de autenticação e callback.

### INF-02 — SMTP próprio

- **Descrição:** configurar SMTP próprio para as mensagens de autenticação.
- **Prioridade:** Pré-produção.
- **Estado:** Aprovado / pendente de configuração e validação.
- **Dependências:** domínio e serviço SMTP escolhidos; configuração no Supabase
  Auth.
- **Critérios de aceite:** mensagens de convite e recuperação são entregues
  usando a configuração SMTP aprovada.

### INF-03 — TLS PostgreSQL com `verify-full`

- **Descrição:** confirmar e exigir validação completa de certificado e nome do
  host na conexão PostgreSQL antes de produção.
- **Prioridade:** Bloqueador de produção.
- **Estado:** Pendente de comprovação no ambiente de produção; requisitos de
  SSL já aparecem na configuração de ambientes.
- **Dependências:** certificado confiável, hostname correto e configuração do
  cliente PostgreSQL.
- **Critérios de aceite:** conexão de produção valida cadeia do certificado e
  hostname (`verify-full`); conexão inválida falha fechada.

### INF-04 — Secrets seguros e persistentes

- **Descrição:** definir armazenamento e injeção seguros e persistentes de
  secrets necessários a Serverpod, Supabase, banco e serviços de e-mail.
- **Prioridade:** Pré-produção.
- **Estado:** Pendente de validação operacional por ambiente.
- **Dependências:** provedor de hospedagem e mecanismo de secrets escolhidos.
- **Critérios de aceite:** secrets não são versionados nem expostos em logs;
  permanecem disponíveis após reinício e rotação conforme a configuração do
  ambiente.

### INF-05 — Fallback SPA para `/auth/callback`

- **Descrição:** configurar no host ou proxy o fallback para entregar o app
  Flutter em `/auth/callback`, preservando query e fragmento do fluxo.
- **Prioridade:** Pré-produção.
- **Estado:** Pendente de configuração da hospedagem; procedimento está em
  `auth-callback-flutter.md`.
- **Dependências:** INF-01 e URLs de redirect aprovadas no Supabase Auth.
- **Critérios de aceite:** links diretos de convite e recuperação abrem o app
  no callback público configurado.

### INF-06 — Preservação dos objetos customizados de Sprint

- **Descrição:** revisar `definition.sql` e os objetos customizados de Sprint
  em instalações novas e ao preparar cada migração futura.
- **Prioridade:** Recorrente — migrações e releases.
- **Estado:** Recorrente; os objetos e a migração aplicada estão documentados
  em `schema-sprints-serverpod.md`.
- **Dependências:** qualquer alteração de schema de Sprint ou geração de
  `definition.sql`.
- **Critérios de aceite:** os cinco objetos SQL customizados documentados são
  preservados onde necessários; os arquivos de definição gerados e o schema
  usado em runtime permanecem coerentes.

### INF-07 — Prova de autenticação real nos ambientes

- **Descrição:** manter a validação E2E local manual já realizada e validar a
  integração publicada com Supabase, incluindo sessão, AAL2,
  `auth.provisionar()` e `auth.me()`.
- **Prioridade:** Pré-produção.
- **Estado:** Parcial; E2E local validado manualmente, homologação em ambiente
  publicado pendente.
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
