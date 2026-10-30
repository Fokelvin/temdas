# Homepage pública do TEMDAS

TEMDAS significa **Tempo e Demandas**. A copy abaixo foi aprovada antes de ser aplicada; novas frases na interface dependem de aprovação do usuário.

| Seção | Texto aprovado |
|---|---|
| Apresentação | Organize suas demandas e acompanhe o tempo dedicado a cada atividade. |
| Demandas | Organize atividades, prioridades e status. |
| Sprints | Planeje períodos de trabalho e acompanhe as demandas vinculadas. |
| Log Time | Registre o tempo dedicado a cada demanda. |
| Relatórios | Consulte as horas registradas por demanda e período. |

Rótulos complementares aprovados: Entrar, Recursos, Dados de exemplo, Demanda de exemplo e Sprint de exemplo. Os demais rótulos das prévias são componentes e campos já existentes no aplicativo. Horas e datas ilustrativas não são métricas reais de usuários.

## Implementação

- Uma página, cinco seções e links que rolam para cada seção. Cabeçalho permanece acessível. A rolagem respeita movimento reduzido.
- Tokens, Inter, Material Symbols Rounded e componentes de Demanda/horas/status existentes. Claro/escuro compartilha a preferência persistida do aplicativo.
- Somente a raiz é pública. Links privados continuam no AuthGate, e callbacks/confirmations mantêm precedência. Sessões existentes passam por provisioning/MFA antes de acessar Demandas.
- Entrar substitui a rota pública pela rota existente de Demandas/login, evitando dois AuthGates simultâneos durante o login.
- As prévias são locais, sem consultar repositórios, contas ou dados privados.
- Backend, banco, migrations e implementação de login/MFA/recuperação não foram alterados.

## Logo

Foi escolhida a assinatura horizontal de `112010.jpg`; as outras duas versões não eram necessárias para esta composição. O arquivo final é `app/assets/images/temdas_wordmark_transparent.png`. No tema escuro, uma base clara pequena mantém a legibilidade da marca sem recolorir a assinatura.

Método: ferramenta integrada `image_gen`, edição para remoção do fundo com transparência real. Prompt usado:

> Edit target: the attached official TEMDAS horizontal wordmark. Background-extraction ONLY. Remove the white/off-white background, including the spaces inside letters, to genuine transparent alpha. Preserve EXACTLY the supplied wordmark: spelling TEMDAS, geometric letter shapes and custom blue lambda-shaped A, original deep navy and blue colors, proportions, spacing and orientation. Do not redesign, redraw, stylize, add shadows, gradients, strokes, extra icons or text. Crop excess empty margins closely while retaining all logo edges and modest transparent padding. Output a clean transparent PNG suitable for use as the official website header wordmark. This is asset cleanup, not new logo generation.

## Validação

`flutter analyze` e testes afetados: homepage, transparência da logo, âncoras, tema, login/recuperação, rotas/callbacks e preservação de provisioning/MFA. Capturas em 320, 360, 390, 430, 768, 820, 1024, 1280 e 1440 px nos dois temas; navegação por seções e texto ampliado também verificados.

Para habilitar capturas nos testes, definir `TEMDAS_HOME_SCREENSHOTS=/tmp/temdas-homepage-screenshots`. Publicação usa o workflow existente do Cloudflare Pages com um único build release final.
