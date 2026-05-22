// Crea el Pedido de Maquila en SAP LEYENDO los datos del Script de Pruebas (pw/tc01-data.json).
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const DATA_FILE = process.argv[2] || path.resolve(__dirname, 'tc01-data.json');
const D = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));

const settle = async (page, ms = 2200) => {
  await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});
  await page.waitForTimeout(ms);
};
const modalOpen = (page) => page.evaluate(() => {
  const b = document.getElementById('urPopupWindowBlockLayer');
  if (!b) return false;
  const r = b.getBoundingClientRect();
  return r.width > 0 && r.height > 0;
});
const setByTitle = async (page, title, value) => {
  const loc = page.locator(`input[title$="${title}"]`).first();
  await loc.click();
  await loc.fill(value);
};
const okcode = async (page, tcode) => {
  await page.evaluate(() => {
    ['ToolbarOkCode-tr', 'ToolbarOkCode-r'].forEach((id) => { const e = document.getElementById(id); if (e) e.style.display = 'inline-block'; });
    const inp = document.getElementById('ToolbarOkCode'); if (inp) { inp.style.width = '220px'; inp.style.height = '26px'; inp.focus(); }
  });
  const ok = page.locator('#ToolbarOkCode');
  await ok.fill(tcode);
  await page.keyboard.press('Enter');
  await settle(page);
};

(async () => {
  const out = path.resolve(__dirname, 'shot.png');
  console.log('DATOS DEL SCRIPT: ' + JSON.stringify(D));
  const browser = await chromium.connectOverCDP('http://localhost:9222');
  const ctx = browser.contexts()[0];
  const pages = ctx.pages();
  const page = pages.find((p) => p.url().includes('qashanada.gilm.com.mx')) || pages[pages.length - 1];

  // 1) VA01
  await okcode(page, '/nVA01');
  console.log('1) ' + (await page.title()));

  // 2) Pantalla inicial (con Sector del script para fijar el area)
  await setByTitle(page, 'Clase de documento de ventas', D.clase);
  await setByTitle(page, 'Organización de ventas', D.org);
  await setByTitle(page, 'Canal de distribución', D.canal);
  await setByTitle(page, 'Sector', D.sector);
  await page.keyboard.press('Enter');
  await settle(page);
  console.log('2) ' + (await page.title()) + ' (' + D.org + '/' + D.canal + '/' + D.sector + ')');

  // 3) Cabecera
  await setByTitle(page, 'Referencia de cliente', D.referencia);
  await setByTitle(page, 'Fecha preferente de entrega para el documento', D.fecha);
  await setByTitle(page, 'Solicitante', D.solicitante);
  await page.keyboard.press('Enter');
  await settle(page);

  // 4) Salvaguarda popup area de ventas
  for (let i = 0; i < 3 && await modalOpen(page); i++) {
    await page.keyboard.press('Escape'); await settle(page);
    if (!(await modalOpen(page))) { await page.keyboard.press('Enter'); await settle(page); }
  }
  if ((await page.title()).toLowerCase().includes('cabecera')) {
    await page.locator('[title^="Atrás"]').first().click(); await settle(page);
  }
  if (await modalOpen(page)) { console.log('!! modal persiste'); await page.screenshot({ path: out }); process.exit(2); }
  console.log('4) ' + (await page.title()));

  // 5) Posicion: material + cantidad
  const tbl = await page.evaluate(() => {
    let prefix = null, matCol = null, qtyCol = null;
    document.querySelectorAll('[id*="[0,"]').forEach((el) => {
      const m = el.id.match(/^(.*)\[0,(\d+)\]$/); if (!m) return;
      const t = (el.textContent || '').trim();
      if (t === 'Material') { prefix = m[1]; matCol = +m[2]; }
      if (t === 'Cantidad de pedido') { qtyCol = +m[2]; }
    });
    return { prefix, matCol, qtyCol };
  });
  const typeInCell = async (id, value) => {
    await page.locator(`[id="${id}"]`).first().click();
    await page.waitForTimeout(400);
    await page.keyboard.press('Control+A'); await page.keyboard.press('Delete');
    await page.keyboard.type(value, { delay: 15 });
    await page.keyboard.press('Enter');
    await settle(page);
  };
  await typeInCell(`${tbl.prefix}[1,${tbl.matCol}]_c`, D.material);
  if (await page.getByText('Continuar', { exact: true }).count()) { await page.getByText('Continuar', { exact: true }).last().click(); await settle(page); }
  await typeInCell(`${tbl.prefix}[1,${tbl.qtyCol}]_c`, D.cantidad);
  console.log('5) ' + (await page.title()) + ' (mat ' + D.material + ' x ' + D.cantidad + ')');

  // 6) Configuracion: NUMERO DE PARTE CLIENTE
  const cfg = await page.evaluate(() => {
    let prefix = null, row = null;
    document.querySelectorAll('[id*="_c-text"]').forEach((s) => {
      if ((s.textContent || '').trim() === 'NUMERO DE PARTE CLIENTE') {
        const m = s.id.match(/^(.*)\[(\d+),1\]_c-text$/); if (m) { prefix = m[1]; row = +m[2]; }
      }
    });
    return { prefix, row };
  });
  if (cfg.prefix) {
    const cell = page.locator(`[id="${cfg.prefix}[${cfg.row},2]_c"]`).first();
    await cell.click(); await page.waitForTimeout(400);
    await page.keyboard.press('Control+A'); await page.keyboard.press('Delete');
    await page.keyboard.type(D.parte, { delay: 15 });
    await page.keyboard.press('Enter'); await settle(page);
    console.log('6) configuracion: NUMERO DE PARTE CLIENTE = ' + D.parte);
  } else {
    console.log('6) sin pantalla de configuracion');
  }

  // 7) Grabar
  await page.getByText('Grabar', { exact: true }).last().click();
  await settle(page, 3000);
  if (await page.getByText('Continuar', { exact: true }).count()) { await page.getByText('Continuar', { exact: true }).last().click(); await settle(page, 3000); }

  const msgs = await page.evaluate(() => {
    const res = [];
    document.querySelectorAll('[role="status"], .lsMessageBar, .urMsgWng, .urMsgErr, [id*="Message"]').forEach((e) => {
      const t = (e.innerText || '').trim(); if (t && t !== 'Barra de mensajes') res.push(t.slice(0, 160));
    });
    return [...new Set(res)];
  });
  console.log('7) ' + (await page.title()));
  console.log('MENSAJES:'); msgs.forEach((m) => console.log('  ' + m));
  await page.screenshot({ path: out }).catch(() => {});
  console.log('shot=' + out);
  process.exit(0);
})();
