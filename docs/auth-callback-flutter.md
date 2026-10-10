# Callback de autenticação no Flutter Web

O app recebe convites e recuperação em `/auth/callback`. A rota aceita tanto
URL com caminho direto (`https://app.example/auth/callback`) quanto a rota hash
do Flutter Web (`https://app.example/#/auth/callback`). O servidor que hospeda
o build precisa devolver `index.html` para `/auth/callback` quando usar o
caminho direto. A estratégia hash existente continua funcionando.

O callback aceita o formato padrão com `access_token` no fragmento, o código
PKCE em `?code=...` e `token_hash` com `type=invite` ou `type=recovery`. O SDK
Supabase troca ou valida o link e mantém a sessão; o app exige que a sessão
resultante corresponda ao usuário retornado. Erros do Supabase, inclusive
`otp_expired`, são mostrados sem exibir tokens ou detalhes internos. Parâmetros
do link sozinhos não concedem acesso: `AuthGate` continua exigindo AAL2 nas
rotas funcionais. Um tipo fornecido no link serve apenas para identificar a
mensagem da tela, após a validação do SDK; não é uma autorização.

O SDK deixa de capturar deep links automaticamente para evitar dupla troca do
código. A rota limpa credenciais e códigos da barra de endereço e guarda apenas
o tipo do fluxo e o ID do usuário no `sessionStorage` por até 15 minutos. No
refresh, valida a sessão Supabase atual e consulta o usuário antes de restaurar
o estado. Se a sessão foi encerrada, o estado anterior não é usado.

Configuração por ambiente:

- Flutter: `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` via `--dart-define`, como
  nas demais rotas; não há origem fixa no callback.
- Backend existente: `SUPABASE_INVITE_REDIRECT_URL` deve apontar para a URL
  pública do callback do ambiente, por exemplo
  `https://app.example/auth/callback`. Nenhuma mudança no backend é necessária.
- Supabase Auth: incluir exatamente as URLs de callback usadas pelo ambiente na
  lista de Redirect URLs. O envio de recuperação, quando implementado, deverá
  usar seu próprio `redirectTo` configurado por ambiente apontando para essa
  mesma rota.

Após um callback válido, a tela solicita senha e confirmação, valida os campos
e chama `Supabase Auth.updateUser()`. Antes do envio, confirma novamente que a
sessão pertence ao usuário do callback; se o access token expirou, tenta o
refresh pelo SDK. Após sucesso, remove o estado temporário, encerra a sessão
Supabase e abre o login convencional. Cliques repetidos não criam outro envio.
Políticas de senha adicionais configuradas no Supabase são aplicadas pelo próprio
Auth e seus erros são mostrados sem detalhes internos.

Provisioning no Flutter, perfil e UI de convites continuam fora desta etapa.
