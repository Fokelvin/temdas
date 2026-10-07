# Prova técnica de MFA TOTP

A rota temporária `/auth-test` é a rota inicial do app nesta etapa. Ela usa
somente as APIs MFA do `supabase_flutter` e mostra o estado da sessão, AAL,
fatores TOTP, enrollment, challenge, verify e retorno de `auth.me()`.

Com o backend Serverpod iniciado, execute o Flutter com os valores públicos do
projeto Supabase de desenvolvimento (substitua os placeholders):

```sh
cd app
flutter run -d linux \
  --dart-define=SUPABASE_URL=<url-do-projeto> \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<sb_publishable_...> \
  --dart-define=SERVERPOD_URL=http://localhost:8080/
```

Digite e-mail e senha **na tela**, não no comando nem em arquivos. Depois do
login, confira `AAL atual: aal1`. A lista mostra fatores TOTP existentes e o
status de cada um. Se não houver fator verificado, use **Cadastrar TOTP** e
configure o Authenticator com a URI ou o secret apresentados na tela. Se já
houver um fator verificado, selecione-o. Use **Iniciar challenge**, informe o
código atual do Authenticator e clique em **Verificar e chamar auth.me()**.

O `factorId` vem de `mfa.enroll()` para um fator novo ou de
`mfa.listFactors()` para um fator verificado. O `challengeId` vem de
`mfa.challenge()`. `mfa.verify()` salva a nova sessão no cliente Supabase;
a tela relê fatores e AAL da sessão, faz refresh adicional se necessário e
somente então chama `auth.me()`. O provider do cliente Serverpod lê
`currentSession` em cada chamada. O resultado esperado no ambiente de
desenvolvimento é `usuarioId=1` e `aal=aal2`.

O secret e a URI de enrollment ficam apenas no estado transitório da tela. São
limpos após verificação, novo login ou logout. Não envie esses dados, a senha
ou o código TOTP em logs ou relatórios do teste.
