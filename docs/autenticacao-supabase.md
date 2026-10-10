# Autenticação Supabase → Serverpod (primeira camada)

Supabase Auth autentica e-mail/senha e emite o access JWT. O TEMDAS não armazena
senhas nem emite outro token. `auth.provisionar()` aceita JWT AAL1/AAL2 para
criar o `Usuario` interno; `auth.me()` e as operações funcionais continuam
exigindo `Usuario` e AAL2.

## Dependências e compatibilidade

Backend: `jose ^0.3.5+2` (JWS/JWK e criptografia da biblioteca), `http ^1.6.0`.
Flutter: `supabase_flutter ^2.18.0`. Serverpod/serverpod_client continuam
fixados em `3.4.11`. A resolução, compilação dos testes e análises foram feitas
com o SDK Dart 3.12 do projeto. Não há criptografia JWT implementada à mão.

Referências consultadas: [jose](https://pub.dev/packages/jose),
[Supabase JWT/JWKS](https://supabase.com/docs/guides/auth/jwts) e
[supabase_flutter](https://pub.dev/packages/supabase_flutter).
Para as APIs do Serverpod, foi conferido diretamente o código instalado da
versão 3.4.11 (ClientAuthKeyProvider, Session e AuthenticationHandler).

## Configuração

Servidor: variável de ambiente pública `SUPABASE_URL=https://<projeto>.supabase.co`.
Aceita somente uma origem HTTPS, sem credenciais, query ou fragmento. Ausência
da configuração retorna `authNotConfigured` nas chamadas com token ao endpoint
protegido. Os endpoints existentes podem ser executados sem Supabase configurado.
O JWT é validado sem publishable key, service_role ou JWT secret. O onboarding
e o envio de convites exigem `SUPABASE_SECRET_KEY=sb_secret_...` somente no
backend, para consultar o usuário confirmado e enviar convites, respectivamente.

Flutter:

```bash
rtk flutter run --dart-define=SUPABASE_URL=https://<projeto>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_<chave-publica> --dart-define=SERVERPOD_URL=http://localhost:8080/
```

O cliente exige uma chave pública moderna com prefixo `sb_publishable_`;
nenhuma chave service_role/secret é aceita. Sem os dois parâmetros Supabase,
o app funciona como antes, sem sessão autenticada. URL e chave parcialmente
configuradas geram erro de inicialização. Não adicionar senha de usuário a
`passwords.yaml`. Em produção, configurar `SERVERPOD_URL` com HTTPS.

## Transporte e validação

`SupabaseSession` implementa `ClientAuthKeyProvider`. O cliente gerado 3.4.11
não recebe esse provider no construtor: configuramos `client.authKeyProvider`
logo após a criação. A cada RPC, o provider lê a sessão atual e fornece
`Authorization: Bearer <accessToken>`. O SDK Supabase restaura/persiste a sessão
e faz refresh automático; o provider também pede refresh se ela já expirou.
`authChanges` expõe login, logout, refresh e demais eventos, sem guardar uma
cópia fixa do token. Login técnico usa `signInWithPassword`, e logout usa `signOut`.

O Serverpod remove o prefixo Bearer e entrega o JWT em
`Session.authenticationKey`. Seu `authenticationHandler` é configurado em
`lib/server.dart`, pois o handler padrão lança erro quando recebe credenciais.
O handler valida o JWT, fornece `AuthenticationInfo` com o `sub` e escopo
`supabase.aal2` somente para `aal2`. Token inválido permanece não autenticado;
o helper do endpoint retorna o erro específico. Claims/falhas são reutilizadas
na mesma Session, e troca de token invalida essa reutilização.

O serviço aceita somente `ES256` (EC P-256) e `RS256` (RSA), com `kid` não vazio
correspondente a uma chave JWKS. Respeita algoritmo/uso/operações da chave,
rejeita `none`, HS256 e extensões críticas não suportadas. URLs de chave nos
headers do JWT não são consultadas. Após verificar assinatura com `jose`, exige:

- `iss` exatamente igual a `<SUPABASE_URL>/auth/v1`;
- `exp` inteiro obrigatório, estritamente posterior ao instante atual, sem tolerância;
- `nbf`, quando presente, inteiro e não futuro;
- `sub` string não vazia;
- `aal` exatamente `aal1` ou `aal2`;
- audience `authenticated` (string ou elemento de uma lista).

## JWKS e cache

Somente `<SUPABASE_URL>/auth/v1/.well-known/jwks.json` é consultado, sem
redirecionamentos. Cache em memória por processo: TTL de 10 minutos, troca
atômica após leitura válida, fetch concorrente compartilhado. `kid` desconhecido
pede refresh, limitado globalmente a uma tentativa a cada 30 segundos para
impedir que tokens aleatórios causem uma consulta por request. Uma chave recém
rotacionada pode precisar de até 30 segundos para ser reconhecida pelo backend,
além do cache do próprio Supabase. Há timeout de 5 segundos para headers e
5 segundos para corpo, limite de 256 KiB e rejeição de `kid` duplicado/chave
privada. Falhas não renovam o cache, e chaves expiradas não são usadas.

O onboarding consulta Supabase Auth a cada chamada; as rotas funcionais não.
Logout/ revogação de sessão não
revogam instantaneamente um access JWT já emitido: validação é local até seu
`exp`, conforme o modelo JWT escolhido.

## Usuário e endpoint de prova

`requireAuthenticatedUsuario(session)` busca a linha com
`Usuario.db.findFirstRow(... supabaseUserId.equals(sub))`.
Retorna `AuthenticatedUsuario(usuario, supabaseUserId, aal)`; não cria usuários,
não usa e-mail para associação e não assume `Usuario.id = 1`.
`requireAal2Usuario(session)` exige adicionalmente `aal2`.

`auth.me` usa esse segundo helper e retorna somente:

```json
{"usuarioId": 1, "aal": "aal2"}
```

## Provisioning AAL1/AAL2

`auth.provisionar()` não recebe e-mail do cliente e não exige `Usuario` prévio.
Usa o `sub` do JWT validado, consulta `GET /auth/v1/admin/users/{sub}` no
Supabase Auth com a chave secreta apenas no header `apikey` e exige que o `id`
da resposta coincida com `sub` e que `email_confirmed_at` esteja preenchido.
Ignora `JWT.email`, `user_metadata` e `confirmed_at` (que também pode indicar
confirmação de telefone). A leitura ocorre antes da transação PostgreSQL.

O e-mail retornado pelo Auth é normalizado como nos convites e deve existir em
`EmailWhitelist`. Uma transação com locks por `sub` e e-mail cria no máximo um
`Usuario` por `supabaseUserId`, sempre com `isAdmin=false`, e preenche
`utilizadoEm` junto com a criação. Repetições retornam o mesmo ID e não alteram
um admin existente. Um registro de whitelist consumido sem `Usuario` para o
mesmo `sub` é recusado. A restrição única do usuário também cobre escritores
que não utilizem os advisory locks. O retorno usa o mesmo `AuthMe` de `auth.me`.
Como a whitelist não registra o `sub` consumidor, a repetição de um `Usuario`
existente é identificada pelo `supabaseUserId`; não é possível provar pelo
registro da whitelist qual `sub` o consumiu originalmente.

Não há transação distribuída com Supabase Auth: uma mudança ou revogação do
e-mail após a consulta e antes do commit só será observada numa próxima
chamada. O JWT também continua válido até `exp` conforme a política já descrita.
Falhas da consulta não criam usuário nem consomem whitelist. Códigos adicionais:
`authNaoConfigurado`, `authIndisponivel`, `usuarioSupabaseNaoEncontrado`,
`emailNaoConfirmado`, `emailInvalido`, `emailNaoAutorizado`,
`conviteJaUtilizado` e `provisioningConflito`.

São erros serializáveis `AuthException.codigo`:

| Código | Situação |
| --- | --- |
| tokenMissing | Nenhum token |
| tokenInvalid | Formato, assinatura, algoritmo, kid ou claims inválidos |
| tokenExpired | Assinatura válida, token expirado |
| usuarioNotFound | JWT válido, sem Usuario interno para o sub |
| aal2Required | Usuario encontrado, sessão aal1 |
| jwksUnavailable | Não há JWKS fresco utilizável |
| authNotConfigured | SUPABASE_URL ausente |

Prova técnica, sem UI nova:

```dart
await supabaseSession!.signInWithPassword(email, password);
final me = await serverpodClient.auth.me();
```

Login primário retorna normalmente `aal1`, portanto a chamada deve falhar com
`aal2Required` quando houver Usuario associado. Após obter uma sessão `aal2`
por TOTP, a mesma chamada retorna o ID interno. Nunca registrar o token/senha.
Usar o helper AAL2 em futuras operações funcionais: apenas `requireLogin` do
Serverpod não verifica provisioning interno nem MFA.

## Verificação

Nesta etapa foram executados `serverpod generate`, `dart analyze` no backend e
cliente e 43 testes unitários do backend. Os testes de onboarding cobrem JWT
AAL1/AAL2, acesso funcional AAL2, e-mail confirmado vindo do Auth, whitelist,
repetição, concorrência simulada e preservação de admin. Os testes de
concorrência usam store em memória; não substituem a validação transacional em
PostgreSQL.

Os unitários cobrem os sete casos solicitados, ES256/RS256, audience/issuer,
cache concorrente, rotação, cooldown, remoção de chave, indisponibilidade,
cache vencido e mudança de token em Session. O teste Flutter usa HTTP local e
o SDK Supabase para login/refresh/logout, conferindo o Bearer recebido pelo
cliente gerado do Serverpod. Ele usa tokens sintéticos e não valida criptografia.

O teste com PostgreSQL real está em `test/integration/auth_usuario_test.dart`:
associação exata do sub, aal1/aal2, sub desconhecido e `auth.me` sem token.
Depende do PostgreSQL de testes em localhost:9090. O banco não respondeu nesta
sessão e o socket Docker não estava acessível; a transação de provisioning e
a consulta ao projeto Supabase real ainda precisam de validação nesse ambiente.

```bash
# A partir de temdas_backend_server, com os serviços de teste disponíveis:
rtk dart test test/integration/auth_usuario_test.dart
```

## Próxima etapa MFA

As decisões de e-mail/senha, TOTP obrigatório e acesso funcional apenas em aal2
estão preservadas. Falta fornecer URL/chave pública do ambiente e confirmar a
signing key assimétrica ativa no Supabase, a associação do sub real em usuarios
e uma sessão aal2 para prova ponta a ponta. A próxima implementação deve tratar
enrollment/challenge TOTP e refletir o token elevado na sessão. O desenho das
telas de MFA permanece para essa etapa; não há UI de onboarding, recovery, RLS
ou roles nesta entrega.
