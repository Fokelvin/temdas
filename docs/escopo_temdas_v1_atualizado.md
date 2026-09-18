# TEMDAS — Escopo Atual da V1

## 1. Objetivo

O TEMDAS é um sistema pessoal para organização de demandas e controle de tempo, com foco em acompanhar trabalho planejado e realizado de forma simples, visual e rastreável.

A V1 consolida quatro capacidades principais:

- organizar demandas em uma estrutura hierárquica;
- acompanhar o estado das demandas ao longo do fluxo de trabalho;
- registrar tempo executado manualmente e comparar com o tempo estimado;
- visualizar o trabalho e os lançamentos de tempo em diferentes contextos, incluindo board de demandas, agenda diária/semanal e detalhes da demanda.

Sprint, automações externas e autenticação continuam fora do escopo funcional da V1.

---

## 2. Estado atual da V1

A V1 já ultrapassou a fase de protótipo e possui backend, banco e fluxos reais.

Arquitetura vigente:

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

O Flutter não acessa o Supabase diretamente. O Serverpod é a camada oficial de backend e regras de negócio.

O n8n não participa da arquitetura da V1.

---

## 3. Funcionalidades incluídas na V1

### 3.1 Demandas

A V1 deve permitir e já possui como núcleo funcional:

- criar demandas;
- listar demandas persistidas;
- editar demandas;
- excluir demandas;
- consultar detalhes de uma demanda;
- alterar status;
- concluir e reabrir demandas conforme as regras de domínio;
- informar tempo estimado;
- visualizar tempo executado acumulado;
- criar demandas filhas vinculadas a uma demanda mãe;
- visualizar a hierarquia entre demandas;
- movimentar demandas entre estados suportados pelo board.

Prioridade permanece presente no modelo e na interface existente, mas não constitui um eixo de evolução funcional da V1.

Sprint e observações permanecem persistidas por compatibilidade com o modelo existente, mas não recebem fluxo funcional próprio nesta versão.

---

## 4. Hierarquia de demandas

Demanda raiz e demanda filha utilizam a mesma entidade.

```text
demandaPaiId = null  → demanda raiz
demandaPaiId = id    → demanda filha
```

A hierarquia não é limitada conceitualmente a apenas um nível. O backend e a persistência suportam descendentes, incluindo filhas, netas e níveis inferiores.

Regras importantes:

- uma demanda filha mantém os mesmos atributos funcionais de uma demanda normal;
- o vínculo é autorreferenciado na tabela de demandas;
- exclusões da árvore respeitam integridade referencial e cascata;
- não existe promoção automática de uma filha para raiz na V1.

### Exclusão

- uma demanda sem filhas pode ser excluída diretamente;
- a exclusão simples é recusada se a demanda possuir descendentes;
- nesse caso, a interface informa a existência da árvore e permite cancelar ou excluir tudo;
- excluir tudo remove a raiz, todos os descendentes e seus registros de tempo em uma transação no backend.

---

## 5. Status e fluxo de trabalho

Os status atualmente persistidos são:

```text
aberta
emAndamento
pausada
concluida
cancelada
```

As regras de transição são tratadas como regra de domínio no backend, e não apenas como comportamento visual do frontend.

A V1 inclui:

- alteração de status;
- conclusão;
- reabertura quando permitida;
- conclusão em cascata para árvores de demandas;
- cancelamento em cascata;
- tratamento do motivo de cancelamento conforme as regras centralizadas do projeto.

A documentação específica de transições de status deve permanecer como fonte de verdade para quais movimentos são válidos entre os estados.

---

## 6. Board e drag-and-drop

A tela de Demandas funciona como board de trabalho e permite movimentar demandas por drag-and-drop entre destinos válidos.

Comportamento atual esperado:

- as áreas de drop ficam discretas quando não há drag ativo;
- durante o drag, as áreas válidas aumentam para facilitar o posicionamento;
- quando a coluna possui cards, a área de drop acompanha uma dimensão próxima ao card;
- em coluna vazia, existe uma área mínima de drop;
- ao passar sobre um destino válido, a interface indica visualmente que a demanda pode ser solta naquele local;
- durante a persistência da movimentação, o destino exibe loading local;
- os handles de drag ficam desabilitados enquanto uma movimentação está em andamento;
- após sucesso, o estado confirmado pelo backend é consolidado na interface;
- o scroll horizontal do board permanece disponível.

O drag-and-drop é uma forma de executar uma alteração de domínio. A UI não deve considerar uma movimentação concluída apenas pela posição visual; o backend continua sendo a fonte de verdade.

---

## 7. Tempo estimado

O usuário trabalha com horas no frontend.

O backend e o banco persistem tempo em minutos inteiros.

Exemplo:

```text
8,5 h → 510 minutos
```

Regras:

- tempo estimado não pode ser negativo;
- o tempo estimado usa passos de 0,5 hora / 30 minutos;
- a conversão é responsabilidade da camada de aplicação antes da persistência;
- não alterar o banco para `double` apenas para representar horas na interface.

---

## 8. Log Time / tempo executado

Tempo executado na V1 é registrado manualmente por lançamentos independentes vinculados à demanda.

Cada `RegistroTempo` contém:

- `demandaId`;
- `inicioEm` em UTC;
- `duracaoMinutos` inteiro e positivo;
- `criadoEm` em UTC.

Comportamento:

- o usuário informa a duração em horas;
- o frontend converte horas para minutos inteiros antes de chamar o backend;
- datas e horários escolhidos no navegador são interpretados no fuso local e convertidos para UTC;
- o total executado da demanda é recalculado no backend após inclusão ou exclusão de um lançamento;
- `tempoExecutadoMinutos` na demanda funciona como resumo derivado dos registros reais;
- consultas por período usam intervalo semiaberto `[início, fim)` para evitar duplicidade em fronteiras de dias e semanas.

A V1 não possui timer automático, pausa ou retomada de timer.

---

## 9. Agenda diária e semanal

A tela de Log Time utiliza dados reais de `RegistroTempo`.

A V1 inclui:

- visualização diária;
- visualização semanal;
- criação de lançamento manual;
- exclusão de lançamento;
- associação dos lançamentos às respectivas demandas;
- navegação baseada em períodos reais persistidos no banco.

A agenda não é um calendário de blocos planejados por início/fim obrigatório da demanda. Ela representa principalmente os registros de tempo executado.

---

## 10. Detalhes da demanda

A V1 possui uma visão de detalhes da demanda com informações consolidadas, incluindo:

- dados principais;
- demanda mãe, quando existir;
- demandas filhas;
- histórico de lançamentos de tempo;
- tempo estimado;
- tempo executado;
- comparação entre estimado e executado.

A tela de detalhes complementa o card resumido do board e concentra informações que não precisam permanecer visíveis o tempo todo na listagem principal.

---

## 11. Comparação estimado x executado

A V1 deve permitir comparar claramente:

```text
tempo estimado
versus
tempo executado acumulado
```

Essa comparação aparece no contexto das demandas e em suas informações detalhadas.

Dashboard avançado e métricas analíticas continuam fora do escopo.

---

## 12. Design system e UX

O frontend utiliza um design system centralizado.

Arquivos e responsabilidades principais:

- `app_theme.dart`: temas `AppTheme.light` e `AppTheme.dark`;
- `temdas_colors.dart`: paleta;
- `TemdasSemanticColors`: cores semânticas de status e prioridade;
- `TemdasTokens`: radius, bordas, espaçamentos e demais tokens recorrentes;
- `Theme.of(context)`, `ColorScheme` e `TextTheme`: fonte oficial para estilos dos componentes.

Regras:

- não criar identidade visual isolada em widgets;
- evitar HEX hardcoded em novas telas e componentes;
- reutilizar os temas globais de componentes;
- o modo claro/escuro segue `ThemeMode.system`;
- IBM Plex Sans é a fonte global empacotada no projeto;
- o board possui densidade Normal/Compacta por `DensidadeDemanda`;
- densidade é apenas uma preferência de apresentação e não altera estado de negócio;
- Log Time herda o tema global, mesmo quando não possui customizações específicas de layout.

---

## 13. Responsabilidades de arquitetura

### View / Page

Responsável por renderização, formulários, confirmações, feedback visual e interação do usuário.

Não deve chamar endpoints Serverpod diretamente.

### ViewModel

Responsável por:

- estado da tela;
- carregamento;
- erros;
- coordenação das ações;
- conversões necessárias entre a apresentação e o domínio.

### Repository

Responsável por montar requests e chamar o client Serverpod.

É a única camada do Flutter que deve conversar diretamente com o client gerado.

### Serverpod Client

É gerado automaticamente e não deve ser editado manualmente.

### Backend

Responsável por:

- validar regras de negócio;
- executar mutações;
- controlar transações;
- garantir consistência de status e hierarquia;
- manter os totais derivados de tempo;
- acessar PostgreSQL.

### PostgreSQL

Responsável por persistência, integridade referencial, constraints, chaves estrangeiras e cascatas definidas pelo modelo.

---

## 14. Endpoints de domínio da V1

### Demandas

```text
demanda.criarDemanda
demanda.listarDemandas
demanda.buscarDemandaPorId
demanda.atualizarDemanda
demanda.alterarStatusDemanda
demanda.concluirDemandaEmCascata
demanda.cancelarDemandaEmCascata
demanda.excluirDemanda
demanda.excluirArvoreDemanda
```

### Registro de tempo

```text
registroTempo.registrarTempo
registroTempo.listarRegistrosTempoPorPeriodo
registroTempo.listarRegistrosTempoDaDemanda
registroTempo.excluirRegistroTempo
```

---

## 15. Persistência e migrations

A migration principal da V1 para hierarquia e tempo é:

```text
20260910015252236-v1-demandas-filhas-tempo
```

Ela adiciona:

- relacionamento autorreferenciado de demandas;
- tabela `registros_tempo`;
- índices necessários;
- chaves estrangeiras e regras de cascade.

Ao alterar modelos `.spy.yaml`:

1. executar `serverpod generate`;
2. revisar o client gerado;
3. revisar a migration;
4. aplicar a migration de forma controlada;
5. validar backend e Flutter.

Arquivos gerados pelo Serverpod não devem ser editados manualmente.

---

## 16. Fora do escopo da V1

Permanecem fora da V1:

- autenticação;
- timer automático;
- pausa e retomada de timer;
- n8n;
- agentes de IA;
- Google Calendar;
- notificações;
- tags;
- anexos;
- histórico persistente de alterações;
- dashboard avançado;
- fluxo funcional de Sprint;
- planejamento de Sprint;
- promoção explícita de demanda filha para raiz;
- novas regras de prioridade;
- banco local;
- acesso direto Flutter → Supabase.

---

## 17. Roadmap de fechamento da V1

A maior parte do núcleo funcional já está implementada.

Estado consolidado:

```text
Arquitetura Flutter/Serverpod/PostgreSQL  ✅
CRUD real de demandas                    ✅
Hierarquia de demandas                   ✅
Exclusão simples e em árvore             ✅
Regras de status                         ✅
Registro manual de tempo                 ✅
Agenda diária                            ✅
Agenda semanal                           ✅
Detalhes da demanda                      ✅
Estimado x executado                     ✅
Design system                            ✅
Board por status                         ✅
Drag-and-drop de demandas                ✅
Loading/feedback da movimentação         ✅
```

O fechamento da V1 deve se concentrar em:

- validação ponta a ponta dos fluxos já implementados;
- testes de regressão das regras de status e hierarquia;
- validação de drag-and-drop em cenários de coluna vazia e preenchida;
- consistência entre tema claro e escuro;
- revisão responsiva e de densidade Normal/Compacta;
- atualização e consolidação da documentação;
- correções de bugs encontrados nessa validação.

Novas funcionalidades devem ser tratadas como pós-V1, salvo decisão explícita de mudança de escopo.

---

## 18. Critérios de conclusão da V1

A V1 pode ser considerada concluída quando:

- CRUD de demandas funcionar ponta a ponta com persistência real;
- hierarquia de demandas funcionar com integridade e exclusão em árvore;
- transições de status válidas forem respeitadas pelo backend;
- movimentações por drag-and-drop persistirem corretamente o estado;
- falhas de movimentação não deixarem a UI em estado divergente do backend;
- tempo estimado continuar sendo armazenado em minutos inteiros;
- usuário puder criar e excluir registros manuais de tempo;
- total executado da demanda refletir os registros reais;
- visão diária utilizar dados persistidos;
- visão semanal utilizar dados persistidos;
- detalhes exibirem hierarquia, registros e estimado x executado;
- reload do navegador preservar o estado por meio do backend;
- funcionalidades da V1 não dependerem de mocks;
- tema claro e escuro permanecerem funcionais;
- `flutter analyze` não apresentar problemas relevantes;
- `flutter test` permanecer verde;
- `dart analyze` do backend não apresentar problemas relevantes.

---

## 19. Fonte de verdade

Em caso de divergência entre documentos históricos e o estado atual, utilizar esta ordem:

```text
1. Código versionado e migrations aplicadas
2. Regras de domínio documentadas atualmente
3. Arquitetura da V1
4. Escopo da V1
5. Handoffs históricos
```

O handoff para Codex deve ser tratado apenas como registro histórico da etapa em que o CRUD ainda não estava concluído.
