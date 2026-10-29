# Pacote 4 — publicação coordenada e restauração dos guards

Autorização do responsável: restaurar os objetos ausentes, ensaiar sobre backup
real e aplicar/publicar o Pacote 4, com backend antes do frontend. O Pacote 5
permanece somente no roadmap.

## Ordem e limites

1. Backup criptografado atualizado, com hash e segunda cópia externa verificados.
2. Restaurar o backup em PostgreSQL 17.11 descartável, sem rede/volumes externos;
   comparar integralmente o inventário das 54 tabelas com o manifesto.
3. Aplicar `20261029183226724-pacote4-demandas`, sem modificar seu SQL histórico.
4. Aplicar `20261029220000000-restore-schema-guards`.
5. Conferir hashes/contagens dos dados originais, schema gerenciado, histórico,
   índices de Sprints e os 7 triggers, 5 funções e 2 CHECKs validados.
6. Publicar no serviço Railway existente e aguardar SUCCESS/readyz; somente
   depois enviar a main para acionar o workflow de Cloudflare Pages.
7. Conferir o SHA do workflow, HTTPS, recursos, cache e proteção dos endpoints.

A correção é aditiva: recupera literalmente as definições de guards já presentes
na definição completa do Pacote 4. Não altera dados nem recria índices existentes.
Exige baseline exato, ausência dos objetos esperados e integridade dos vínculos;
qualquer divergência interrompe a transação. Cada migration possui transação,
lock_timeout de 5s e statement_timeout de 60s. A correção bloqueia brevemente
escritas nas quatro tabelas envolvidas e valida os CHECKs sobre os dados reais.
As migrations históricas permanecem intactas; instalações novas usam a definição
completa final, que já inclui os guards.

## Evidências essenciais

- `scripts/migrations/rehearse_pacote4_release.py`: SQL com hashes fixados,
  restauração real, preservação dos dados, delta exato do schema, CHECKs,
  rejeição de ordem incorreta e de reaplicação. Nunca conecta em PROD.
- `scripts/migrations/test_release_guards.py`: regressão dos artefatos e rejeição
  de remoção/alteração dos objetos anteriores.
- 43 testes direcionados de backend aprovados com PostgreSQL descartável e
  definição final: Sprints, ownership/AAL2, anotações e concorrência de observações.
- Reutilizados os testes/análises completos anteriores e os ensaios de volume,
  timeouts e fusos em `pacote4-validacao-complementar.md`. Sem alterações novas
  de Dart neste fechamento; gerar artefato Web release com os defines de PROD.
- Ensaio real aprovado em [pacote4-publicacao-ensaio.json](pacote4-publicacao-ensaio.json):
  54 tabelas restauradas; dados originais preservados; migrations em 0,179s/0,164s.
- Cinco testes de regressão dos artefatos passaram.
- Evidência operacional também fica em `/tmp/temdas-p4-release-rehearsal.json`;
  não versionar manifestos, dumps, credenciais, dados pessoais ou chaves.

## Recuperação e limites

Não existe rollback automático. Em falha de migration, parar e conferir versão
persistida antes de qualquer repetição. Se a segunda migration falhar, a primeira
é aditiva e o backend anterior permanece publicado; não publicar o frontend.
Se necessário, restaurar código anterior somente após avaliar compatibilidade;
reversão de schema/restauração de dados exige nova autorização. Conservar tabelas,
colunas e o arquivo legado `Demanda.observacoes` durante a recuperação.

O backup selecionado cobre os schemas documentados pelo processo de backup;
não equivale a recuperação integral dos serviços gerenciados Supabase. O ensaio
não restaura ownership/grants gerenciados. Não há ponto nativo de recuperação/PITR
comprovado; a recuperação verificada depende do arquivo criptografado, chave e
cópia externa. Nunca aplicar restauração destrutiva automaticamente.

Login/MFA e os fluxos com dados reais exigem sessão autorizada do proprietário.
Na ausência dela, registrar a homologação interativa como pendência; não simular
usuários pessoais nem declarar que testes públicos exercitaram fluxos autenticados.
