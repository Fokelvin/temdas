# TEMDAS — Handoff histórico de Desenvolvimento para Codex

> Registro histórico anterior à conclusão dos fluxos da V1, preservado como
> contexto das decisões. As listas de pendências, a estrutura de arquivos e as
> instruções de retomada abaixo retratam aquela etapa e estão desatualizadas.
> Para o estado implementado, consulte [Arquitetura da V1](arquitetura.md), o
> código atual e as migrations. CRUD, demandas filhas, registros de tempo,
> agendas e detalhes já foram implementados; o `WorkspaceViewModel` foi removido.
> Use o checkpoint mais recente para decidir quais validações ainda são necessárias.

---

## 1. Objetivo do TEMDAS

O TEMDAS é um sistema pessoal para gestão simples de demandas e controle de tempo.

A V1 deve permitir organizar demandas e demandas filhas, acompanhar tempo estimado versus tempo executado manualmente e visualizar esse trabalho em visões diária e semanal.

---

## 2. Escopo oficial da V1

A V1 deve permitir:

- cadastrar demandas;
- cadastrar demandas filhas;
- definir status;
- informar tempo estimado;
- informar tempo executado manualmente;
- visualizar demandas em formato diário;
- visualizar demandas em formato semanal;
- comparar tempo estimado versus tempo executado.

### Fora do escopo da V1

Não priorizar nem desenvolver como requisito da V1:

- prioridade;
- timer automático;
- pausa e retomada de timer;
- observações/anotações;
- tags;
- anexos;
- histórico de alterações;
- autenticação;
- dashboards avançados;
- integrações com n8n;
- integração com Google Calendar;
- notificações;
- sprint.

### Campos já existentes, mas fora do escopo

O backend atual já possui alguns campos que não fazem parte da V1, principalmente:

- `prioridade`;
- `sprint`;
- `observacoes`.

**Não remover agora apenas por estarem fora da V1.**
Evitar migrations e retrabalho sem necessidade.

Regras práticas:

- `sprint` pode continuar existindo e aparecer como `Não informada`;
- não criar fluxo de Sprint na V1;
- `observacoes` pode continuar existindo no modelo, mas não precisa de formulário na V1;
- `prioridade` já possui implementação parcial no frontend/backend; pode permanecer, mas não investir em regras, filtros ou funcionalidades adicionais de prioridade.

---

## 3. Arquitetura atual — fonte de verdade

A arquitetura antiga que previa:

```text
Flutter Web → n8n Webhook → PostgreSQL
```

**não representa mais o projeto atual.**

A arquitetura vigente é:

```text
Flutter Web
    ↓
Serverpod Client gerado
    ↓
Serverpod Backend
    ↓
Supabase PostgreSQL
```

### Stack

- Frontend: Flutter Web
- Backend/API: Serverpod
- Banco: Supabase PostgreSQL remoto
- Client: package Dart gerado pelo Serverpod
- Autenticação: fora da V1 e removida do backend atual
- n8n: fora da V1
- Banco local: não usar

### Portas locais

```text
Flutter Web        3000
Serverpod API      8080
Serverpod Insights 8081
Serverpod Web      8082
```

---

## 4. Organização do frontend

A direção arquitetural atual é simples e separa responsabilidades:

```text
View/Page
    ↓
ViewModel
    ↓
Repository
    ↓
Serverpod Client
    ↓
Backend
```

### Responsabilidades

#### View / Page

Responsável por:

- renderizar campos;
- botões;
- cards;
- loading;
- erros;
- interação do usuário.

Não deve chamar endpoint Serverpod diretamente.

#### ViewModel

Responsável por:

- estado da tela;
- loading;
- erros;
- lista de demandas;
- coordenação das ações;
- conversões de apresentação, como horas ↔ minutos.

#### Repository

Responsável por:

- montar requests do client;
- chamar os endpoints Serverpod;
- devolver os objetos do backend para o ViewModel.

#### Serverpod Client

É gerado automaticamente e não deve ser editado manualmente.

O app usa um client central:

```text
app/lib/data/serverpod_client.dart
```

com conexão para:

```text
http://localhost:8080/
```

---

## 5. Estrutura atual relevante

Arquivos principais do frontend:

```text
app/lib/
├── app/
│   ├── app_routes.dart
│   └── temdas_app.dart
├── data/
│   ├── serverpod_client.dart
│   └── repositories/
│       └── demanda_repository.dart
├── view/
│   ├── demandas_page.dart
│   └── widgets/
│       └── demanda_card.dart
└── view_model/
    ├── demandas_view_model.dart
    └── workspace_view_model.dart
```

`WorkspaceViewModel` pertence ao protótipo anterior e ainda pode existir para telas mockadas.
**Não usar como ponto central do CRUD real de demandas.**
O CRUD real deve ficar no `DemandasViewModel`.

Backend relevante:

```text
serverpod/temdas_backend/
├── temdas_backend_client/
└── temdas_backend_server/
    └── lib/src/demandas/
```

---

## 6. Modelo de Demanda atual no backend

O modelo atual possui aproximadamente:

```yaml
class: Demanda
table: demandas
fields:
  titulo: String
  descricao: String?
  status: DemandaStatus
  prioridade: Prioridade
  sprint: String?
  tempoEstimadoMinutos: int
  tempoExecutadoMinutos: int
  observacoes: String?
  criadoEm: DateTime
  atualizadoEm: DateTime
  concluidoEm: DateTime?
```

Status atuais:

```text
aberta
emAndamento
pausada
concluida
cancelada
```

Prioridades atuais:

```text
baixa
media
alta
urgente
```

### Regras backend já implementadas

- título obrigatório;
- tempo estimado não pode ser negativo;
- tempo estimado deve ser múltiplo de 30 minutos;
- nova demanda inicia com `status = aberta`;
- nova demanda inicia com `tempoExecutadoMinutos = 0`;
- prioridade default é `media`;
- ao concluir, `concluidoEm` é preenchido;
- ao reabrir, `concluidoEm` volta para `null`;
- exclusão atual é física;
- concluir e excluir são ações diferentes.

---

## 7. Regra de horas no frontend

Decisão já tomada:

**o usuário trabalha com horas; backend e banco continuam armazenando minutos inteiros.**

Exemplo:

```text
Frontend: 8.5 h
    ↓
ViewModel: 8.5 × 60
    ↓
Backend: 510 minutos
```

Na leitura:

```text
Backend: 510 minutos
    ↓
Frontend: 8.5 h
```

### Regras

- trabalhar preferencialmente em passos de `0,5 h`;
- backend permanece com múltiplos de 30 minutos;
- aceitar `1.5` e `1,5` na entrada do Flutter quando aplicável;
- não mudar banco para `double`;
- não alterar o backend só para exibir horas.

---

## 8. Cards de demanda

A listagem atual usa:

```text
app/lib/view/widgets/demanda_card.dart
```

Direção de UX já decidida:

```text
Card resumido
    ↓ clique
Card expandido
    ↓ futuramente
"Mostrar tudo"
    ↓
Página completa da demanda
```

### Requisitos do card

- usar card expansível;
- implementação atual usa `Card + ExpansionTile`;
- textos informativos devem ser selecionáveis/copíaveis;
- implementação atual usa `SelectionArea`;
- no resumo mostrar informações essenciais;
- ao expandir mostrar mais dados;
- `Mostrar tudo` deve futuramente abrir a página completa da demanda;
- não precisa criar página completa apenas para concluir o CRUD imediato.

O layout atual está limitado/centralizado e ainda não é o design final.
**Não gastar tempo agora com polimento visual.**
A etapa de design pode ficar para o final.

---

## 9. Logging e feedback

O usuário valoriza logs e feedback de operações.

Manter quando útil:

- logs do Serverpod no terminal;
- mensagens de erro legíveis;
- feedback visual da última operação;
- durante o desenvolvimento pode ser útil manter o card que mostra a última demanda retornada pelo backend.

Não criar histórico persistente de alterações na V1, pois está fora do escopo.

Nunca registrar:

- senhas;
- tokens;
- segredos;
- credenciais de banco.

---

## 10. O que já foi concluído

### Backend CRUD

Endpoints já implementados e testados via `curl`:

```text
criarDemanda
listarDemandas
buscarDemandaPorId
atualizarDemanda
excluirDemanda
```

Foram testados:

- criação;
- listagem;
- busca por ID;
- atualização;
- conclusão;
- reabertura;
- exclusão física;
- busca após exclusão retornando `null`.

### Frontend Create e Read

Já funciona:

- dependência por path para `temdas_backend_client`;
- client central;
- `DemandaRepository`;
- `DemandasViewModel`;
- criação real via Serverpod;
- retorno real do backend;
- listagem real do banco;
- recarregar lista ao abrir a página;
- recarregar lista após criação;
- cards expansíveis;
- texto selecionável;
- descrição;
- prioridade já implementada apesar de fora do escopo oficial;
- tempo informado em horas no frontend;
- conversão para minutos no backend;
- exibição de minutos convertidos novamente em horas.

---

## 11. Ponto exato em que o desenvolvimento parou

O foco atual é:

```text
Finalizar CRUD de Demanda no frontend
```

Estado:

```text
Create  ✅
Read    ✅
Update  🚧 em andamento
Delete  ⏳ pendente
```

### Update — trabalho já iniciado

Foi adicionado ao `DemandaRepository` um método semelhante a:

```dart
Future<backend.Demanda> atualizarDemanda({
  required int id,
  required String titulo,
  String? descricao,
  required backend.DemandaStatus status,
  required backend.Prioridade prioridade,
  String? sprint,
  required int tempoEstimadoMinutos,
  String? observacoes,
})
```

que monta `DemandaUpdateRequest` e chama:

```dart
_client.demanda.atualizarDemanda(request);
```

Também foi iniciado no `DemandasViewModel`:

```dart
Future<bool> atualizarDemanda({
  required backend.Demanda demanda,
  required String titulo,
  required double tempoEstimadoHoras,
  required backend.DemandaStatus status,
  required backend.Prioridade prioridade,
  String? descricao,
})
```

### Regra importante do Update

Como `sprint` e `observacoes` existem no backend mas não fazem parte do formulário da V1, **preservar o valor existente durante a edição**:

```dart
sprint: demanda.sprint,
observacoes: demanda.observacoes,
```

Não enviar `null` apenas porque os campos estão escondidos.

### Antes de continuar

Executar:

```bash
git status --short
flutter analyze
```

Há alterações posteriores ao último commit e o estado atual deve ser conferido antes de novas edições.

Último commit conhecido antes dessas alterações posteriores:

```text
db08453 feat: integrate demand creation and listing frontend
```

Não assumir que o working tree ainda está limpo.

---

## 12. Próximo objetivo imediato — terminar CRUD frontend

### 12.1 Finalizar Update

Implementar UI simples para editar uma demanda existente.

Campos da edição nesta etapa:

- título;
- descrição;
- status;
- prioridade, pois já está implementada no modelo/UI mesmo estando fora do escopo;
- tempo estimado em horas.

Preservar internamente:

- sprint;
- observações;
- tempo executado;
- criadoEm.

O backend já cuida de:

- `atualizadoEm`;
- `concluidoEm`.

Após atualizar com sucesso:

1. recarregar `listarDemandas`;
2. atualizar os cards;
3. mostrar feedback de sucesso/erro;
4. validar conclusão e reabertura pelo Flutter.

Preferir reutilizar um diálogo/formulário simples.
Não investir em design final agora.

### 12.2 Implementar Delete

Adicionar no `DemandaRepository`:

```text
excluirDemanda(id)
```

e correspondente método no `DemandasViewModel`.

Fluxo:

```text
Usuário solicita exclusão
→ confirmação explícita
→ ViewModel
→ Repository
→ Serverpod excluirDemanda
→ se true, recarregar lista
→ feedback visual
```

A exclusão atual da V1 é física.

Não confundir:

```text
status concluida != excluir demanda
```

### 12.3 Aceite do CRUD

Considerar CRUD frontend concluído quando for possível:

- criar;
- listar;
- editar;
- concluir;
- reabrir;
- excluir;
- atualizar a página e obter estado persistido do banco.

Rodar:

```bash
flutter analyze
```

e testar manualmente no navegador.

---

## 13. Depois do CRUD — ordem recomendada para completar V1

Não iniciar tudo ao mesmo tempo.

### Etapa A — Demandas filhas

A V1 exige demandas filhas.

Regra de negócio já alinhada:

> uma demanda filha funciona, para fins práticos, como uma demanda normal, mas fica vinculada a uma demanda mãe.

Recomendação de modelagem:

- adicionar relação opcional/autorreferenciada na Demanda, por exemplo `demandaPaiId`;
- demanda raiz: pai `null`;
- demanda filha: pai aponta para outra demanda;
- evitar uma entidade separada apenas para filho;
- permitir criar filha a partir da demanda mãe;
- exibir filhas de forma visualmente subordinada.

Antes de migration, revisar o modelo Serverpod e garantir integridade da relação.
Evitar ciclos se houver risco de edição futura.

### Etapa B — Tempo executado manual

Uma única coluna acumulada em `Demanda` não é suficiente para suportar corretamente visão diária/semanal.

Para a V1, usar registros de tempo separados vinculados à demanda.

Modelo recomendado, nome a definir no código de forma consistente, por exemplo:

```text
ApontamentoTempo / RegistroTempo
```

Campos mínimos recomendados:

```text
id
demandaId
data
hora/início se necessário para posicionamento na agenda
duracaoMinutos
criadoEm
```

O usuário deve informar duração em horas no frontend, convertida para minutos no backend.

O total executado da demanda deve refletir a soma dos registros.

**Não criar timer automático.**

### Etapa C — Visão diária e semanal

Depois que registros de tempo reais existirem:

- remover dependência de mocks da agenda;
- buscar dados reais;
- visão diária;
- visão semanal;
- usar registros de tempo/demanda reais;
- manter fluxo simples.

### Etapa D — Estimado versus executado

Exibir comparação utilizando:

```text
tempo estimado
versus
soma do tempo executado
```

Pode ser mostrado inicialmente de forma simples nos cards e/ou página da demanda.
Dashboard avançado fica fora da V1.

### Etapa E — polimento visual

Só depois do fluxo funcional:

- aproveitar melhor a largura da página;
- remover coluna excessivamente estreita;
- melhorar responsividade;
- ajustar espaçamentos;
- definir layout definitivo dos cards;
- página completa da demanda;
- ligar botão `Mostrar tudo`.

---

## 14. O que NÃO fazer

Não introduzir sem necessidade:

- n8n;
- autenticação;
- banco local;
- acesso direto Flutter → Supabase;
- timer;
- Google Calendar;
- notificações;
- tags;
- anexos;
- dashboard avançado;
- fluxo real de Sprint;
- histórico persistente de alterações;
- observações como nova prioridade de desenvolvimento.

Não duplicar classes do backend sem necessidade.

Evitar:

```text
View → Serverpod diretamente
```

Manter:

```text
View → ViewModel → Repository → Serverpod Client
```

Não editar manualmente arquivos gerados pelo Serverpod.

Ao alterar arquivos `.spy.yaml`:

1. gerar o código Serverpod;
2. revisar migration;
3. aplicar de forma compatível com Supabase;
4. validar backend;
5. atualizar client;
6. validar Flutter.

---

## 15. Supabase e ambiente

O banco é remoto no Supabase.

Configuração usada anteriormente:

```text
Session Pooler
host = aws-0-ca-central-1.pooler.supabase.com
port = 5432
dbname = postgres
user = postgres.ddzwawlamjnzwjjxuava
ssl = true
```

O projeto pode ser pausado pelo Supabase por inatividade.
Se aparecer erro:

```text
tenant/user ... not found
```

verificar primeiro se o projeto está pausado ou ainda em processo de retomada antes de alterar credenciais.

Não expor senha do banco no Git.

---

## 16. Comandos úteis

### Backend

```bash
cd serverpod/temdas_backend/temdas_backend_server
dart run bin/main.dart
```

### Flutter Web

```bash
cd app

flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 3000
```

### Análise Flutter

```bash
cd app
flutter analyze
```

### Análise backend

```bash
cd serverpod/temdas_backend/temdas_backend_server
dart analyze
```

### Gerar Serverpod

Executar no diretório adequado do projeto Serverpod quando houver alteração de protocolo/modelo:

```bash
serverpod generate
```

### Git antes de mudanças grandes

```bash
git status --short
git diff
git diff --check
```

---

## 17. Forma de trabalhar no restante da V1

Objetivo principal: **praticidade, organização e separação de responsabilidades.**

Ao continuar:

1. inspecionar o código atual antes de editar;
2. respeitar o que já está funcional;
3. terminar uma fatia vertical antes de abrir a próxima;
4. não reescrever backend funcional sem motivo;
5. manter Flutter consumindo Serverpod, nunca Supabase diretamente;
6. testar cada fluxo ponta a ponta;
7. rodar analyzers;
8. manter logs úteis;
9. revisar `git diff`;
10. não expandir escopo.

Prioridade de execução:

```text
1. Finalizar Update do CRUD frontend
2. Finalizar Delete do CRUD frontend
3. Validar CRUD completo ponta a ponta
4. Demandas filhas
5. Apontamento manual de tempo
6. Visão diária
7. Visão semanal
8. Comparação estimado x executado
9. Página completa da demanda / Mostrar tudo
10. Polimento visual final
```

---

## 18. Critérios de conclusão da V1

A V1 estará funcionalmente concluída quando:

- demandas forem persistidas no Supabase através do Serverpod;
- CRUD de demandas funcionar pelo Flutter;
- demanda puder possuir demandas filhas;
- status puder ser alterado;
- usuário informar tempo estimado em horas;
- backend armazenar tempo em minutos;
- usuário registrar tempo executado manualmente;
- tempo executado puder ser associado a datas;
- visão diária utilizar dados reais;
- visão semanal utilizar dados reais;
- estimado e executado forem comparáveis;
- recarregar o navegador não perder estado;
- frontend não depender de mocks para funcionalidades da V1;
- `flutter analyze` não apresentar problemas;
- `dart analyze` do backend não apresentar problemas.

---

## 19. Observação sobre documentação antiga

A documentação original tinha fases como:

```text
Fase 1 — POP visual
Fase 2 — MVP local estruturado
Fase 3 — Flutter → n8n → PostgreSQL
```

Na prática, o projeto evoluiu e essa divisão ficou desatualizada.

Situação atual:

```text
POP visual                     ✅ realizado
Estrutura Flutter inicial      ✅ realizada
Backend Serverpod              ✅ criado
Supabase                       ✅ integrado
CRUD backend                   ✅ concluído
Create/Read frontend           ✅ concluídos
Update frontend                🚧 iniciado
Delete frontend                ⏳ pendente
Demandas filhas                ⏳ pendente
Tempo manual real              ⏳ pendente
Visão diária real              ⏳ pendente
Visão semanal real             ⏳ pendente
Comparação estimado/executado  ⏳ pendente
Polimento visual               ⏳ final
```

Na época deste handoff, ele substituiu os documentos que ainda mencionavam n8n
ou backend inexistente. O estado atual está em [Arquitetura da V1](arquitetura.md).
