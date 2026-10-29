# PROD-02 — Validação e aprovação de migrations

O ensaio é local e semiautomatizado. **Não há comando para aplicar migrations em
PROD neste script.** Sucesso local não autoriza alteração de produção. A aprovação
humana será explícita, separada e vinculada ao SQL e backend efetivamente testados.

## Infraestrutura inspecionada

Compose: `serverpod/temdas_backend/temdas_backend_server/docker-compose.yaml`.

| Serviço/container | Imagem e versão declarada | Porta local | Volume original |
| --- | --- | --- | --- |
| `temdas_backend_server-postgres-1` | `pgvector/pgvector:pg16`, PostgreSQL 16.15 | 8090 | `temdas_backend_server_temdas_backend_data` |
| `temdas_backend_server-postgres_test-1` | mesma imagem/versão | 9090 | `temdas_backend_server_temdas_backend_test_data` |

Os dois containers estavam parados. Os bancos configurados são `temdas_backend`
e `temdas_backend_test`; os catálogos internos não foram consultados nem os
containers iniciados. Não se presume que sejam os únicos bancos presentes.
Os serviços Redis existentes também são preservados.

PROD usa PostgreSQL 17.11. Não se restaura seu dump em PG16 nem se atualiza a
infraestrutura de desenvolvimento para realizar este ensaio. A rotina usa a
imagem oficial `postgres:17.11-bookworm`, fixada por digest no script, e exige
`server_version_num=170011`. Mudanças de versão exigem revisão e novos testes.

## Executar uma validação

No diretório raiz do repositório:

```bash
python3 scripts/migrations/validate.py
```

Pré-requisitos: Python 3, OpenSSL, acesso ao daemon Docker local, ferramentas
PG17 já preparadas pelo PROD-01, configuração privada de backup e disco F:
montado com acesso de leitura. O script não usa sudo nem altera permissões.
No Codex, solicitar aprovação pontual se o sandbox bloquear Docker ou F:.

A configuração padrão é `~/.config/temdas-backup/config.json`. O argumento
opcional `--config` recebe esse mesmo formato privado. O projeto/host precisam
ser PROD; **isso identifica a origem do backup, não abre conexão com ela**.
`pgpass`, credenciais de Supabase/Railway e URLs de conexão não são utilizados.
Não há argumento para escolher um banco de destino existente.

A saída JSON contém somente categorias, versões, hashes e resultados. Guardar
o relatório fora do Git, por exemplo em uma pasta privada de evidências. Não
copiar dump, inventários de dados, config ou chave de recuperação ao repositório.

## Proteções e etapas

1. Bloquear concorrência com backup/retenção e com outro ensaio/teste Docker.
2. Exigir backup mais recente com idade entre zero e 24h, identidade da instalação
   e SHA-256/tamanho corretos. Verificar também índice e conteúdo da segunda cópia
   em `F:\TEMDAS\backups\`, inclusive montagem real do disco; nenhuma cópia nova é
   feita e nenhum backup é consultado remotamente.
3. Descriptografar em diretório temporário Linux privado, reutilizando os helpers
   PROD-01. Conferir autenticação CMS, membros do arquivo, hashes internos, projeto
   e versão. A chave fica fora do Docker e nunca aparece em argumentos como valor.
4. Criar container com nome aleatório, ID e label de propriedade. Não publicar
   portas, montar pastas do host ou conectar a redes. Usar `--network=none`, dados
   em tmpfs, limite de memória/CPU, usuário `postgres`, sem capabilities adicionais,
   sem log persistente. O `VOLUME` padrão da imagem também é coberto por tmpfs para
   não criar volumes anônimos. Conexões ocorrem por socket **dentro** do container.
5. Restaurar o backup existente nos schemas selecionados pelo PROD-01: `public`,
   `auth`, `storage`, `supabase_migrations`. Criar apenas roles NOLOGIN sem atributos
   administrativos para resolver referências. Conferir inventário restaurado
   inteiro contra o manifesto: dados, tabelas, colunas, índices, constraints,
   funções, triggers, views e policies. Não executar atributos/grants de roles
   gerenciadas fora do Supabase.
6. Ler `public.serverpod_migrations` **do clone** e o registro local ordenado,
   ignorando seu cabeçalho gerado e exigindo correspondência com os diretórios
   ordenados que o runtime Serverpod 3.4.11 enumera.
   Versão desconhecida ou ausente bloqueia; não inicializar silenciosamente um
   baseline vazio. Validar incrementalmente apenas versões posteriores.
7. Fazer análise conservadora do SQL antes de executá-lo. Exigir os wrappers
   `BEGIN`/`COMMIT` gerados pelo Serverpod e permitir somente um subconjunto aditivo
   conhecido, além do upsert exato do histórico. DROP, TRUNCATE, DELETE, alteração
   de tipo, SET NOT NULL, comandos privilegiados, psql, código dinâmico e expressões
   desconhecidas bloqueiam. Comentários aninhados e strings são tratados sem
   confundi-los com comandos. SQL bloqueado exige análise específica e teste
   dedicado; não existe flag para ignorar o bloqueio.
8. Executar os arquivos SQL transacionais na ordem validada, com lock timeout
   de 5s e statement timeout de 60s. O Serverpod 3.4.11 usa esse mesmo SQL e ordenação;
   o aplicativo não é iniciado e nenhuma configuração DEV/PROD é carregada.
9. Verificar histórico de aplicação e módulos, colunas, tipos suportados,
   nullability, defaults, presença de índices/FKs, constraints validadas e dados
   originais por contagem/hash projetando as colunas anteriores. Não ignorar
   alteração inesperada de dados. Backfills precisam de expectativas específicas;
   não são aprovados automaticamente por esta rotina.
10. Exigir os objetos customizados de Sprint do backend atual e preservar todas
    as definições de índices, constraints e triggers de Sprint existentes no
    baseline. Os três objetos do antigo bucket sem proprietário foram removidos
    deliberadamente em `20261007002904636-ownership-required`; hoje os dois
    customizados esperados são `sprints_uma_ativa_por_usuario_idx` e
    `sprints_periodos_sem_sobreposicao_por_usuario`. Não reparar nem recriar
    automaticamente objetos faltantes.
11. Remover somente o container cujo ID/nome/label/imagem conferem. Comparar
    fingerprints dos metadados de containers/volumes originais antes/depois. Não
    iniciar, consultar ou executar SQL nos bancos originais. Apagar temporários
    privados ao terminar. Nunca usar `compose down -v`, prune ou rm de volumes.

Interrupções normais e erros limpam o container. Encerramento forçado do processo
ou do WSL pode deixar um container temporário; seus dados estão em tmpfs. Nesse
caso, inspecionar ID, label e imagem antes de remoção manual individual. Não usar
remoção por prefixo, prune ou comandos gerais de limpeza. A imagem baixada é cache
Docker e pode permanecer; não é um volume de dados.

## Gate obrigatório antes de PROD

Mesmo `rehearsal_passed_requires_review` retorna `production_authorized=false`.
Antes de pedir autorização de execução real:

- Exigir todos os testes aprovados e ausência de bloqueios no relatório.
- Reconferir backup <=24h e segunda cópia íntegra imediatamente antes da janela.
- Comparar histórico **atual** de PROD em leitura com o snapshot; o ensaio offline
  não atesta que PROD permaneceu igual desde o backup.
- Revisar todo `migration.sql`, `definition.sql`, JSONs, dependências e hashes.
  Conferir criação limpa e upgrade; o gerador Serverpod não preserva sozinho SQL
  customizado de Sprint no `definition.sql` de novas migrations.
- Avaliar compatibilidade do backend atual e novo com ambos os schemas. Preferir
  mudanças expansivas compatíveis; não remover coluna utilizada pelo backend
  ainda em execução. O fingerprint do backend/migrations vincula as evidências;
  qualquer mudança exige repetir o ensaio.
- Avaliar plano de locks, volume de dados, duração, transações longas e janela de
  manutenção. Ausência de contenção no clone não prova ausência em PROD.
- Confirmar tipos/defaults especiais, definições completas de índices e FKs,
  extensões, grants/owners, Auth/Storage/Realtime e outros serviços Supabase. O
  inventário do clone não equivale à plataforma gerenciada. Qualquer dependência
  não reproduzida deve ficar como bloqueio, com validação específica pendente.
- Documentar recuperação: erro antes do COMMIT permite rollback transacional;
  após COMMIT, não presumir down-migration nem rollback de código suficiente.
  Preparar correção expansiva ou restauração coordenada a partir do backup
  verificado, considerando gravações posteriores e indisponibilidade. Uma
  restauração real exige autorização separada; não sobrescrever PROD/DEV aqui.
- Registrar aprovação humana explícita do responsável, versões, hashes do SQL,
  backend, backup e relatório, janela e plano de recuperação. Não aceitar uma
  aprovação genérica anterior como autorização da próxima migration.

A aplicação real será uma etapa operacional separada. O Serverpod oferece
`--role maintenance --apply-migrations`, mas estes argumentos **não** estão em
scripts de deploy, execução normal ou automação de PROD-02. Não reativar migrations
automáticas no Railway. Este trabalho não altera o Railway nem faz deploy.

## Testes e reprodução

Executar sequencialmente, sem outro ensaio Docker concorrente:

```bash
python3 -m unittest discover -s scripts/backup -v
TEMDAS_MIGRATION_DOCKER_TESTS=1 python3 -m unittest discover -s scripts/migrations -v
git diff --check
```

Sem opt-in, os testes Docker ficam **skipped**, o que não satisfaz o gate. Os
testes reais usam apenas dados sintéticos em seu próprio container PG17: migration
aditiva, SQL inválido com rollback, bloqueio destrutivo antes da execução,
preservação de dados/histórico, divergência do target, isolamento e regras reais
de exclusão/uma Sprint ativa por proprietário. Os testes unitários cobrem falha
Docker, concorrência, SQL perigoso/malformado, backup ausente/antigo/futuro,
segunda cópia inválida, identidade de cleanup e logs sem saída sensível.

## Resultado inicial e limitação registrada

O ensaio do backup existente confirmou integridade nas duas cópias, restauração
em PG17.11, inventário idêntico ao manifesto e nenhuma migration pendente no
snapshot diante do registro atual. O baseline, porém, não contém os
dois objetos customizados de Sprint esperados. A rotina retorna
`baseline_sprint_custom_objects_missing` e bloqueia aprovação. Isso é uma
observação **do snapshot**, não uma consulta atual ao Supabase. Nenhum objeto foi
criado/corrigido em PROD ou DEV. É necessária investigação somente leitura do
schema atual e do histórico antes de propor qualquer correção separada.

O `pubspec.yaml` do servidor ainda contém um atalho local `serverpod run start`
com `--apply-migrations`. Ele não foi executado nem alterado nesta tarefa e não é
usado pelo processo PROD-02. Não utilizá-lo com credenciais ou configuração PROD;
isso é independente do Pre-Deploy removido do Railway.

## Referências

- [Serverpod 3.4 — Migrations](https://docs.serverpod.dev/3.4.0/concepts/database/migrations)
- Implementação instalada 3.4.11: `migration_manager.dart`, `_loadMigrationSQL` e
  `_migrateToLatestModule` (registro conhecido + execução do SQL gerado).
- [PostgreSQL 17 — SQL dump e restore](https://www.postgresql.org/docs/17/backup-dump.html)
- [Docker — container run](https://docs.docker.com/reference/cli/docker/container/run/)
- [Supabase — backup e restore](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)
- [Backup PROD-01](backup-restauracao-prod.md) e
  [schema customizado de Sprint](schema-sprints-serverpod.md).
