# Pacote 4 — Validação complementar pré-deploy

Branch `feat/pacote-4-painel-demandas`, preservando `c77bed4` e `d226893`.
Somente dados sintéticos e PostgreSQL descartável. Não houve aplicação em banco
DEV compartilhado/PROD, merge, push ou publicação.

## Migration e volume

A revisão `20261029183226724-pacote4-demandas` permanece **inalterada**, inclusive
SQL, definições JSON, instalação limpa e registro de versões. O SHA-256 do SQL
está no [artefato JSON](pacote4-validacao-complementar.json), comparado byte a
byte com o commit `d226893`.

Ambiente: PostgreSQL 17.11 com imagem fixada por digest; 2 CPUs, limite de 3 GiB
RAM, dados em tmpfs de 2 GiB, sem rede, portas ou volumes persistentes. Os textos
sintéticos usam blocos MD5 distintos por linha/posição, com Unicode, espaços e
quebras, evitando uma única sequência altamente compressível repetida.

| Perfil | Demandas | Log Time | Usuários / Sprints / vínculos | Texto original total¹ | Migration² |
|---|---:|---:|---:|---:|---:|
| A | 10.000 | 40.000 | 20 / 20 / 200 | 48,65 MiB | 1,182 s |
| B | 50.000 | 200.000 | 100 / 100 / 1.000 | 244,23 MiB | 6,438 s |

¹ Soma de descrição e observações legadas; inclui casos nulos, brancos, ambos
preenchidos e textos extensos. Maior descrição original: 262.172 bytes; maior
observação: 262.180 bytes; maior descrição após concatenação: 524.379 bytes.

² Tempo de parede da conexão/execução/commit, excluindo a geração das fixtures.
Dados em memória e hardware local; não é previsão garantida de duração em PROD.

Contagens antes/depois idênticas em ambos os perfis. Conferências por linha:

- Zero descrições divergentes do conteúdo esperado, por hash e tratamento de
  valores nulos; demais campos/observações arquivadas da Demanda preservados.
- Zero registros de Log Time divergentes dos hashes anteriores. Novos campos
  opcionais permanecem nulos em todos os registros antigos.
- Zero anotações artificiais, vínculos órfãos ou divergências de proprietário.
- Hashes de Sprints, vínculos e constraints existentes idênticos antes/depois.
- Revisão confirmada e valores efetivos dentro da transação: `lock_timeout=5s`
  e `statement_timeout=1min`.

O banco, **incluindo tabelas auxiliares do ensaio**, passou de 407.664.307 para
704.231.091 bytes no perfil B. Esse valor não inclui todo o consumo de WAL e não
é uma estimativa isolada do espaço exigido pela migration em produção.

## Timeouts e rollback

| Cenário provocado | Duração | SQLSTATE | Resultado |
|---|---:|---|---|
| Outra conexão segura lock incompatível em Demandas | 5,154 s | `55P03` | Abortou; rollback lógico completo |
| Pausa diagnóstica de 61 s antes do COMMIT | 60,235 s | `57014` | Abortou; rollback lógico completo |

Ambos usaram os limites reais extraídos do SQL, sem reduzi-los para acelerar o
teste. Após cada falha: tabela/colunas novas ausentes, revisão anterior mantida,
hashes e contagens de dados iguais. O crescimento físico observado após rollback
foi de 32.768 e 5.914.624 bytes, respectivamente; tamanho físico não é prova de
integridade lógica e pode permanecer maior após uma transação abortada.

Ocorrências no harness, registradas sem mascaramento:

- O limite inicial de tmpfs de 1 GiB terminou em `53100` durante a **geração** do
  perfil B, antes da migration. A reprodução confirmou falta de espaço. Somente
  o contêiner descartável passou a usar 2 GiB; nenhuma infraestrutura foi alterada.
- A primeira comparação de rollback incluía tamanho físico e reprovou esse
  crescimento esperado. A verificação foi corrigida para comparar dados,
  hashes, schema e revisão; os limites reais foram repetidos e passaram.
  Os benchmarks de volume já concluídos não foram repetidos nessa etapa.

## Problemas demonstrados e correções

1. **Identidade:** o teste anterior tratava mesmo intervalo/texto como duplicação.
   A regressão demonstrou “esperados 2, observado 1”. Agora a chave é a identidade
   privada da origem, persistida nos metadados existentes. Origens distintas
   iguais permanecem duas; repetir a mesma origem em uniões sucessivas não a
   duplica. Empates são ordenados por identidade. Divergência de conteúdo para a
   mesma identidade aborta a operação em vez de sobrescrever silenciosamente.
2. **Horário anterior ao movimento:** um teste demonstrou origem mudando de
   `10:00Z` para `09:30Z` ao editar o intervalo de uma observação ainda não unida.
   Agora o endpoint conserva a origem anterior antes de mudar horários quando
   o texto não foi alterado. Agregados já existentes conservam suas origens.
3. **Fuso e texto livre:** horários embutidos em UTC no texto não acompanhavam o
   fuso do restante da tela. A observação agora concatena apenas textos integrais;
   `observacoesOriginais` fornece datas UTC e textos como projeção tipada de
   resposta, sem coluna nova (`!persist`) e sem expor identidades privadas.
   Painel e edição usam o mesmo formatador local, com data e offset explícitos.
   Datas digitadas pelo usuário não são interpretadas nem substituídas.
4. **Salvar sem alteração:** preserva os metadados de origem, inclusive no
   endpoint isolado. Alteração explícita de texto continua substituindo a
   observação conforme o fluxo já aprovado.

Exemplo conferido nos dois fusos:

- UTC: `01/11/2026 02:45 → 01/11/2026 03:15`, offset `UTC+00:00`.
- São Paulo: `31/10/2026 23:45 → 01/11/2026 00:15`, offset `UTC-03:00`.

## Validações afetadas

- **46 testes Flutter em America/Sao_Paulo:** novas verificações de fuso,
  anotações/horas do painel, formulários e regressões de criação/arraste da agenda.
- **5 testes de fuso em UTC:** mesmo conjunto específico, cobrindo conversão,
  virada de dia, duas origens iguais e preservação de texto livre/no-op.
- **26 testes backend em PostgreSQL descartável:** identidade, uniões sucessivas,
  persistência/reconsulta da projeção, autoria/AAL2, edição temporal e concorrência
  real de observação/normalização; comparação do target confirma ausência de DDL novo.
- Análise Flutter e análise Dart do workspace Serverpod sem problemas.
- Build Web release aprovado com as definições públicas existentes, sem deploy.
- Formatação, compilação do script Python e `git diff --check` sem problemas.

As suítes completas anteriores não foram repetidas. Permanecem os avisos
anteriores não bloqueantes: comparação de índices customizados pelo harness de
alguns testes e fonte CupertinoIcons no build.

Reprodução do ensaio SQL:

```bash
python3 scripts/migrations/rehearse_pacote4_volume.py
```

O script cria e remove exclusivamente seu contêiner identificado; o resultado
local fica em `/tmp/temdas-p4-volume-report.json`. A opção
`TEMDAS_VOLUME_COUNTS=` repete somente os timeouts, aproveitando os resultados
já medidos do arquivo local. Logs backend:
`/tmp/temdas-p4-backend-test.log`.

## Risco restante e próximos passos

Não ficou falha funcional conhecida nos cenários exercitados. O risco restante é
principalmente operacional: tmpfs é mais rápido que disco real; volume, I/O,
concorrência e espaço para novas versões de texto/WAL em PROD podem variar.
A transação evita migração parcial, mas pode bloquear escritas até o timeout.
O ensaio de falta de espaço reforça a necessidade de folga de armazenamento.

Manter o plano já aprovado: homologação visual em navegador/dispositivo real,
backup verificável, baseline correto e janela de aplicação com autorização
específica. Backend compatível deve preceder a nova versão do frontend.
Nenhum rollback automático; não descartar colunas/anotações novas. Recuperação
após commit da transformação de descrição depende da cópia anterior, sem dividir
texto por subtítulos. Os ambientes compartilhados e PROD permanecem intocados.

## Arquivos afetados nesta revisão

- `app/lib/view/demanda_detalhe_page.dart`
- `app/lib/view/log_time_page.dart`
- `app/lib/view/widgets/demanda_texto_dialog.dart`
- `app/lib/view/widgets/log_time_dialog.dart`
- `app/lib/view/widgets/registro_tempo_observacoes.dart`
- `app/test/registro_tempo_observacoes_test.dart`
- `docs/pacote4-painel-demandas.md`
- `docs/pacote4-validacao-complementar.json`
- `docs/pacote4-validacao-complementar.md`
- `docs/roadmap.md`
- `scripts/migrations/rehearse_pacote4_volume.py`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/protocol.dart`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/registros_tempo/registro_tempo.dart`
- `serverpod/temdas_backend/temdas_backend_client/lib/src/protocol/registros_tempo/registro_tempo_observacao.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/protocol.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/registros_tempo/registro_tempo.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/generated/registros_tempo/registro_tempo_observacao.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo.spy.yaml`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo_endpoint.dart`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo_observacao.spy.yaml`
- `serverpod/temdas_backend/temdas_backend_server/lib/src/registros_tempo/registro_tempo_observacao_service.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/integration/pacote4_endpoint_test.dart`
- `serverpod/temdas_backend/temdas_backend_server/test/unit/registro_tempo_observacao_test.dart`
