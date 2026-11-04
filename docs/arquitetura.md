# TEMDAS — Arquitetura atual do MVP

**Atualização:** 03/11/2026. **Fonte:** código, migrations e documentação da branch `main` do repositório TEMDAS.

O TEMDAS é uma aplicação Web de gestão de Demandas, Sprints, registros de tempo e relatórios. Esta documentação descreve a arquitetura **implementada e publicada**, não apenas a arquitetura histórica da V1. A organização distribuída dos serviços também atende ao objetivo do projeto de aprendizado e evolução técnica.

Em caso de divergência, o código e as migrations versionadas prevalecem sobre descrições históricas. O [roadmap](roadmap.md) define estados de funcionalidades e pendências, enquanto os runbooks detalham operações específicas de produção.

## 1. Serviços e responsabilidades

| Camada | Tecnologia ou serviço | Função atual |
| --- | --- | --- |
| Interface | Flutter Web + Dart | Páginas, interações, estado visual e responsividade |
| Frontend público | Cloudflare Pages | Distribuir a aplicação Flutter Web por HTTPS em https://temdas.com.br |
| API e domínio | Serverpod 3.4.11 + Dart | Endpoints tipados, validações, autorização, transações e persistência |
| Hospedagem da API | Railway | Executar o backend Serverpod de produção |
| Banco de dados | Supabase PostgreSQL | Dados de negócio, relacionamentos, constraints e migrations |
| Identidade | Supabase Auth | E-mail/senha, JWT, sessão, recuperação de senha e MFA TOTP |
| E-mail | Resend, via SMTP do Supabase Auth | Entregar convites e mensagens de recuperação |
| Versionamento | Git + GitHub | Repositório, histórico, branches, PRs e documentação |
| CI/CD do frontend | GitHub Actions | Build Flutter Web e publicação na Cloudflare Pages |
| Proteção de dados PROD | Agendador Windows + WSL + PostgreSQL | Backup criptografado, cópia secundária local e ensaio de restauração |

**Delimitação:** o n8n, Google Calendar, timer automático, anexos e integrações futuras não participam do fluxo de produção. O PostgreSQL é fornecido pelo Supabase; o frontend não abre conexões diretas ao banco.

## 2. Fluxos de informação

```text
DESENVOLVIMENTO E PUBLICAÇÃO (FRONTEND)
VS Code / Flutter / Dart / Serverpod / Git
          |
          +-- git push --> GitHub (main)
                              |
                          GitHub Actions
                              |
                         build Flutter Web
                              |
                         Cloudflare Pages
                              |
                         temdas.com.br
                              |
                       navegador do usuário

FLUXO FUNCIONAL (EM EXECUÇÃO NO NAVEGADOR)
Flutter Web
  View/Page
      ↓
  ViewModel
      ↓
  Repository
      ↓
  Client Serverpod gerado
      |
      | HTTPS / RPC + Authorization: Bearer JWT
      v
Serverpod (Railway)
  Autenticação e autorização
      ↓
  Endpoints / serviços de domínio
      ↓
  PostgreSQL (Supabase)
      |
      +--> resposta tipada --> Repository --> ViewModel --> View

FLUXO DE IDENTIDADE (SEPARADO DOS DADOS DE NEGÓCIO)
Flutter Web <-- login / MFA / refresh --> Supabase Auth
     |
     +--> JWT Supabase --> Client Serverpod --> Railway
                                              |
                                              +--> verifica JWT via JWKS
                                              +--> valida Usuario e AAL2
                                              +--> aplica ownership

Serverpod --> API administrativa Supabase Auth (operações autorizadas)
Supabase Auth --> Resend SMTP --> e-mail de convite/recuperação
```

O Flutter é **hospedado** na Cloudflare Pages, mas **executado no navegador**. O SDK `supabase_flutter` fala com Supabase Auth apenas para identidade/sessão. Todo acesso aos dados funcionais passa pelo Serverpod, que concentra as regras de negócio. O Resend não recebe RPCs do TEMDAS; transporta e-mails de autenticação configurados no Supabase Auth.

O deploy do backend Railway é distinto do workflow de build/deploy do frontend. Um push no GitHub não significa, por si só, aplicar migrations no banco.

## 3. Frontend: organização e UX

O padrão para chamadas de domínio é:

```text
View / Page → ViewModel → Repository → Client Serverpod gerado → Endpoint
```

- **View / Page:** renderiza estados, ações, formulários, feedback, painéis e diálogos.
- **ViewModel:** coordena consultas/mutações, estado local e conversões necessárias à apresentação.
- **Repository:** encapsula requests e chamadas do client gerado; widgets não devem acessar endpoints diretamente.
- **Client Serverpod:** contrato tipado gerado a partir dos modelos/endpoints, sem edição manual.
- **Autenticação (fluxo independente):** `SupabaseSession` restaura/renova sessão e fornece o Bearer atual ao client; `AuthGate` protege rotas funcionais e exige MFA.

Arquivos-base: `app/lib/data/serverpod_client.dart`, `app/lib/data/supabase_session.dart`, `app/lib/app/auth_gate.dart` e `app/lib/app/app_routes.dart`.

### Telas implementadas

| Tela | Recursos atuais |
| --- | --- |
| Home pública | Apresentação do produto e entrada para login em painel lateral |
| Demandas | CRUD, hierarquia de demandas filhas, Kanban com drag-and-drop, Lista, prioridades, status, busca, filtros, densidade normal/compacta e vínculos com Sprints |
| Detalhes / painel de Demanda | Visão geral, Anotações e Horas, ações aplicáveis, histórico, tempo estimado/executado e rota própria |
| Sprints | Planejamento, ativação, conclusão, cancelamento, histórico, vínculos, indicadores, lista de Demandas e painel lateral |
| Log Time | Agenda diária/semanal, lançamentos manuais, edição/exclusão, observação opcional e busca/criação de Demanda no lançamento |
| Relatórios | Período e filtros, agregação de horas, estrutura hierárquica e exportação CSV / visualização imprimível |
| Meu Perfil | Informações e controles aplicáveis ao usuário autenticado |
| Login e MFA | E-mail/senha, enrollment e verificação TOTP, recuperação e confirmação de convite |

A agenda semanal do Log Time usa **domingo a sábado** após o refinamento publicado em 03/11/2026. O fluxo de lançamento abre o formulário diretamente, inclusive sem Demandas prévias, e permite cadastrar a Demanda pelo formulário compartilhado sem perder o rascunho de tempo.

A interface possui tema claro/escuro com preferência persistente (incluindo a opção de seguir o sistema), IBM Plex Sans, design tokens, cores semânticas, barra superior compartilhada, densidade compacta, painel lateral responsivo e navegação mobile. A visualização normal/compacta e a escolha Kanban/Lista são preferências de apresentação; não alteram dados ou regras de domínio.

Referências: [Pacote 4](historico/pacote4-painel-demandas.md), [Pacote 5](historico/pacote5-toolbar-demandas.md), [Pacote 6](historico/pacote6-sprints-responsividade.md) e [Redesign de Demandas](historico/redesign-demandas.md).

## 4. Autenticação, identidade e autorização

O Supabase Auth é a fonte de verdade para identidade, credenciais, MFA e sessões. O TEMDAS não guarda senhas e não emite um JWT paralelo.

```text
Login e-mail/senha → Supabase Auth → sessão AAL1
                              |
                              +--> onboarding/provisionar, se necessário
                              |
                              +--> configurar/verificar TOTP → sessão AAL2
                                                            |
                                                            v
Flutter client → Bearer JWT → Serverpod → JWT/JWKS + Usuario + AAL2
                                               |
                                               v
                                      operação autorizada
```

- O Supabase Auth emite o JWT. O SDK no Flutter administra persistência, logout e refresh de sessão; o provider do client Serverpod lê o token atual a cada RPC.
- O handler de autenticação do backend verifica assinatura assimétrica via JWKS e claims, inclusive issuer, audience, expiração, sujeito (`sub`) e nível de autenticação (`aal`).
- O `auth.provisionar()` associa o `sub` do Supabase a um `Usuario` interno após consultar o e-mail confirmado e validar a lista de convites autorizados. O onboarding pode ocorrer com AAL1/AAL2, **sem liberar operações funcionais em AAL1**.
- `auth.me()` e operações funcionais exigem `Usuario` interno, **AAL2** e verificação de propriedade dos dados (`UsuarioScope`).
- `Usuario.isAdmin` restringe a consulta, emissão e reenvio de convites; convite não promove automaticamente o convidado a administrador.
- Convites e recuperação utilizam SMTP Resend configurado no Supabase Auth. As rotas `/auth/confirm` (confirmação explícita) e `/auth/callback` (compatibilidade) preservam o controle de identidade e, quando exigido, MFA antes de alterar a senha.
- Links de e-mail não concedem automaticamente AAL2 nem acesso aos endpoints de domínio. Credenciais secretas do Supabase e banco ficam exclusivamente em ambiente servidor/operacional, nunca no build Web.

**Limite importante:** logout/revogação não invalida retroativamente todo JWT de acesso já emitido antes de sua expiração; a validação local do backend segue a validade do token. A política de sessão é administrada pelo Supabase Auth.

Documentação: [Autenticação Supabase](autenticacao-supabase.md), [Confirmação](auth-confirmation.md), [Callback](auth-callback-flutter.md) e [Convites](convites-admin.md).

## 5. Modelo de dados

As entidades de negócio persistem no PostgreSQL Supabase, gerenciadas pelo Serverpod.

| Modelo / tabela | Dados e relacionamentos principais |
| --- | --- |
| `Usuario` / `usuarios` | `supabaseUserId` único, `isAdmin`, `createdAt` |
| `EmailWhitelist` / `emails_whitelist` | E-mail normalizado, consumo, cooldown e reserva de envio |
| `Demanda` / `demandas` | `usuarioId`, `demandaPaiId` opcional, ordem, título, descrição, status, prioridade e tempos |
| `RegistroTempo` / `registros_tempo` | `demandaId`, início UTC, duração em minutos, observação e data de criação |
| `AnotacaoDemanda` / `anotacoes_demanda` | `demandaId`, `autorId`, conteúdo e datas de criação/edição/exclusão lógica |
| `Sprint` / `sprints` | `usuarioId`, nome, datas, tempo previsto opcional, status |
| `SprintDemanda` / `sprints_demandas` | `sprintId` e `demandaId`; par único, vínculo N:N |

```text
Supabase Auth (UUID / sub)
          |
          v
Usuario (ID interno)
   +-- 1:N --> Demanda -- 1:N --> RegistroTempo
   |                |
   |                +-- 1:N --> Demanda filha (mesma entidade)
   |                +-- 1:N --> AnotacaoDemanda (autor = Usuario)
   |
   +-- 1:N --> Sprint
                    |
                    +-- N:N --> Demanda via SprintDemanda
```

**Hierarquia:** toda filha é uma Demanda com `demandaPaiId`; descendentes podem ter múltiplos níveis. A exclusão simples recusa Demandas com filhas; a exclusão explícita da árvore remove descendentes e registros associados transacionalmente. Anotações possuem exclusão lógica e verificação de autoria.

**Vínculo com Sprint:** a tabela `demandas` **não** possui uma coluna `sprint`. `SprintDemanda` é a fonte dos vínculos, inclusive do histórico. Desde a evolução SPR-P2-01 de 03/11/2026, uma Demanda pode pertencer à Sprint ativa e a mais de uma Sprint futura planejada **desde que os períodos não se sobreponham**, preservando vínculos anteriores e históricos. O cancelamento de Sprint preserva os vínculos históricos; reabrir revalida as regras. Vínculos removidos por versões antigas não são reconstruídos automaticamente.

O backend oferece `sprint.listarContextoDemandas` para consultar em lote as Sprints e os vínculos visíveis ao proprietário. O histórico visível não muda a semântica do filtro **Sprint aberta / Sem Sprint**, que considera os vínculos abertos (ativas ou planejadas). A alteração SPR-P2-01 teve migration aplicada em PROD; sua API e frontend foram publicados em 03/11/2026. A homologação manual da vinculação otimizada e de seu desempenho real permanece registrada separadamente, sem SLA presumido.

Leia [Múltiplas Sprints por Demanda](spr-p2-01-multiplas-sprints.md) e [Roadmap](roadmap.md).

## 6. Regras de negócio e tempo

**Demandas:** status `aberta`, `emAndamento`, `pausada`, `concluida` e `cancelada`. O serviço de domínio controla transições, reaberturas permitidas, cancelamento com motivo obrigatório e conclusão/cancelamento em cascata. O frontend não presume sucesso antes da confirmação do backend. Veja [Transições de status](transicoes-status.md).

**Sprints:** estados `planejada`, `ativa`, `concluida` e `cancelada`. Regras de integridade no PostgreSQL garantem no máximo uma Sprint ativa por proprietário e proíbem sobreposição de períodos para planejadas, ativas ou concluídas do mesmo proprietário. Intervalos de datas de Sprint consideram ambos os dias extremos; canceladas não bloqueiam novos períodos.

**Tempo:** o usuário informa horas na UI, mas o servidor/banco persistem **minutos inteiros**. O tempo estimado segue passos de 30 minutos; lançamentos executados precisam ter duração positiva e representável em minutos. Registros possuem início em UTC, visualizados no fuso local do navegador. Consultas usam intervalos semiabertos `[início, fim)`.

O total `tempoExecutadoMinutos` da Demanda é um resumo derivado dos registros, mantido pelo backend. Indicadores de Sprint e relatórios são calculados a partir dos dados persistidos. A mesma execução não deve ser duplicada por estar associada a múltiplas Sprints: cada indicador considera as regras do período consultado.

**Anotações e observações:** Anotação de Demanda tem autoria, edição e exclusão lógica. RegistroTempo possui observação opcional; metadados de proveniência usados em uniões de apontamentos permanecem exclusivos do servidor, garantindo preservação do texto original sem expô-los ao cliente.

## 7. Backend, API e migrations

Os endpoints e serviços Serverpod concentram regras, validações de ownership e acesso ao banco:

- `demanda`: CRUD, movimentação/ordem, hierarquia e transições de status;
- `registroTempo`: registrar, listar por Demanda/período, editar, excluir e atualizar observação;
- `anotacaoDemanda`: listar, criar, editar e excluir logicamente;
- `sprint`: CRUD/ciclo de vida, vínculos, contexto em lote e indicadores;
- `relatorio`: agregações de tempo e demandas;
- `auth`: provisionamento e consulta do usuário;
- `convite`: operações administrativas de convite.

Em alterações de modelos `.spy.yaml`, executar `serverpod generate` e revisar contratos, artefatos gerados e migrations. Não editar client ou código gerado manualmente.

Migrations **nunca são aplicadas automaticamente em PROD**: exigem revisão SQL, ensaio em banco descartável, backup válido, aprovação específica e aplicação controlada, separada do deploy. As migrations de produção já aprovadas (incluindo `sprint-integrity` e `spr-p2-01`) possuem evidências nos respectivos runbooks. A execução do Railway em produção mantém a aplicação automática de migrations desabilitada.

As Sprints dependem de objetos SQL customizados não expressos integralmente no modelo Serverpod: índice único parcial de Sprint ativa por usuário, exclusion constraint de períodos, triggers de vínculo e extensão PostgreSQL aplicável. O `definition.sql` e futuras migrations precisam preservá-los. Não alterar migrations históricas já aplicadas.

Referências: [Schema de Sprints](schema-sprints-serverpod.md), [Migrations PROD](migrations-prod.md), [SPR-P2-01](spr-p2-01-multiplas-sprints.md).

## 8. Hospedagem, publicação e ambientes

- **GitHub:** branch `main` como linha principal de integração. O versionamento inclui código, docs e migrations, mas não secrets, dumps ou arquivos privados.
- **GitHub Actions:** `.github/workflows/deploy-pages.yml` faz build release Flutter com as configurações públicas do ambiente e publica pela Cloudflare Pages. Em push na `main`, o workflow reage a arquivos de `app/**` ou ao próprio workflow; também suporta acionamento manual por ambiente. **Alterar apenas `docs/** não dispara esse deploy.**
- **Cloudflare Pages:** publica a SPA em `https://temdas.com.br`, mantém fallback para links diretos (inclusive autenticação) e domínio do projeto.
- **Railway:** executa o backend Serverpod; sua publicação é operacionalmente separada do workflow de frontend, com atenção à compatibilidade de migrations, endpoints e clientes em mudanças coordenadas.
- **Supabase:** projetos/credenciais de desenvolvimento e produção distintos; o PostgreSQL é consumido pelo Serverpod e o Auth pelo SDK Flutter e por chamadas administrativas autorizadas do backend.
- **Resend:** entrega os e-mails do Supabase Auth por SMTP, inclusive recovery e convites.
- **HTTPS e TLS:** frontend/API públicos via HTTPS; conexões diretas PostgreSQL de backup e migration usando IPv6/TLS `verify-full`. A prova de falha de certificado/hostname inválido especificamente para o cliente PostgreSQL do Serverpod permanece registrada como parcial no roadmap — não a declarar homologada sem evidência.

Autenticação por e-mail/senha, MFA, callback e convites já foram homologados em PROD. A publicação do recurso SPR-P2-01 foi concluída, mas alguns cenários manuais de seu desempenho/vinculação permanecem pendentes de homologação, como descrito no próprio item.

## 9. Backup e recuperação

A operação PROD já possui backup recorrente **criptografado**, executado a partir de Windows Task Scheduler/WSL, leitura direta do PostgreSQL remoto e segunda cópia no disco F:. O processo valida integridade e realizou ensaio de **restauração em cluster PostgreSQL isolado**, preservando dados, schema e os objetos customizados de Sprint.

Limites operacionais atuais:

- Os dois destinos conhecidos ficam **no mesmo computador**. Isso não representa backup offsite nem protege contra perda de todo o equipamento.
- Cópia externa da chave/recuperação e proteção offsite são atividades distintas ainda registradas.
- A rotina depende da disponibilidade do PC e das condições de login configuradas no Windows; não funciona com computador desligado.
- Nenhum dump, chave privada, senha ou arquivo de recuperação deve ser versionado, incluído em logs ou exibido nesta documentação.

Procedimentos e evidências: [Backup/restauração PROD](backup-restauracao-prod.md) e [Migrations PROD](migrations-prod.md).

## 10. Execução local

Portas padrão de desenvolvimento: Flutter Web `3000`; Serverpod API `8080`, Insights `8081` e Web `8082`. O serviço Insights é auxiliar; sua indisponibilidade local não bloqueia a API.

Backend:

```bash
cd serverpod/temdas_backend/temdas_backend_server
dart run bin/main.dart
dart analyze
```

Frontend (usar apenas valores **públicos** do ambiente):

```bash
cd app
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 \
  --dart-define=SUPABASE_URL=<url-publica-do-projeto> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<sb_publishable_...> \
  --dart-define=SERVERPOD_URL=http://localhost:8080/
flutter analyze
flutter test
```

Os testes de integração dependem de serviços e bancos de teste disponíveis; executar somente contra o ambiente intencional. Nunca enviar senha ou secret do servidor em `--dart-define`. Para configuração e diagnóstico local: [Setup Serverpod](setup-serverpod.md).

## 11. Limites atuais e roadmap

**Implementado:** Demandas e hierarquia, Kanban/Lista, anotações, Sprints e múltiplos vínculos não sobrepostos, Log Time, relatórios, autenticação com MFA, convites, recuperação, UX responsiva, home pública, deploy e backup operacional com restauração SQL comprovada.

**Em evolução ou fora do MVP atual:** associação formal de Projetos a Demandas, organizações/equipes, permissões colaborativas, recuperação controlada de MFA, timer automático, etiquetas, anexos, n8n, Google Calendar, notificações, dashboards mais avançados, monitoramento operacional ampliado e backup offsite. O estado e a prioridade de cada item devem ser conferidos no [roadmap oficial](roadmap.md); funcionalidades aprovadas não devem ser descritas como já implementadas sem confirmação.

**Princípio de arquitetura:** Flutter apresenta e orquestra ações; Serverpod autoriza, valida e persiste o domínio; Supabase Auth autentica; PostgreSQL armazena dados; Cloudflare Pages entrega a interface; Railway executa a API; Resend entrega e-mails; GitHub versiona e automatiza o deploy do frontend.
