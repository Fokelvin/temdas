# PROD-01 — Backup e restauração do TEMDAS

Estado: **parcial**, em 28/10/2026 (America/Sao_Paulo). Backup criptografado e
restauração SQL local comprovados; proteção externa e cópia externa da chave de
recuperação pendentes. Não considerar recuperação completa da plataforma Supabase
ou operação sem login Windows como validadas.

## Decisão e backup nativo

PROD é `vberbygddnootjcbkajc`; nenhum comando acessa o DEV. A Management API
retornou zero backups disponíveis e PITR desativado. O contexto aprovado informa
Supabase Free; o token disponível permite ler o projeto, mas não confirmou o plano
no faturamento (consulta de organizações vazia; endpoints de assinatura sem acesso
utilizável). Esta limitação não altera o fato de não haver backup nativo recuperável
na lista consultada.

A documentação oficial oferece backups diários no Pro/Team/Enterprise, com
retenção de 7/14/até 30 dias. Pro parte de US$25/mês; nada foi contratado ou
habilitado. Free deve exportar dados e manter cópia externa. Nenhum restore nativo
foi executado em projeto existente. A alternativa sem serviço pago é local WSL.

## Arquitetura e arquivos privados

- PostgreSQL PROD 17.11; ferramentas oficiais PGDG 17.11 extraídas para o usuário,
  sem sudo, instalação global, Docker ou serviço PostgreSQL persistente.
- Conexão direta IPv6, porta 5432, `sslmode=verify-full`, CA/hostname validados.
- Senha existente obtida sem exibir seu valor; consumidores Railway e Supabase
  permanecem inalterados. O job não depende da CLI Railway nem de token Management.
- Sessões de origem com `default_transaction_read_only=on`; snapshot MVCC exportado
  e compartilhado com `pg_dump`. Não é um novo usuário de banco com privilégios
  reduzidos: a credencial continua sendo a de `postgres`, protegida localmente.
- Dump custom PostgreSQL com gzip nível 6; arquivo completo, não apenas `public`.
  Roles são exportadas separadamente, sem hashes de senhas de roles PostgreSQL.
- Empacotamento com manifesto criptografado; OpenSSL CMS RSA-3072/AES-256-GCM.
  O job diário usa apenas o certificado público de recuperação.

| Finalidade | Local Linux, fora do Git |
| --- | --- |
| Backups `.cms`, índice e logs sanitizados | `/home/kelvin/.local/share/temdas-backup/` |
| Script instalado estável | `/home/kelvin/.local/share/temdas-backup/bin/backup.py` |
| Ferramentas 17 | `/home/kelvin/.local/share/temdas-backup/tools/` |
| Configuração, CA e `pgpass` | `/home/kelvin/.config/temdas-backup/` |
| Chave privada e certificado de recuperação | `/home/kelvin/.config/temdas-backup/recovery/` |

Diretórios privados 0700, arquivos privados 0600 e `umask 077`. Chave privada em
diretório separado dos dumps, não enviada à segunda cópia automaticamente.
**Separação de diretórios no mesmo PC não protege contra perda física ou invasão
da conta Linux.** Guardar chave e cópia de recuperação da configuração em meio
seguro externo/separado exige intervenção do responsável. Nunca enviar pelo chat.
Uma perda da chave torna os backups criptografados irrecuperáveis.

Nenhum dump, senha, chave, log de dados ou arquivo de configuração real deve ser
adicionado ao Git. `scripts/backup/.gitignore` acrescenta uma proteção preventiva;
os caminhos reais permanecem fora do checkout. Não versionar `state.json`.

## Execução, integridade e retenção

Comandos locais (configuração privada já preparada neste ambiente):

```sh
python3 scripts/backup/backup.py run
python3 scripts/backup/backup.py status
python3 scripts/backup/backup.py restore-check
python3 -m unittest discover -s scripts/backup -p 'test_*.py' -v
```

`run --force` cria uma nova cópia para validações autorizadas; não é o comando da
rotina diária. `prepare-tools.py` reproduz a extração de pacotes assinados PGDG
para Ubuntu 24.04; recusa substituir uma instalação existente. Revisar atualização
de ferramentas antes de trocar uma versão em uso. `config.example.json` contém
somente caminhos e metadados públicos, sem senha.

O dump precisa ser não vazio, ter cabeçalho válido e ser integralmente lido por
`pg_restore --file=/dev/null` antes de ser criptografado. Arquivos parciais nunca
entram no índice. Publicação atômica, SHA-256 do arquivo criptografado, manifesto
interno e autenticação GCM detectam corrupção; restauração exige também checksum
do dump/roles e comparação dos dados. Restaurar somente arquivos de origem
confiável: um dump SQL pode conter código executável.

Retenção local: todos os backups dos últimos **7 dias com cópias válidas**, mais
uma cópia por semana ISO dentre as **4 semanas com cópias**, sempre preservando a
mais recente. Reexecuções manuais do mesmo dia são preservadas. Sem histórico
suficiente, a retenção não inventa pontos de recuperação. Não há exclusão de
arquivos preexistentes/desconhecidos; apenas arquivos indexados desta instalação
podem ser removidos, e só depois da publicação de uma nova cópia válida.
A segunda cópia não tem exclusão automática. Há verificação mínima de espaço
livre (1 GiB); o espaço inspecionado no WSL foi amplamente suficiente. Reavaliar
capacidade conforme o banco crescer.

Lock Linux não bloqueante impede concorrência; o Agendador também usa IgnoreNew.
Logs incluem apenas evento, UTC, duração, tamanho, atraso e contagem de tabelas.
Falhas geram códigos fixos, nunca stderr bruto, SQL com dados ou exceções livres.
Datas nos nomes e no índice são UTC. Sem rede/IPv6 o job falha sem fallback TLS
inseguro. `status` verifica os hashes dos arquivos locais e sinaliza atraso acima
de 36h; isso não é um alerta externo nem garante RPO quando o PC está desligado.

## Agendamento Windows/WSL

Tarefa `TEMDAS-PROD-Backup`, **03:00 no fuso do Windows**, mais gatilho ao login,
`StartWhenAvailable`, três retries a cada 15 minutos, limite de duas horas,
execução com privilégio limitado. A ação chama `wsl.exe --distribution
Ubuntu-24.04 --user kelvin --exec /usr/bin/python3 .../bin/backup.py run`.
Portanto não depende de cron rodando numa distribuição já aberta. Um job de
validação temporário executou um **backup real** pelo Task Scheduler e terminou
com resultado 0; a tarefa temporária foi removida, preservando a diária.

O principal usa InteractiveToken: **precisa que o usuário esteja logado no
Windows**. Retoma ao próximo login; não promete execução com PC desligado,
usuário desconectado ou distribuição inacessível. O teste não encerrou a
distribuição que hospeda o agente para simular cold start. Dias perdidos entre
cópias são registrados no próximo sucesso, sem alegar cobertura retroativa.

Para registrar ou conferir a tarefa, executar no PowerShell Windows o script
`register-task.ps1`. `-Verify` executa uma nova cópia real através de uma tarefa
temporária; não substitui uma tarefa diária existente com definição divergente.
Não há senha Windows ou senha PostgreSQL na definição da tarefa.

Após revisar atualizações do código, copiar a versão validada para o caminho
instalado com permissões 0700; o agendamento não executa um checkout Git mutável.

## Teste de restauração e cobertura comprovada

Cada teste cria um cluster PostgreSQL 17 em diretório temporário 0700, com **TCP
desativado**, socket privado, banco novo e role administrativa local exclusiva.
Não aceita uma URL de destino. Nunca restaura em PROD, DEV, PostgreSQL de
integração existente ou porta 9090. O processo é parado e os arquivos
restaurados em plaintext são eliminados ao terminar.

Resultado comprovado: **54 tabelas** de `public`, `auth` e `storage`, com igualdade
de contagens e hashes de todas as linhas, além de definições de colunas, índices,
constraints (incluindo FKs/estado validado), funções, views, políticas e triggers.
A seleção também contempla `supabase_migrations` quando esse schema existir.
O histórico Serverpod em `public.serverpod_migrations` está entre os dados
comparados; não é executada nenhuma migration. O inventário contém cinco
constraints relacionadas a Sprint, que também passaram na comparação. Todos os
objetos SQL customizados existentes nos schemas selecionados permanecem no dump
e na comparação estrutural.

A primeira comparação detectou diferença apenas em métricas numéricas Serverpod:
o PROD usa `extra_float_digits=0`, enquanto o PostgreSQL local tinha outro padrão.
As conexões do backup e do teste passaram a usar representação explícita idêntica
(`extra_float_digits=3`, timezone UTC, DateStyle ISO/YMD), sem alterar valores nem
configuração persistente do banco. Um novo backup passou na comparação integral.
Cópias anteriores foram preservadas; a evidência em `restore-evidence.json`
identifica por checksum qual cópia foi validada.

O teste usa roles locais **NOLOGIN**, não replica privilégios de roles gerenciadas
Supabase. Owners/grants originais continuam no archive e no arquivo de roles, mas
sua aplicação não foi homologada fora da plataforma. A validação estrutural SQL
não equivale a subir Serverpod, Supabase Auth, MFA, Storage ou Realtime localmente.

## Recuperação operacional após incidente (não executada em nuvem)

1. Obter uma cópia criptografada, a chave privada recuperável e o registro de
   checksum de fonte confiável. Preservar os originais e trabalhar em cópia.
2. Em máquina Linux confiável, criar diretório privado com `umask 077`, instalar
   ferramentas 17 compatíveis e verificar a descriptografia GCM. Por exemplo,
   `openssl cms -decrypt -binary -inform DER -in BACKUP.cms -inkey CHAVE_PRIVADA
   -out payload.tar`. Não colocar senha, tokens ou conteúdo da chave no comando.
3. Validar membros do tar e checksums internos antes de extrair; o script faz isso
   automaticamente para a cópia indexada local. O manifesto contém inventário,
   hashes e contexto, sem depender do banco de origem. O teste não precisa da
   senha PROD. Reconstituir o índice a partir de registro confiável se o PC foi perdido.
4. Demonstrar novamente o restore SQL em cluster descartável privado. Não usar
   `--clean`, `DROP DATABASE` nem um banco existente. Avaliar especificamente roles,
   owners, grants, extensões e versões antes de uma recuperação de plataforma.
5. Para voltar ao Supabase, preparar **um projeto novo isolado**, somente após
   autorização específica; alinhar baseline/versão gerenciada e restaurar os
   objetos e dados compatíveis, preservando UUIDs Auth e referências Usuario.
   Não aplicar cegamente `roles.sql` nem recriar schemas internos de um projeto
   ativo: adaptar customizações sobre a baseline suportada pelo Supabase.
6. Reconfigurar, por processo seguro, Auth URLs/templates/SMTP/MFA, API keys,
   signing keys, segredos, infraestrutura, integração Railway e frontend.
   Exportação lógica não comprova portabilidade de chaves criptográficas gerenciadas,
   fatores MFA, Vault ou sessões entre projetos. Validar login/MFA e revogação de
   sessões com procedimento aprovado; nunca desativar a política para facilitar restore.
7. Supabase Storage: `storage.objects` e buckets são **metadados**, não os arquivos.
   Arquivos precisam de cópia separada via Storage API/destino autorizado. Realtime,
   replication slots, Edge Functions, Vault e configurações da plataforma também
   exigem procedimentos específicos. O archive conserva schemas SQL exportáveis,
   mas esses serviços e extensões gerenciadas não foram homologados no PostgreSQL puro.
8. Somente promover uma recuperação depois dos testes de aplicação e segurança;
   nenhum passo deste runbook autoriza sobrescrever PROD/DEV ou executar migrations.

## Segunda cópia e pendências

`external_dir` é opcional e está `null`. Um diretório de destino explicitamente
autorizado pode receber somente os arquivos `.cms`, com conferência de SHA-256;
colisões com conteúdo diferente são rejeitadas. Essa cópia pode apontar para
montagem/sincronização externa previamente autorizada, mas o script não conecta
contas, não cria buckets, não adquire serviços e não transfere chaves privadas.
Não configurar um diretório no mesmo disco e chamar isso de proteção externa.

Pendências para fechar PROD-01: escolher e autorizar destino externo, copiar e
validar recuperação da chave em meio separado, comprovar uma recuperação a partir
dessa segunda cópia e definir se a dependência de login Windows atende ao RPO.
Monitoramento/alerta externo não foi configurado. O roadmap permanece parcial.

## Referências oficiais

- [Backups Supabase e limitações](https://supabase.com/docs/guides/platform/backups)
- [Preços](https://supabase.com/pricing)
- [Backup/restore Supabase](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore)
- [PostgreSQL oficial para Ubuntu](https://www.postgresql.org/download/linux/ubuntu/)
- [pg_dump e consistência](https://www.postgresql.org/docs/17/app-pgdump.html)
- [SSL verify-full](https://www.postgresql.org/docs/17/libpq-ssl.html)
- [Task Scheduler settings](https://learn.microsoft.com/en-us/powershell/module/scheduledtasks/new-scheduledtasksettingsset)
