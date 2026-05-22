// Lanza Chromium visible (headed) con CDP abierto en :9222 y sesión persistente.
// Queda vivo para reconectarme por connectOverCDP desde otros scripts.
const path = require('path');
const { chromium } = require('playwright');

const URL = 'https://qashanada.gilm.com.mx:44301/sap/bc/gui/sap/its/webgui#';
const USER_DATA = path.resolve(__dirname, 'userdata');

(async () => {
  const ctx = await chromium.launchPersistentContext(USER_DATA, {
    headless: false,
    ignoreHTTPSErrors: true,
    viewport: null,
    acceptDownloads: true,
    args: ['--remote-debugging-port=9222', '--start-maximized'],
  });

  const page = ctx.pages()[0] || (await ctx.newPage());
  try {
    await page.goto(URL, { waitUntil: 'domcontentloaded', timeout: 60000 });
  } catch (e) {
    console.log('goto warning:', e.message);
  }
  console.log('READY url=' + page.url());
  // Mantener vivo el proceso (y el navegador) indefinidamente.
  await new Promise(() => {});
})();
