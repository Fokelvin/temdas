// Run against a local release build with fake Supabase configuration only.
// See README.md. This script never opens production or real authentication links.
const assert = require('node:assert/strict');
const { chromium } = require(process.env.TEMDAS_PLAYWRIGHT_MODULE || 'playwright');
const base = process.env.TEMDAS_WEB_TEST_URL || 'http://localhost:38431';
assert(['localhost', '127.0.0.1'].includes(new URL(base).hostname));
const hash = 'a'.repeat(56);
const user = { id: 'browser-test-user', aud: 'authenticated', app_metadata: {},
  user_metadata: {}, created_at: '2026-01-01T00:00:00Z' };
let stage = 'launch';
function jwt(aal) { const enc = x => Buffer.from(JSON.stringify(x)).toString('base64url'); return enc({alg:'HS256'})+'.'+enc({aal,exp:Math.floor(Date.now()/1000)+3600})+'.fixture'; }
(async () => {
  const browser = await chromium.launch({headless: true,
    ...(process.env.TEMDAS_BROWSER_EXECUTABLE ? {executablePath: process.env.TEMDAS_BROWSER_EXECUTABLE} : {})});
  let passed = 0;
  try {
    for (const type of ['recovery', 'invite']) {
      for (const fragment of ['', '#/demandas']) for (const withMfa of [false, true]) {
        let aal = 'aal1';
        const account = {...user, factors: withMfa ? [{id:'browser-factor', factor_type:'totp', status:'verified', created_at:'2026-01-01T00:00:00Z', updated_at:'2026-01-01T00:00:00Z'}] : []};
        const session = () => ({access_token:jwt(aal),refresh_token:'fake-refresh-value',expires_in:3600,token_type:'bearer',user:account});
        const context = await browser.newContext({serviceWorkers: 'block'});
        try {
          const page = await context.newPage();
          let verifies = 0, challenges = 0, totpVerifies = 0;
          const diagnostics = [];
          const errors = [];
          page.on('pageerror', e => errors.push(e.name));
          page.on('console', m => {
            if (m.text().startsWith('TEMDAS_AUTH_DIAG ')) diagnostics.push(m.text());
          });
          await context.route('**/*', async route => {
            const request = route.request();
            const url = new URL(request.url());
            if (url.pathname.startsWith('/auth/v1/')) {
              // The build must use the local fake Auth service, never production.
              assert(['localhost', '127.0.0.1'].includes(url.hostname));
              let body;
              if (url.pathname.endsWith('/factors/browser-factor/challenge')) {
                challenges++;
                body = {id:'browser-challenge',expires_at:Math.floor(Date.now()/1000)+300};
              } else if (url.pathname.endsWith('/factors/browser-factor/verify')) {
                totpVerifies++;
                assert.equal(request.postDataJSON().code,'123456');
                aal='aal2'; body=session();
              } else if (url.pathname.endsWith('/verify')) {
                verifies++;
                assert.equal(request.method(), 'POST');
                const payload = request.postDataJSON();
                assert.equal(payload.token_hash, hash);
                assert.equal(payload.type, type);
                body = session();
              } else if (url.pathname.endsWith('/user')) {
                body = account;
              } else {
                throw new Error('Unexpected Auth operation');
              }
              return route.fulfill({status: 200, contentType: 'application/json',
                headers: {'access-control-allow-origin': '*', 'x-supabase-api-version': '2024-01-01'},
                body: JSON.stringify(body)});
            }
            if (url.origin === new URL(base).origin) return route.continue();
            // Use the CanvasKit distributed with the build instead of its CDN.
            if (url.hostname === 'www.gstatic.com' && url.pathname.includes('/flutter-canvaskit/')) {
              const asset = url.pathname.split('/flutter-canvaskit/')[1].replace(/^[a-f0-9]{20,}\//, '');
              const response = await context.request.get(base + '/canvaskit/' + asset);
              assert.equal(response.status(), 200);
              return route.fulfill({response, headers: {...response.headers(), 'access-control-allow-origin': '*'}});
            }
            // No production, backend, or other external requests are allowed.
            return route.abort();
          });
          await page.addInitScript(() => {
            window.__authHistorySensitive = [];
            for (const method of ['replaceState', 'pushState']) {
              const original = history[method];
              history[method] = function (state, title, url) {
                window.__authHistorySensitive.push(new URL(url, location.href).searchParams.has('token_hash'));
                return original.apply(this, arguments);
              };
            }
          });
          stage = 'navigation';
          await page.goto(base + '/auth/confirm?token_hash=' + hash + '&type=' + type + fragment);
          stage = 'flutter-view';
          await page.waitForFunction(() => !!document.querySelector('flutter-view'), {timeout: 30000});
          stage = 'semantics';
          await page.locator('flt-semantics-placeholder').dispatchEvent('click', {timeout: 30000});
          const title = type === 'invite' ? 'Confirmar convite' : 'Confirmar recuperação de senha';
          stage = 'confirmation-title';
          await page.getByLabel(title, {exact: false}).waitFor({timeout: 10000});
          await page.waitForTimeout(500);
          assert.equal(verifies, 0, 'Loading/prefetch must not verify a token');
          const clean = await page.evaluate(() => ({
            path: location.pathname,
            hasQuery: location.search !== '',
            hasHashCredential: location.hash.includes('token_hash'),
            sensitiveHistory: window.__authHistorySensitive.some(Boolean),
          }));
          assert.deepEqual(clean, {path: '/auth/confirm', hasQuery: false, hasHashCredential: false, sensitiveHistory: false});
          const button = page.getByRole('button', {name: type === 'invite' ? 'Aceitar convite' : 'Continuar recuperação', exact: true});
          await button.click();
          if (withMfa) {
            await page.getByLabel('Confirme o MFA para definir a senha',{exact:false}).waitFor();
            assert.equal(await page.getByRole('button',{name:'Salvar senha',exact:true}).count(),0);
            assert.equal(challenges,0); assert.equal(totpVerifies,0);
            await page.getByRole('textbox').fill('123456');
            await page.getByRole('button',{name:'Confirmar MFA',exact:true}).click();
          }
          stage = 'password-title';
          await page.getByLabel(type === 'invite' ? 'Definir senha' : 'Redefinir senha', {exact: false}).waitFor();
          assert.equal(verifies, 1);
          assert.equal(challenges,withMfa?1:0); assert.equal(totpVerifies,withMfa?1:0);
          await page.waitForTimeout(300);
          assert.equal(verifies, 1);
          assert.deepEqual(errors, []);
          assert(diagnostics.some(s => s.includes('confirmationReady')));
          assert(diagnostics.some(s => s.includes('confirmationSubmitted')));
          assert(diagnostics.every(s => ![hash, 'fake-access-value', 'fake-refresh-value', 'browser-test-user', 'https://', 'http://', 'token_hash=', '123456'].some(secret => s.includes(secret))));
          passed++;
          console.log(JSON.stringify({scenario: type + (fragment ? ' with default fragment' : ' direct'), passed: true, withMfa,
            autoVerify: false, sanitized: true, explicitVerifications: verifies}));
        } finally { await context.close(); }
      }
    }
    console.log(JSON.stringify({passed, failed: 0}));
  } finally { await browser.close(); }
})().catch(error => {
  // Assertion output can contain fixture request payloads: keep console safe.
  console.error(JSON.stringify({failed: true, errorClass: error.name, stage}));
  process.exitCode = 1;
});
