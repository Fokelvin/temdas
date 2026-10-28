# Confirmação explícita de recovery e invite

## Funcionamento

`/auth/confirm` e `/#/auth/confirm` recebem exclusivamente `token_hash` e
`type=recovery|invite`. O hash deve ter o formato emitido pelo Supabase Auth:
56 caracteres hexadecimais minúsculos (SHA-224), opcionalmente com `pkce_`.
Parâmetros espelhados entre query e fragmento são aceitos somente quando iguais;
repetições internas, conflitos, campos adicionais e outras modalidades são recusados.

O carregamento apenas valida a estrutura localmente, limpa parâmetros da URL via
`history.replaceState` e mostra um botão. Nenhum token é enviado ao Supabase.
O hash permanece somente na memória da página, sem persistência em storage ou logs.
O documento Web define `Referrer-Policy` via meta `no-referrer`, evitando que a URL
com credenciais seja enviada como Referer enquanto o Flutter inicializa.
Após clique explícito, uma única chamada `verifyOTP(tokenHash: ..., type: ...)`
obtém a sessão. O fluxo existente verifica a identidade, permite definir/redefinir
a senha, encerra a sessão e retorna ao login. MFA e provisioning continuam sob os
controles existentes; o link não concede AAL2 nem acesso às telas de negócio.

Uma sessão antiga nunca substitui a validação do novo hash. Um link inválido,
expirado ou reutilizado não abre o formulário, mesmo que já exista outra sessão.
Não há retry automático após a confirmação. Recarregar a URL já limpa não restaura
um fluxo antigo: antes do clique, reabra o link original; depois do consumo, um novo
link será necessário. O callback legado `/auth/callback` permanece compatível.

O fallback atual de Cloudflare Pages (`app/web/_redirects`: `/* /index.html 200`)
já cobre o acesso direto a `/auth/confirm`; nenhuma mudança na Cloudflare é necessária.
GETs/prefetches passivos não consomem o hash. Esta medida não é uma prova de presença
humana: automações que deliberadamente acionem o botão ainda podem consumir o link.

## Templates preparados, ainda não aplicados

Origem: leitura da Supabase Management API do projeto PROD
`vberbygddnootjcbkajc`. O horário da captura está no backup.

- `auth-email-templates/backup-prod.json`: os dois HTMLs e assuntos originais.
- `auth-email-templates/recovery.html`: conteúdo original, com apenas o href alterado.
- `auth-email-templates/invite.html`: conteúdo original, com apenas o href alterado.

Os novos links usam `{{ .SiteURL }}/auth/confirm` (Site URL PROD: `https://temdas.com.br`), com
`token_hash={{ .TokenHash }}` e `type` fixo para cada fluxo. O separador é `&amp;`
no HTML. O token não é um redirect genérico e não contém uma URL de destino arbitrária.
Não se usa `ConfirmationURL` nas versões propostas, evitando o GET automático a
`/auth/v1/verify`. Também não basta abrir uma página que execute `verifyOTP` no init.

Campos exatos que poderão ser atualizados, somente após aprovação:

| Campo de Auth config | Arquivo proposto |
| --- | --- |
| `mailer_templates_recovery_content` | `auth-email-templates/recovery.html` |
| `mailer_templates_invite_content` | `auth-email-templates/invite.html` |

O backup também preserva `mailer_subjects_recovery` e `mailer_subjects_invite`;
os assuntos não precisam ser alterados. SMTP, expiração, MFA, signup, Site URL,
allowlist e a variável de convites do Railway não fazem parte desta mudança.
A ativação exige confirmar que Site URL aponta para a origem PROD.

## Publicação e rollback

1. Publicar primeiro o Flutter com `/auth/confirm`, mantendo o callback legado.
2. Validar HTTP/SPA e o novo build. Em homologação autorizada, verificar que o
   carregamento não faz `/verify`, o clique faz um POST e os controles de MFA persistem.
3. Antes de aplicar os templates, ler novamente o Auth config e comparar os dois
   campos com o backup. Interromper se houver alterações concorrentes.
4. Com autorização específica, usar `PATCH /v1/projects/{ref}/config/auth`, enviando
   exclusivamente os dois campos HTML acima. Ler novamente para confirmar os valores.
5. Validar novos e-mails somente quando autorizado. Links emitidos antes da troca
   continuam no fluxo legado, sujeitos a pré-visualização e ao prazo de validade.

Para rollback, restaurar exclusivamente os dois HTMLs de `auth_config_fields` do
backup. Nesta ativação, o rollback em caso de falha parcial está autorizado. Não retirar a rota nova enquanto houver links novos
válidos. Nunca colar links reais, hashes ou sessões em logs, issues ou documentação.

O logger temporário continua filtrável por `TEMDAS_AUTH_DIAG`, incluindo
`confirmationReady`, `confirmationSubmitted` e `confirmationAlreadySubmitted`.
Todos os campos permanecem categorizados ou booleanos.

Referências: [templates e proteção contra prefetch](https://supabase.com/docs/guides/auth/auth-email-templates),
[verifyOTP no Dart](https://supabase.com/docs/reference/dart/auth-verifyotp),
[formato do hash no código oficial](https://github.com/supabase/auth/blob/master/internal/crypto/crypto.go).
