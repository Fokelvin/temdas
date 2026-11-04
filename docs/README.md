# Documentação do TEMDAS

Este é o índice da documentação **ativa** do projeto, revisado em 04/11/2026.
As regras efetivas são as do código e das migrations versionadas; documentação
histórica não deve ser tratada como instrução de implementação ou deploy.

## Produto, arquitetura e regras

- [Roadmap oficial](roadmap.md) — estado das funcionalidades, prioridades e decisões pendentes.
- [Arquitetura atual](arquitetura.md) — stack, fluxos, responsabilidades e ambientes.
- [Escopo da V1](escopo_temdas_v1_atualizado.md) — requisitos, funcionalidades e limites.
- [Transições de status](transicoes-status.md) — regras e cascatas de Demandas.
- [Schema de Sprints](schema-sprints-serverpod.md) — constraints e objetos SQL customizados.

## Autenticação e autorização

- [Supabase Auth e Serverpod](autenticacao-supabase.md) — integração de identidade e AAL2.
- [Callback Flutter](auth-callback-flutter.md) — rotas de autenticação e compatibilidade.
- [Confirmação explícita de links](auth-confirmation.md) — convite, recuperação e proteção de token.
- [Convites administrativos](convites-admin.md) — envio, reenvio, autorização e limites.
- [Templates de convite e recuperação](auth-email-templates/) — HTMLs e backups de configuração; conferir o estado real do Supabase antes de reutilizar.

## Operação e banco de dados

- [Backup e restauração PROD](backup-restauracao-prod.md) — cópias, integridade e recuperação.
- [Migrations PROD](migrations-prod.md) — ensaios e critérios de aprovação explícita.
- [Setup local do Serverpod](setup-serverpod.md) — configuração de desenvolvimento.
- [Promoção do administrador inicial](promover-admin-inicial.sql) — procedimento SQL manual e sensível; **não executar automaticamente**.

## Referências de implementação ainda importantes

- [Múltiplas Sprints por Demanda](spr-p2-01-multiplas-sprints.md) — integridade, histórico e migração.
- [Vinculação em lote](spr-p2-01-vinculacao-lote.md) — otimização, timeout e reconciliação.

## Histórico de entregas

Os 11 documentos de projetos já concluídos, relatórios de testes e evidências
foram movidos, sem alteração de conteúdo, para [historico/](historico/).
Use-os para auditoria e contexto, **não** como instrução operacional atual.
O antigo handoff do Codex e a prova inicial de MFA foram retirados da árvore
ativa por estarem obsoletos; podem ser recuperados pelo histórico de commits.

## Convenções

- Atualizar o [roadmap](roadmap.md) ao aprovar ou concluir funcionalidades.
- Preferir atualizar documentos existentes a criar novos relatórios pontuais
  para cada alteração pequena.
- Não aplicar migrations, executar restaurações ou publicar PROD sem aprovação explícita.
- Corrigir referências ao mover arquivos para evitar links quebrados.
