# SPR-P2-01 — múltiplas Sprints por Demanda

Implementação de 03/11/2026, na branch `feat/spr-p2-01-multiplas-sprints`,
a partir de `main` em `0bcb62d`. A publicação coordenada de 03/11/2026 está
registrada ao final deste documento e nas evidências JSON.

## Comportamento e contrato

- `SprintDemanda` permanece a fonte da verdade. Vínculos com Sprints abertas
  de períodos diferentes coexistem; a árvore herda todos os vínculos abertos.
  Dias extremos continuam inclusivos, conforme a regra atual de períodos.
  Locks transacionais, proprietário, par único e uma ativa por usuário permanecem.
- Cancelar mantém os vínculos; o histórico cancelado não bloqueia o planejamento.
  Desvinculação manual continua disponível apenas em Sprints abertas. Exclusão
  explícita da própria Sprint mantém seu comportamento anterior.
- Reabrir revalida período, proprietário e completude mãe/filhas. Se a árvore
  mudou durante o cancelamento, a reabertura falha atomicamente; não inventa
  vínculos históricos nem recupera os apagados antes desta versão.
- `sprint.listarContextoDemandas(List<int>? demandaIds)` é uma RPC aditiva,
  protegida por AAL2. Retorna `SprintContextoDemandas`, com `sprints` e `vinculos`.
  `null` consulta todas as Demandas do usuário; lista vazia retorna contexto
  vazio. Até três consultas de domínio, independentemente do número de Sprints; a consulta
  de propriedade projeta somente IDs, sem carregar textos das Demandas.
  Nas consultas sem filtro, metadados de Sprints sem vínculos são mantidos para
  o filtro de planejamento. No detalhe, somente Sprints vinculadas são retornadas.
- Os dois lados do vínculo são filtrados por proprietário. Todos os estados são
  retornados, sem depender de haver Sprint ativa. Sprint 72 finalizada aparece
  retroativamente quando o vínculo já está persistido.
- Listagem e detalhe exibem Ativa, planejadas por início crescente e histórico
  finalizado/cancelado por início decrescente, com desempate por ID decrescente.
  O filtro **Sprint aberta / Sem Sprint** continua considerando apenas vínculos
  ativos/planejados, mesmo quando existe histórico visível.
- O seletor mostra os vínculos da árvore e permite períodos distintos; bloqueia
  sobreposição. O backend continua sendo a autoridade no momento de gravar.
- Nome tem prefixo visual fixo `Sprint`; somente o complemento é editável e
  persistido. Exibição/edição aceitam nomes legados com prefixos repetidos.
  Não há atualização em massa de nomes.
- Registros de tempo e o serviço de indicadores não foram alterados. A mesma
  linha de tempo é contabilizada no período da Sprint, sem criar cópias.

## Migration SPR-P2-01

`20261103123548408-spr-p2-01` é necessária porque os triggers existentes
impedem qualquer segundo vínculo aberto, mesmo com períodos diferentes.

O SQL substitui somente os corpos de `temdas_validar_vinculo_sprint_aberta`
e `temdas_validar_reabertura_sprint`, acrescenta o índice
`sprints_demandas_demanda_idx` e registra a versão. Exige baseline
`20261029220000000-restore-schema-guards`, presença dos triggers, transação,
locks e timeouts. Não remove dados, não normaliza nomes, não reconstrói vínculos
e não reescreve migrations anteriores. A definição limpa conserva os demais
triggers, checks, índice de par único e proteções customizadas de Sprint.

Não executar o SQL automaticamente. O gate genérico de migrations possui regras
restritivas para SQL customizado: esta versão exige revisão e aprovação próprias;
não foi introduzido bypass nem autorização implícita para aplicar em PROD.
O teste local inicializa somente um schema limpo descartável e não executa
`migration.sql`; o caminho incremental foi ensaiado e aprovado separadamente
em 03/11/2026, antes da aplicação registrada ao final deste documento.

## Validação

`dart format`, `flutter analyze --no-pub` e análise Dart dos arquivos backend
alterados. Suítes direcionadas: Sprints, contexto de Demandas, detalhe/painel,
filtros e os novos testes de múltiplos vínculos. Repetições ficaram restritas
aos casos afetados por correções de fixtures/expectativas.

Casos cobertos: ativa e futuras coexistentes; herança da árvore em todas;
conclusão mantendo futuros e horas únicas; cancelamento preservando histórico;
reabertura com conflito de período e árvore alterada; concorrência em transações
independentes; consulta em lote com todos os estados e sem ativa; isolamento e
rejeição de AAL1; ordenação/navegação em 320/420/1200 px; prefixo fixo e nomes
legados; Sem Sprint com a semântica anterior.

Comandos reproduzíveis (sem PROD):

```sh
# Banco descartável, porta aleatória só em 127.0.0.1, sem volumes existentes.
# Requer imagem PostgreSQL 17.11 já disponível; cleanup confere ID/nome/label.
python3 scripts/testing/run_sprint_tests.py
# Para repetir só um caso, acrescente arquivo e --name ao comando acima.
python3 -m unittest discover -s scripts/migrations -p test_spr_p2_01.py -v
python3 -m unittest discover -s scripts/migrations -p test_release_guards.py -v
# No diretório do servidor:
dart test test/unit/sprint_integrity_migration_test.dart test/unit/sprint_custom_schema_test.dart
# No diretório app:
flutter test --no-pub test/sprint_page_test.dart test/sprint_view_model_test.dart test/demandas_sprint_contexto_test.dart test/demanda_detalhe_test.dart test/demanda_painel_test.dart test/pacote6_sprint_painel_test.dart test/pacote5_demandas_test.dart test/sprint_multiplas_test.dart
```

Evidências da execução em `/tmp/temdas-spr-*`: análises, testes, build e hashes
consolidados em `docs/historico/evidencias-spr-p2-01.json`. O build release é local e usa as definições públicas oficiais, sem publicação.
Foram executados dois builds locais: o segundo foi autorizado separadamente
pelo responsável após o ajuste final da largura de Sprints em lista/cards.
Os testes desse ajuste usam a fonte Inter real e verificam texto sem recorte.

## Procedimento de publicação coordenada

A revisão do contrato identifica dependência obrigatória **migration → backend
→ frontend**. O frontend novo não funciona com backend antigo por não existir a
RPC de contexto. Endpoints anteriores foram mantidos; o enum ganhou
`hierarquiaSprintInvalida`. Não promover o frontend isoladamente.

1. Aprovar e ensaiar o caminho incremental em clone isolado, conferindo baseline,
   backup, preservação de vínculos/horas, objetos e rollback transacional.
   O ensaio e a aplicação exigem autorização específica, concedida separadamente
   para esta release em 03/11/2026.
2. Aprovar janela coordenada e controlar os deploys automáticos de backend e
   Cloudflare Pages que seguem a `main`. Não integrar esta branch antes de
   definir esse controle. Não alterar infraestrutura sem autorização.
3. Na janela, suspender escritas do serviço durante a troca: o backend antigo
   ainda remove vínculos ao cancelar e não deve operar depois da mudança de
   política. Aplicar a migration revisada e publicar o backend do mesmo commit.
4. Validar saúde, AAL2, RPC nova, propriedade, períodos e preservação de histórico.
   Publicar então o frontend validado do mesmo commit, conferir o domínio,
   solicitar recarga de abas antigas e liberar a janela.
5. Homologar a Sprint 72 existente, ativa + futura, cancelamento/reabertura e horas.
   Validar a estratégia com o responsável antes de aprovar integração/publicação.

Rollback: se a migration falhar, sua transação deve reverter integralmente.
Após criar múltiplos vínculos/preservar cancelamentos, **não voltar ao backend
antigo**, que pode apagar histórico. Conservar schema e backend compatíveis;
pausar escritas e corrigir adiante. Um eventual rollback de frontend exige
avaliar a interface antiga (ela não exibe todo o histórico). Não apagar vínculos
para tornar os dados compatíveis com a versão antiga.

## Publicação autorizada em PROD — 03/11/2026

Autorização explícita do responsável para pausa de escritas, SQL SPR-P2-01,
Railway, integração sem force push e Cloudflare. Ensaios incremental e limpo
aprovados em PostgreSQL 17.11; relatório e hash do backup preservados nas
evidências. Não foram repetidos testes aprovados nem builds locais.

- Commit implementado: `2564db0`; integração: `8391659`, preservando o commit
  posterior de documentação `c32d0dd`. Código de `app/` e `serverpod/` idêntico
  ao commit aprovado após a integração.
- Backup de `2026-11-03T10:21:02.291189+00:00`, SHA-256
  `e4f4f92536671edd9bc6acd563c82a2176c2df7c6a5d52ff2cc1d2a1ea103f9f`:
  arquivo local e cópia F: reconferidos antes da aplicação.
- Pausa efetiva: domínio Railway encaminhado temporariamente de 8080 para
  porta sem serviço (8089), com resposta pública 502; processo antigo parado
  com `deploymentStop`, zero réplicas em execução e zero transações/locks
  pendentes antes da migration. A tentativa de escala zero pela CLI não
  efetivou a pausa; a configuração original `iad: 1` foi restaurada e a parada
  foi confirmada separadamente. Nenhuma migration foi aplicada antes disso.
- Aplicado exclusivamente `20261103123548408-spr-p2-01`, SQL SHA-256
  `01145a171e8296ef16bdf0d67b8991a7f0052c9b3c4a345043b00c7e00f1f31f`.
  Execução em 0,801 s, lock timeout 5 s e statement timeout 60 s.
  Histórico Serverpod, schema, índice novo, extensão/checks customizados e
  sete triggers ativos conferidos. Hashes de todas as linhas das quatro
  tabelas de negócio preservados: 2 Sprints, 13 vínculos, 14 Demandas e
  29 registros de tempo. Nenhum dado de teste criado em PROD.
- Railway `d21f891d-50e8-44a7-b5e8-30ed513b1496`: `SUCCESS`, Serverpod 3.4.11,
  `applyMigrations: false`, `applyRepairMigration: false`, Pre-Deploy vazio.
  Upload de fontes rastreadas de `2564db0`; falha TLS antes do primeiro envio
  foi conferida e repetida sem duplicar migration. Saúde interna `/readyz`
  200; RPCs `listarSprints` e `listarContextoDemandas` existentes e rejeitando
  chamadas sem token com `AuthException/tokenMissing`.
- Cloudflare: pipeline `41673125176` para `8391659` concluído com sucesso;
  deployment `https://2be57445.temdas-web.pages.dev`. Domínio
  `https://temdas.com.br` carregado em navegador isolado: HTTPS/HTTP 200,
  bootstrap e `main.dart.js` 200, Flutter renderizado e nenhum erro JavaScript.
  O JavaScript efetivamente servido pelo domínio tem SHA-256
  `f8dda7e89e11a49fe01e97433bb38297193466cfc01c104fd6f54a441d7b90fc`,
  idêntico ao build local aprovado, e contém a nova RPC, o erro de hierarquia
  e a URL oficial do backend PROD. A tentativa de comparação direta do asset
  no endereço `pages.dev` recebeu 403; não foi contornada. Identificação do
  deployment foi obtida pelo pipeline e o asset do domínio foi lido no navegador.
- Conferência final somente leitura em `2026-11-03T16:33:04Z`: mesmas contagens
  de negócio, zero vínculos órfãos ou entre proprietários e vínculos históricos
  da Sprint 72 concluída presentes no banco. Isto confirma preservação no banco;
  **não homologa a leitura autenticada pela RPC nem pela interface**.
- **Estado ao fim da janela inicial:** API pública mantida na porta sem serviço
  8089, bloqueando leituras e escritas pelo domínio. Backend novo saudável
  internamente; configuração de réplicas original `iad: 1` preservada.
  O responsável informou estar remoto pelo celular, sem sessão/token AAL2 no
  computador, e determinou continuar somente checks sem credenciais. Não foram
  extraídos tokens, contornado MFA ou criadas credenciais de teste. A verificação
  positiva de AAL2/RPCs e a liberação do acesso público ficaram pendentes nessa etapa.
  O registro SSH temporário criado para a verificação interna foi removido;
  a chave local existente foi preservada.

Após múltiplos vínculos, conservar backend compatível; em falha manter o
bloqueio público e corrigir adiante. Nenhum rollback destrutivo ou restore
automático está autorizado. Offsite/chave externa do backup continuam pendentes.

### Liberação pública autorizada para homologação no celular — 03/11/2026

Por autorização explícita posterior do responsável, a API foi liberada para
homologação manual diretamente em `https://temdas.com.br`, com login/MFA normal
no celular. A homologação AAL2 permanece pendente e não é declarada aprovada.

Antes da liberação, Railway confirmou o mesmo deployment
`d21f891d-50e8-44a7-b5e8-30ed513b1496` em `SUCCESS`, uma réplica saudável,
zero issues e nenhum trabalho pendente. Healthcheck interno configurado em
`/readyz`, sem erros críticos nos logs consultados. O asset atual do frontend
continua com o SHA-256 aprovado e o contrato da RPC nova/backend PROD.

Alterada exclusivamente a porta pública do domínio
`temdas-backend-production.up.railway.app`: **8089 → 8080**. Read-back confirmou
a porta, o deployment e a configuração de réplicas originais. Nenhum novo SSH,
credencial, migration, build, teste de suíte, deploy ou mutação de negócio.

Checks públicos em `2026-11-03T16:40:23Z`:

- HTTPS `/readyz`: 200; `https://temdas.com.br/`: 200.
- POST de leitura `listarSprints` e `listarContextoDemandas` sem token:
  HTTP 400 com `AuthException/tokenMissing`, conforme o contrato de autenticação.
- CORS das RPCs permite a origem do frontend; OPTIONS `/sprint`: 200,
  POST e headers `Content-Type`/`Authorization` permitidos.

**API pública e escritas liberadas para a homologação manual autorizada.**
O responsável deve recarregar `temdas.com.br` no celular, entrar com login/MFA,
consultar Sprints e conferir o histórico da Sprint 72 nas Demandas existentes,
sem criar ou alterar dados para testar. Não é necessário fornecer ou extrair token.
Registrar depois o resultado da leitura autenticada e da navegação no celular.
Em falha crítica de operação, restaurar somente o domínio para 8089 e reportar;
não executar rollback de backend/schema ou restauração automática.

### Atualização posterior — vinculação em lote e timeout

Em 03/11/2026 foi autorizada e concluída a publicação de `9d5b3af`, com
otimização da RPC de lote, timeout compartilhado de 60 s e reconciliação por
leitura após timeout. Railway `2fab0925` e Cloudflare `c68e8427` concluídos,
API pública mantida em 8080. Nenhuma nova migration ou vinculação de teste em
PROD. Procedimento, resultados e limites em
[vinculação em lote](spr-p2-01-vinculacao-lote.md).
