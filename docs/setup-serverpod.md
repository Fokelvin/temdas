# Setup do Serverpod - TEMDAS

Este documento registra como configurar e executar o backend Serverpod do TEMDAS usando Supabase Postgres remoto.

## Arquitetura local

```text
Flutter Web
  -> roda localmente na porta 3000

Serverpod Backend
  -> API Server na porta 8080
  -> Insights Server na porta 8081
  -> WebServer na porta 8082

Supabase Postgres
  -> banco remoto acessado pelo Serverpod
```

## Aviso local do Insights

O aviso `Invalid serviceSecret in password file, Insights server disabled.`
indica que o servidor auxiliar do Insights não foi habilitado. O `serviceSecret`
autentica o acesso ao Insights, conforme a
[documentação do Serverpod](https://docs.serverpod.dev/concepts/configuration#secrets).

No Serverpod 3.4.11 utilizado pelo projeto, essa validação desabilita somente o
Insights; a API principal inicia separadamente. O Flutter e a ferramenta E2E
usam a API na porta 8080 e não dependem do Insights para os fluxos da V1.

Configurar o Insights permanece uma pendência local opcional. Se ele for
necessário, fornecer um segredo aleatório exclusivo com mais de 20 caracteres
(critério do código da versão 3.4.11), na seção do ambiente correspondente ou
em `shared` de `config/passwords.yaml`. Esse arquivo já é ignorado pelo Git.
Não versionar nem imprimir o valor. A auditoria não leu nem alterou credenciais
e não habilitou o serviço auxiliar.
