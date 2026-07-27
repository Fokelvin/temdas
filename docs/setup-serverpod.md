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
