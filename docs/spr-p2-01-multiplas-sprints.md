# SPR-P2-01 — múltiplas Sprints por Demanda

Implementação de 03/11/2026, na branch `feat/spr-p2-01-multiplas-sprints`,
a partir de `main` em `0bcb62d`. Sem integração, push ou publicação em PROD.

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

## Migration preparada, não aplicada

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
`migration.sql`; o caminho incremental precisa de ensaio e aprovação separados
antes da publicação.

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
consolidados em `docs/evidencias-spr-p2-01.json`. O build release é local e usa as definições públicas oficiais, sem publicação.
Foram executados dois builds locais: o segundo foi autorizado separadamente
pelo responsável após o ajuste final da largura de Sprints em lista/cards.
Os testes desse ajuste usam a fonte Inter real e verificam texto sem recorte.

## Publicação coordenada — proposta para aprovação separada

A revisão do contrato identifica dependência obrigatória **migration → backend
→ frontend**. O frontend novo não funciona com backend antigo por não existir a
RPC de contexto. Endpoints anteriores foram mantidos; o enum ganhou
`hierarquiaSprintInvalida`. Não promover o frontend isoladamente.

1. Aprovar e ensaiar o caminho incremental em clone isolado, conferindo baseline,
   backup, preservação de vínculos/horas, objetos e rollback transacional.
   Nenhum ensaio com dados de PROD ou aplicação de migration foi autorizado aqui.
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
