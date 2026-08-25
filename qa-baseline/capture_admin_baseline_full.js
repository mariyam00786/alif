const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const outDir = path.join(process.cwd(), 'qa-baseline', 'admin-mobile-2026-06-24');
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function clickByText(page, text) {
  await page.evaluate((label) => {
    const nodes = Array.from(document.querySelectorAll('flt-semantics, [role="button"], button, div, span'));
    const matches = nodes.filter((n) => ((n.innerText || n.textContent || '').trim() === label));
    const target = matches[matches.length - 1];
    if (target) {
      target.click();
    }
  }, text);
}

async function ensureReady(page) {
  await page.goto('http://localhost:5002', { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForFunction(() => !!document.querySelector('flutter-view'), { timeout: 120000 });
  await page.evaluate(() => {
    const placeholder = document.querySelector('flt-semantics-placeholder, [aria-label="Enable accessibility"]');
    if (placeholder) placeholder.click();
  });
  await sleep(1000);
}

async function openSectionViaMore(page, label) {
  await clickByText(page, 'More');
  await sleep(400);
  await clickByText(page, label);
  await sleep(900);
}

async function main() {
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2 });

  await ensureReady(page);
  await page.screenshot({ path: path.join(outDir, '01-dashboard-mobile.png'), fullPage: true });

  await openSectionViaMore(page, 'Reports');
  await page.screenshot({ path: path.join(outDir, '02-reports-mobile.png'), fullPage: true });

  await clickByText(page, 'Teachers');
  await sleep(700);
  await clickByText(page, 'Add Teacher');
  await sleep(700);
  await page.screenshot({ path: path.join(outDir, '03-teacher-add-sheet-mobile.png'), fullPage: true });
  await clickByText(page, 'Cancel');
  await sleep(500);

  await openSectionViaMore(page, 'Batches & Classes');
  await clickByText(page, 'Add Batch');
  await sleep(700);
  await page.screenshot({ path: path.join(outDir, '04-batch-add-sheet-mobile.png'), fullPage: true });
  await clickByText(page, 'Cancel');
  await sleep(500);

  await clickByText(page, 'Activities');
  await sleep(700);
  await clickByText(page, 'Add Activity');
  await sleep(700);
  await page.screenshot({ path: path.join(outDir, '05-activity-add-sheet-mobile.png'), fullPage: true });
  await clickByText(page, 'Cancel');
  await sleep(500);

  await openSectionViaMore(page, 'Badges');
  await page.screenshot({ path: path.join(outDir, '06-badge-add-sheet-mobile.png'), fullPage: true });

  await openSectionViaMore(page, 'Reports');
  await page.evaluate(() => {
    const nodes = Array.from(document.querySelectorAll('flt-semantics, [role="button"], button, div, span'));
    const tile = nodes.find((n) => {
      const t = (n.innerText || n.textContent || '').replace(/\s+/g, ' ').trim();
      return t.startsWith('Daily report ');
    });
    if (tile) tile.click();
  });
  await sleep(700);
  await page.screenshot({ path: path.join(outDir, '07-reports-after-daily-click-mobile.png'), fullPage: true });

  await browser.close();
  console.log('baseline-capture-complete');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
