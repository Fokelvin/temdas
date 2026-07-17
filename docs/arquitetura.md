# TEMDAS — Arquitetura Inicial

## Objetivo

O TEMDAS é um sistema pessoal para gestão simples de demandas e controle de tempo.

A primeira versão será focada em organizar demandas, demandas filho e acompanhar tempo estimado versus tempo executado, com visualização diária e semanal em formato de calendário/agenda.

## Escopo da primeira versão

A V1 deve permitir:

- cadastrar demandas;
- cadastrar demandas filho;
- definir status;
- informar tempo estimado;
- informar tempo executado manualmente;
- visualizar demandas em formato diário;
- visualizar demandas em formato semanal;
- comparar tempo estimado versus tempo executado.

## Fora do escopo da primeira versão

Estes itens ficam para versões futuras:

- prioridade;
- timer automático;
- pausa e retomada de timer;
- observações/anotações;
- tags;
- anexos;
- histórico de alterações;
- autenticação;
- dashboards avançados;
- integrações com n8n;
- integração com Google Calendar;
- notificações.

## Estratégia de desenvolvimento

O projeto será desenvolvido em fases.

### Fase 1 — POP visual

Protótipo Operacional de Produto.

Objetivo:

- validar layout;
- validar navegação;
- validar fluxo de uso;
- validar a visão diária/semanal;
- validar como demandas e demandas filho aparecem na tela.

Nesta fase não haverá:

- backend;
- banco de dados;
- autenticação;
- n8n;
- persistência real.

Os dados serão mockados no próprio app.

### Fase 2 — MVP local estruturado

Objetivo:

- criar entidades;
- criar enums;
- criar ViewModels;
- criar repositories fake;
- organizar estrutura definitiva do Flutter;
- preparar o app para receber backend depois.

### Fase 3 — Integração com dados

Possível fluxo inicial:

```text
Flutter Web → n8n Webhook → PostgreSQL