# TEMDAS — Arquitetura da V1

## Objetivo

O TEMDAS é um sistema pessoal para organizar demandas e demandas filhas,
registrar tempo executado manualmente e visualizar os lançamentos por dia ou
semana. A comparação entre estimado e executado aparece nos cards e nos
detalhes de cada demanda.

Este documento consolida o escopo e a arquitetura implementada ao final da V1.
Em caso de divergência com materiais temporários de handoff, o código e as
migrations versionadas prevalecem.

## Fluxo da aplicação

```text
Flutter Web
  View / Page
    ↓
  ViewModel
    ↓
  Repository
    ↓
  Serverpod Client gerado
    ↓
Serverpod Backend
    ↓
Supabase PostgreSQL
```

O Flutter não acessa o Supabase diretamente. Não há n8n, autenticação, timer
automático ou banco local na V1.

## Responsabilidades

- **View/Page:** renderiza estado, formulários, confirmações e feedback.
- **ViewModel:** coordena carregamento e mutações, mantém o estado da tela e
  converte horas do frontend para minutos inteiros.
- **Repository:** monta requests e é a única camada do app que chama o client
  Serverpod.
- **Client Serverpod:** contrato gerado a partir dos modelos e endpoints; não é
  editado manualmente.
- **Backend:** valida regras, executa mutações transacionais e acessa o banco.
- **PostgreSQL:** garante chaves estrangeiras e exclusões em cascata.

## Dados persistidos

### Demanda

Uma demanda filha usa a mesma entidade de uma demanda normal e possui
`demandaPaiId` opcional apontando para outra demanda:

```text
demandaPaiId = null  → demanda raiz
demandaPaiId = id    → demanda filha
```

Campos funcionais da V1 incluem título, descrição, status, tempo estimado,
tempo executado e vínculo com a mãe. Prioridade permanece no modelo e na UI
existente, sem novas regras. Sprint e observações permanecem persistidas, mas
sem funcionalidades próprias; seus valores são preservados durante a edição.

### RegistroTempo

Cada lançamento manual é uma linha em `registros_tempo` com:

- `demandaId`;
- `inicioEm` em UTC;
- `duracaoMinutos` inteiro e positivo;
- `criadoEm` em UTC.

As agendas são derivadas desses registros persistidos. A coluna
`tempoExecutadoMinutos` da demanda é mantida como resumo e recalculada no
backend após criar ou excluir um registro.

## Regras de tempo

O usuário informa durações em horas no Flutter. O formulário de lançamento
aceita somente valores positivos que resultem em minutos inteiros. O fluxo de
Demandas converte a duração na página e o de Log time no `AgendaViewModel`, que
também valida a conversão; ambos enviam minutos ao backend pelo Repository.
O tempo estimado continua usando passos de 0,5 hora (30 minutos).

Datas e horários selecionados são interpretados no fuso local do navegador e
convertidos para UTC antes de chamar o backend. Consultas usam intervalos
semiabertos `[início, fim)`, evitando duplicar registros na fronteira entre
dias ou semanas.

## Hierarquia e exclusão

O vínculo `demandas.demandaPaiId → demandas.id` usa `ON DELETE CASCADE`. O
vínculo `registros_tempo.demandaId → demandas.id` também usa cascade.

- Uma folha pode ser excluída pelo endpoint de exclusão simples.
- A exclusão simples recusa demandas que possuem filhas.
- A UI avisa quando existem descendentes e oferece apenas cancelar ou
  **Excluir tudo**.
- **Excluir tudo** chama o endpoint específico para a árvore.
- A exclusão da raiz remove recursivamente filhas, netas e demais descendentes,
  além de todos os seus registros de tempo, em uma transação no backend.
- Não existe promoção automática de filha para raiz na V1.

## Telas da V1

- **Demandas:** CRUD real, árvore de demandas, criação de filha, conclusão,
  reabertura, exclusão e lançamento manual de tempo.
- **Log time:** agenda diária e semanal derivada dos registros reais, criação e
  exclusão de lançamentos.
- **Detalhes da demanda:** dados completos, mãe, filhas, histórico de tempo e
  comparação de estimado versus executado.
- **Sprint:** permanece apenas como navegação preexistente; não recebe fluxo
  funcional na V1.

## Endpoints de domínio

```text
demanda.criarDemanda
demanda.listarDemandas
demanda.buscarDemandaPorId
demanda.atualizarDemanda
demanda.excluirDemanda
demanda.excluirArvoreDemanda

registroTempo.registrarTempo
registroTempo.listarRegistrosTempoPorPeriodo
registroTempo.listarRegistrosTempoDaDemanda
registroTempo.excluirRegistroTempo
```

## Migração da V1

A migration `20260910015252236-v1-demandas-filhas-tempo` adiciona o vínculo
autorreferenciado de demandas e cria `registros_tempo` com seus índices e
chaves estrangeiras. Ela foi gerada pelo Serverpod, revisada antes da aplicação
e aplicada ao banco configurado do projeto.

## Execução e validação

Backend:

```bash
cd serverpod/temdas_backend/temdas_backend_server
dart run bin/main.dart
dart analyze
```

Frontend:

```bash
cd app
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
flutter analyze
flutter test
```

Após alterações em arquivos `.spy.yaml`, executar `serverpod generate`, revisar
o client e a migration gerados e nunca editar esses artefatos manualmente.

## Fora da V1

Autenticação, timer automático, n8n, Google Calendar, notificações, tags,
anexos, dashboard avançado, histórico de alterações, fluxo de Sprint e promoção
explícita de demanda filha para raiz permanecem fora do escopo.
