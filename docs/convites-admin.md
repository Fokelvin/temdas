# Convites administrativos

O endpoint Serverpod `convite` oferece `consultar(email)`, `convidar(email)` e
`reenviar(email)`. Todos exigem JWT Supabase AAL2, `Usuario` interno e
`Usuario.isAdmin=true`. `consultar` retorna `ausente`, `pendente` ou
`provisionado`; os envios retornam `enviado` ou `reenviado`. Falhas usam
`ConviteException.codigo` e acesso sem privilégio usa
`AuthException(codigo: adminRequired)`.

O backend normaliza e valida o e-mail e usa a chave única de
`emails_whitelist.emailNormalizado`. `utilizadoEm` pertence apenas ao
provisioning: permanece nulo após o envio e, quando preenchido, impede novos
envios. `convidar` não reenviará um convite já registrado. `reenviar` é uma
ação explícita para registros pendentes. O intervalo mínimo de 15 minutos é
calculado a partir de `ultimoConviteEm` no banco, preenchido somente após
resposta de sucesso do Supabase. `createdAt` não controla o reenvio. Registros
anteriores à migration têm `ultimoConviteEm` nulo e podem ser reenviados de
imediato até o primeiro envio bem-sucedido registrado.
Aplicar a migration antes de executar o backend atualizado; ela foi gerada,
mas não aplicada nesta alteração.

Uma transação curta com advisory lock por e-mail grava `conviteReservaId` e
`conviteReservadoAte` antes da chamada HTTP. Outra transação curta registra
`ultimoConviteEm` e libera a reserva após o sucesso. Nenhuma transação fica
aberta durante a chamada ao Supabase. A reserva de dois minutos impede envios
simultâneos entre processos enquanto estiver válida; um token impede que uma
resposta atrasada sobrescreva uma reserva posterior. Falhas explícitas liberam
a reserva; um convite novo cuja chamada falhou tem sua linha removida. Se um
processo morrer, uma reserva vencida pode ser retomada. A expiração permite
novo envio mesmo se uma chamada antiga ainda estiver em curso; timeouts e
falhas entre o sucesso no Supabase e a gravação no banco podem resultar em
convite entregue sem `ultimoConviteEm` atualizado. Não há transação distribuída
entre PostgreSQL e Supabase, portanto a garantia de não duplicar envios cobre
apenas reservas válidas. O cálculo dos prazos usa o relógio UTC dos processos
do backend, que precisam estar sincronizados entre si.

Configuração exclusiva do backend:

- `SUPABASE_URL`: origem HTTPS do projeto, também usada na validação JWT.
- `SUPABASE_SECRET_KEY`: chave `sb_secret_...`, somente no ambiente do servidor.
- `SUPABASE_INVITE_REDIRECT_URL`: destino do convite. Deve constar na lista de
  Redirect URLs permitidas no Supabase Auth; caso contrário, o Supabase pode
  usar a Site URL sem retornar erro.

O backend chama `POST /auth/v1/invite` com a chave somente no header `apikey`.
Não registra nem devolve a chave ou o corpo de erro do Supabase. Não repete
automaticamente uma chamada que terminou em timeout, pois o e-mail pode ter
sido enviado mesmo sem resposta. Respostas `429`, falhas de configuração,
recusas e indisponibilidade têm códigos separados.

Há limites em memória por processo: 20 tentativas por administrador por hora e
um minuto de espera por e-mail após falha de envio. O limite por administrador
e a espera após falha não são compartilhados entre réplicas nem sobrevivem a
reinícios. O cooldown de envios bem-sucedidos e a reserva ficam no banco. Para
múltiplas réplicas, é necessário um limitador distribuído por administrador
antes de expor o endpoint amplamente.
