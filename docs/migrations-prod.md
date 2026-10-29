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
   A única exceção revisada é a correção Sprint descrita abaixo, vinculada à
   versão, aos hashes dos cinco artefatos e ao estado inicial auditado.
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
    Para a correção específica, admitir apenas o baseline incompleto exato e
    exigir os dois objetos corretos ao final, sem outra alteração de schema.
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
TEMDAS_MIGRATION_DOCKER_TESTS=1 TEMDAS_MIGRATION_BACKUP_TESTS=1 python3 -m unittest discover -s scripts/migrations -v
git diff --check
```

Sem opt-in, os testes Docker ficam **skipped**, o que não satisfaz o gate. Os
testes reais usam apenas dados sintéticos em seu próprio container PG17: migration
aditiva, SQL inválido com rollback, bloqueio destrutivo antes da execução,
preservação de dados/histórico, divergência do target, isolamento e regras reais
de exclusão/uma Sprint ativa por proprietário. Os testes unitários cobrem falha
Docker, concorrência, SQL perigoso/malformado, backup ausente/antigo/futuro,
segunda cópia inválida, identidade de cleanup e logs sem saída sensível.
`TEMDAS_MIGRATION_BACKUP_TESTS=1` habilita explicitamente o teste do backup
existente com idade <=24h e cópia F: verificada; não coleta backup novo. Ele
exige o snapshot anterior à correção, aplica somente no clone e testa conflitos
usando dados sintéticos revertidos por rollback. Depois de atualizar PROD, esse
cenário exige conservar um baseline anterior dedicado e revisado; não deve ser
interpretado como autorização para voltar o histórico de um banco existente.

## Resultado inicial, antes da correção

O ensaio do backup existente confirmou integridade nas duas cópias, restauração
em PG17.11, inventário idêntico ao manifesto e nenhuma migration pendente no
snapshot diante do registro então vigente. O baseline, porém, não contém os
dois objetos customizados de Sprint esperados. A rotina retorna
`baseline_sprint_custom_objects_missing` e bloqueia aprovação. Isso é uma
observação **do snapshot**, não uma consulta atual ao Supabase. Nenhum objeto foi
criado/corrigido em PROD ou DEV. A investigação posterior e o ensaio da correção
estão registrados abaixo; esse resultado inicial não deve ser confundido com o
resultado do novo ensaio.

## Correção Sprint preparada em 29/10/2026

Versão: `20261029113025000-sprint-integrity`. A definição completa de
`convite-cooldown` omitiu os dois objetos presentes na versão anterior. Seu SQL
incremental não os remove. A criação inicial pela definição incompleta explica
o estado observado, mas não comprova qual comando histórico foi executado.

A nova migration instala `btree_gist` 1.7 em `extensions`, cria o índice único
parcial e a exclusion constraint descritos no [schema Sprint](schema-sprints-serverpod.md)
e atualiza somente o módulo TEMDAS. A definição completa também contém esses
objetos. Nenhuma migration histórica foi alterada.

O gate permite ensaiar **somente essa versão**, isoladamente, com os cinco
artefatos e SHA-256 fixados em `SPRINT_ARTIFACTS`. Os bytes executados são os
mesmos que foram verificados. Alterar SQL/JSON, incluir arquivo extra, renomear
a migration ou agrupá-la com outra impede o uso dessa exceção. O analisador SQL
geral continua bloqueando comandos privilegiados e blocos `DO` desconhecidos.

O preflight exige histórico cooldown/serverpod conhecido, schema gerenciado
compatível, os dois índices e as duas constraints originais de Sprint, ausência
dos dois objetos customizados e de `btree_gist`. O resultado exige predicados,
elementos, métodos e propriedades exatos dos objetos novos, extensão no schema e
versão esperados, histórico correto, dados preservados e nenhuma outra alteração
nos objetos inventariados. `production_authorized=false` permanece obrigatório.

### Evidências e pré-requisitos Supabase

Foram aprovados 53 testes de migrations, incluindo instalação limpa, upgrade do
backup PROD existente em PostgreSQL 17.11 isolado, conflitos, isolamento entre
proprietários, rollback e restauração de dump contendo os novos objetos. Também
passaram 26 testes de backup e dois testes Dart de schema/target; Dart analyze
não apresentou problemas nos arquivos verificados. Contagens e hashes do clone
foram preservados, exceto a atualização esperada do histórico Serverpod. Os
containers e volumes originais permaneceram inalterados.

A consulta PROD somente leitura de 29/10 confirmou PostgreSQL 17.11,
`btree_gist` 1.7 disponível e trusted, schema `extensions` existente, permissões
CREATE no banco e CREATE/USAGE no schema e propriedade suficiente sobre Sprint
e histórico. O teste local com role sem superuser e esses privilégios passou;
sem CREATE no banco houve rejeição e rollback. Não foi executado DDL remoto.
Docker não reproduz todos os serviços/event triggers da plataforma Supabase:
reconferir extensão, permissões, histórico e integridade atuais antes da aplicação.
Qualquer divergência bloqueia a execução até nova análise.

### Locks, aprovação e recuperação

A transação usa `ACCESS EXCLUSIVE` em Sprint e `SHARE ROW EXCLUSIVE` no histórico.
O lock de Sprint bloqueia inclusive leituras até o fim da transação. O limite de
5s é de **espera por lock**, não da duração total do bloqueio; o statement timeout
de 60s vale por comando. Escolher janela de baixo tráfego e verificar transações
longas. O tamanho pequeno do clone não garante o tempo de execução em PROD.

Antes de solicitar aprovação separada, repetir o ensaio com backup <=24h e cópia
F: verificada, reconferir as precondições atuais e registrar versão, hashes,
backend compatível, relatório e janela. Usar o SQL incremental revisado;
`definition.sql` é apenas para banco vazio. Não reativar Pre-Deploy nem aplicar
esta versão por inicialização normal do backend. Nenhum deploy é necessário
para preparar os arquivos, e nenhum foi executado nesta tarefa.

Falha antes do COMMIT desfaz extensão/schema novos, índice, constraint e alteração
de histórico. Em perda de conexão com resultado do COMMIT desconhecido, inspecionar
schema/histórico antes de qualquer repetição. Depois do COMMIT, preferir correção
aditiva revisada; não remover proteções nem voltar o histórico automaticamente.
Restauração real é último recurso, exige autorização própria e plano para
preservar gravações posteriores ao backup.

O restaurador agora prepara exclusivamente a dependência `btree_gist` conhecida
em um destino descartável antes do restore filtrado por schema. A coleta diária
e o script instalado do Agendador não foram modificados. Para restaurar backups
posteriores à correção, usar a versão do repositório conforme o
[runbook de backup](backup-restauracao-prod.md); a cópia instalada antiga não
inclui esse novo suporte.

## Aplicação autorizada em PROD — 29/10/2026

A migration `20261029113025000-sprint-integrity` foi aplicada exclusivamente
no Supabase PROD `vberbygddnootjcbkajc`, após autorização humana específica.
Commit dos artefatos: `f4ef19d09fb0b59bf2ba21053d7a9dbe8e4552ca`.
O SQL incremental executado tinha SHA-256:

```text
e46a7e8013f1c51069c3e31a5faf1ff0a6f8d3b7c46028181f199822a8f8e230
```

### Preflight e ensaio

- Artefatos e código conferidos contra o commit autorizado; nenhuma alteração
  rastreada pendente. Somente essa migration estava pendente no histórico PROD.
- Conexão direta IPv6, PostgreSQL 17.11, `sslmode=verify-full`, certificado/hostname
  verificados pelo cliente e TLS confirmado no servidor. Preflight em transação
  repeatable read/read-only, com statement timeout de 15s e lock timeout de 2s.
- Baseline cooldown, ambos os objetos e extensão ausentes; uma Sprint, nenhum
  proprietário ausente, período inválido, par sobreposto ou múltiplas ativas.
- `btree_gist` 1.7 trusted/relocatable disponível; permissões de banco/schema e
  propriedade das duas tabelas conferidas. Zero transações com mais de 30s,
  transações preparadas ou locks de outras sessões em Sprint/histórico na amostra.
- Backup de `2026-10-29T01:15:02.123551+00:00`, aproximadamente 11h no preflight,
  íntegro e com segunda cópia em F: verificada. SHA-256 do arquivo criptografado:

```text
fc2db2111ac5a9157a3bdb41ccdfdbc1f0a4c47a12d0626989918d63c211ed43
```

O ensaio PROD-02 foi repetido com esse backup: restauração em PostgreSQL 17.11
descartável, schema e dados iguais ao manifesto, aplicação apenas no clone e
validações finais aprovadas. Containers/volumes originais permaneceram iguais.
O relatório continuou com `production_authorized=false`; a autorização específica
foi conferida separadamente, sem alterar nem contornar esse controle global.

Backend publicado: Serverpod 3.4.11, deployment Railway
`29a80d3b-9c4d-40fa-9fc8-e9fdec8e90b7`, `SUCCESS`. O SQL é aditivo, preserva
colunas/relacionamentos consumidos pelo backend e restaura os dois índices
previstos no target customizado. Logs de inicialização confirmaram migrations
automáticas desabilitadas e Pre-Deploy permaneceu vazio.

### Execução e resultado

Uma única tentativa entre `2026-10-29T12:32:32.770743+00:00` e
`2026-10-29T12:32:40.481231+00:00` (09:32 em Brasília, incluindo verificações).
Somente os bytes revisados de `migration.sql` foram enviados ao psql; não foi
executado `definition.sql`. A transação, os prechecks e os timeouts do artefato
foram preservados. psql retornou zero e o COMMIT foi confirmado por nova consulta
somente leitura. Não houve repetição, repair, outra migration ou rollback.

| Verificação posterior | Resultado |
| --- | --- |
| Histórico TEMDAS | `20261029113025000-sprint-integrity` |
| Histórico módulo serverpod | `20260129180959368`, preservado |
| Extensão | `btree_gist` 1.7 em `extensions` |
| Índice único parcial | Nome, método, unicidade, predicado e elementos corretos; válido/ready |
| Exclusion constraint | Nome, método GiST, predicado e elementos corretos; validada, imediata/não deferrable |
| Demais objetos inventariados | Preservados: colunas, índices, constraints, views, funções, policies e triggers |
| Dados e relacionamentos | Contagens/hashes de todas as tabelas originais preservados, exceto atualização esperada de histórico; Sprint continua com uma linha e sem proprietário órfão |
| `/readyz`, `/livez`, `/startupz` | HTTP 200 |
| `/greeting/hello` | HTTP 200 |
| `/sprint/listarSprints` e `/auth/me` sem JWT | HTTP 400 com `AuthException` / `tokenMissing`, sem erro de schema |
| Railway | Mesmo deployment `SUCCESS`, sem mudanças staged ou novo deploy |

Nenhum registro novo de runtime foi retornado na consulta de logs posterior à
aplicação; não houve erro de schema nas respostas HTTP. Essa observação não é uma
prova de ausência de todos os erros possíveis. O aviso anterior de inicialização
`Invalid serviceSecret in password file, Insights server disabled.` é independente
da migration e permaneceu fora do escopo. Não foram criados usuários/sessões nem
obtido JWT pessoal para repetir consultas de negócio autenticadas; esse caminho
não foi homologado novamente nesta etapa. Não foram feitos testes conflitantes
ou de escrita em PROD.

### Situação operacional e pendências

A divergência de Sprint está resolvida. O PROD-02 foi homologado operacionalmente
neste ciclo: backup/F:, ensaio isolado, revisão, autorização separada, aplicação
única e conferência real do resultado. Isso não autoriza próximas migrations.
Cada aplicação futura exige novamente todos os gates e aprovação humana própria.
DEV, dados de negócio, volumes existentes e configurações Railway/Cloudflare
permaneceram inalterados; não houve deploy.

A instalação local antiga de `~/.local/share/temdas-backup/bin/backup.py` ainda
não contém `restore_extension_sql`. A coleta/agendamento de backup não precisa
dessa função e não foi alterada. Para restauração de backups posteriores à
correção, usar o restaurador atualizado do checkout conforme PROD-01. Sincronizar
a cópia instalada é uma pendência operacional separada, não executada aqui.
O backup utilizado antecede a correção: a próxima coleta agendada deve registrar
o novo histórico/objetos, com verificação da cópia F:. Não foi disparado backup
adicional nesta tarefa. Antes de qualquer nova migration, exigir backup atualizado
e ensaio correspondente ao schema então vigente.

**Encerramento posterior, 29/10/2026:** a pendência do restaurador foi resolvida
na etapa específica autorizada. Cópia instalada sincronizada, coleta manual
posterior à migration e restauração isolada diretamente do F: aprovadas, com
histórico e dois objetos Sprint corretos, além de `btree_gist` 1.7. Configuração,
credenciais, chave e definição do agendamento preservadas. Evidências no
[encerramento PROD-01](backup-restauracao-prod.md#encerramento-operacional--29102026).
Esse encerramento não executou migrations nem alterou PROD/DEV.

O `pubspec.yaml` do servidor ainda contém um atalho local `serverpod run start`
com `--apply-migrations`. Ele não foi executado nem alterado nesta tarefa e não é
usado pelo processo PROD-02. Não utilizá-lo com credenciais ou configuração PROD;
isso é independente do Pre-Deploy removido do Railway.

## Referências

- [Serverpod 3.4 — Migrations](https://docs.serverpod.dev/3.4.0/concepts/database/migrations)
- Implementação instalada 3.4.11: `migration_manager.dart`, `_loadMigrationSQL` e
  `_migrateToLatestModule` (registro conhecido + execução do SQL gerado).
- [PostgreSQL 17 — SQL dump e restore](https://www.postgresql.org/docs/17/backup-dump.html)
- [PostgreSQL 17 — btree_gist](https://www.postgresql.org/docs/17/btree-gist.html)
- [PostgreSQL 17 — CREATE EXTENSION](https://www.postgresql.org/docs/17/sql-createextension.html)
- [Supabase — extensões](https://supabase.com/docs/guides/database/extensions)
- [Docker — container run](https://docs.docker.com/reference/cli/docker/container/run/)
- [Supabase — backup e restore](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)
- [Backup PROD-01](backup-restauracao-prod.md) e
  [schema customizado de Sprint](schema-sprints-serverpod.md).
