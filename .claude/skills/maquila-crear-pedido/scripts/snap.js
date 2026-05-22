// Reconecta por CDP al navegador ya abierto, toma una captura y reporta estado.
// No cierra el navegador (process.exit deja vivo el Chromium del launcher).
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const out = process.argv[2] || path.resolve(__dirname, 'shot.png');
  const browser = await chromium.connectOverCDP('http://localhost:9222');
  const ctx = browser.contexts()[0];
  const pages = ctx.pages();
  const page = pages[pages.length - 1];

  console.log('pages=' + pages.length);
  console.log('url=' + page.url());
  console.log('title=' + (await page.title().catch(() => '')));
  await page.screenshot({ path: out, fullPage: false }).catch((e) => console.log('shot err:', e.message));
  console.log('shot=' + out);
  process.exit(0);
})();
