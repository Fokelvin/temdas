# Redesign de Demandas

Mudança de apresentação: tokens compartilhados em `app/lib/ui/theme/tokens.dart`, Inter e Roboto Mono empacotadas, ícones Material Symbols Rounded e componentes em `app/lib/ui/components/`. Repositórios, modelos, endpoints, permissões, status e regras de hierarquia permanecem nas implementações existentes.

A Lista mantém cabeçalho fixo, agrupa as árvores pelo status da raiz e reúne grupos vazios no rodapé. O Kanban usa scroll vertical por coluna, snap horizontal e faixas recolhidas que continuam recebendo drops. No celular, abas substituem o board; pressão longa no card usa a operação de movimentação já existente. A preferência Lista/Kanban continua no armazenamento local existente.

A navegação usa sidebar de 212 px, rail de 60 px ou bottom navigation com safe area. O cabeçalho desktop compacta a busca quando necessário. A tabela usa colunas combinadas quando a largura disponível depois da sidebar não comporta todas as colunas. Metadados usam text2 para manter leitura AA; text3 permanece disponível como token decorativo.

Validação: `flutter analyze`, testes afetados de status, busca, filtros, Sprint, arraste, atualização local, tema e responsividade. `app/test/demandas_redesign_test.dart` cobre 360, 390, 430, 768, 820, 1024, 1280 e 1440 px nos dois temas e nas duas visualizações, texto ampliado, persistência, hierarquia, atualização parcial e drag no celular. `TEMDAS_SCREENSHOTS=/tmp/temdas-redesign-screenshots` habilita as 32 capturas.

O anexo recebido contém somente o prompt Markdown; não há mockups de imagem para comparação lado a lado. As capturas foram conferidas contra as especificações textuais.

Publicação: um único build release no workflow existente `deploy-pages.yml`, seguido pelo deploy de produção somente se o build passar. Não gerar build local intermediário ou duplicado.
