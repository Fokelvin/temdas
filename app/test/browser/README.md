# Release Web: confirmação de autenticação em navegador real

Requisitos: Playwright e navegador Chromium existentes. Não instalar dependências
no projeto nem usar definições ou sessões PROD. Os testes usam um contexto isolado
por caso, bloqueiam serviços externos e simulam a API Auth localmente.

1. Em `app/`, gerar o build:

   ```sh
   flutter build web --release --no-pub --output /tmp/temdas-confirm-browser \
     --dart-define=SUPABASE_URL=http://localhost:38431 \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_browser_fixture \
     --dart-define=SERVERPOD_URL=http://localhost:38431/
   ```

2. Servir o build com fallback SPA (somente loopback):

   ```sh
   python3 test/browser/serve_flutter.py /tmp/temdas-confirm-browser
   ```

3. Executar `node test/browser/auth_confirmation.cjs`. Quando necessário, definir
   `TEMDAS_PLAYWRIGHT_MODULE` como caminho do pacote e
   `TEMDAS_BROWSER_EXECUTABLE` como caminho do navegador. Para WSL + navegador
   Windows, executar com Node Windows e usar seus caminhos correspondentes.

Os quatro casos exercitam o `main.dart` real compilado: recovery e invite, com e
sem `#/demandas`. Conferem a tela de confirmação, ausência de consumo no
carregamento, limpeza da URL e das entradas de histórico criadas pelo Flutter,
uma verificação explícita e formulário de senha. Logs são inspecionados para
impedir exposição das credenciais fictícias. Nenhuma senha é alterada.
