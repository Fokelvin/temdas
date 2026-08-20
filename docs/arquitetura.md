# TEMDAS — Arquitetura Inicial

## Objetivo

O TEMDAS é um sistema pessoal para gestão simples de demandas, organização de execução diária/semanal e controle de tempo estimado versus tempo executado.

A primeira versão será focada em organizar demandas e subdemandas, distribuir visualmente essas demandas em uma agenda diária/semanal e comparar esforço planejado com esforço realizado.

Recursos de backlog, sprint, automações e integrações ficam para versões futuras.

## Escopo da primeira versão

A V1 deve permitir:

Demanda:
- título
- descrição
- status
- data planejada opcional
- tempo estimado
- tempo executado manual
- subdemandas

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
- validar como demandas e subdemandas aparecem na tela.

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