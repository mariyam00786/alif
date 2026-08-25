const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const OUT_DIR = path.join(__dirname, 'qa-baseline', 'admin-mobile-2026-06-24');
const BASE_URL = 'http://localhost:5002';

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function clickText(page, text) {
  return page.evaluate((label) => {
    const nodes = Array.from(
      document.querySelectorAll('flt-semantics,[role="button"],button,div,span')
    );
    const matches = nodes.filter((n) => (n.innerText || n.textContent || '').trim() === label);
    const target = matches[matches.length - 1];
    if (!target) return false;
    target.click();
    return true;
  }, text);
}

async function clickStartsWith(page, prefix) {
  return page.evaluate((labelPrefix) => {
    const nodes = Array.from(
      document.querySelectorAll('flt-semantics,[role="button"],button,div,span')
    );
    const matches = nodes.filter((n) => {
      const text = (n.innerText || n.textContent || '').replace(/\s+/g, ' ').trim();
      return text.startsWith(labelPrefix);
    });
    const target = matches[matches.length - 1];
    if (!target) return false;
    target.click();
    return true;
  }, prefix);
}

async function closeSheet(page) {
  const closed = await clickText(page, 'Cancel');
  if (closed) await delay(250);
}

async function openMoreAndSelect(page, label) {
  await clickText(page, 'More');
  await delay(220);
  return clickText(page, label);
}

async function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  const browser = await puppeteer.launch({ headless: true });
  try {
    const page = await browser.newPage();
    await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2 });
    await page.goto(BASE_URL, { waitUntil: 'networkidle2', timeout: 120000 });

    await page.waitForFunction(() => !!document.querySelector('flutter-view'), {
      timeout: 120000,
    });

    await page.evaluate(() => {
      const ph = document.querySelector('flt-semantics-placeholder,[aria-label="Enable accessibility"]');
      if (ph) ph.click();
    });
    await delay(600);

    await page.screenshot({
      path: path.join(OUT_DIR, '01-dashboard-mobile.png'),
      fullPage: false,
    });

    await openMoreAndSelect(page, 'Reports');
    await delay(350);
    await page.screenshot({
      path: path.join(OUT_DIR, '02-reports-mobile.png'),
      fullPage: false,
    });

    await clickText(page, 'Teachers');
    await delay(280);
    await clickText(page, 'Add Teacher');
    await delay(280);
    await page.screenshot({
      path: path.join(OUT_DIR, '03-teacher-add-sheet-mobile.png'),
      fullPage: false,
    });
    await closeSheet(page);

    await openMoreAndSelect(page, 'Batches & Classes');
    await delay(280);
    await clickText(page, 'Add Batch');
    await delay(280);
    await page.screenshot({
      path: path.join(OUT_DIR, '04-batch-add-sheet-mobile.png'),
      fullPage: false,
    });
    await closeSheet(page);

    await clickText(page, 'Activities');
    await delay(280);
    await clickText(page, 'Add Activity');
    await delay(280);
    await page.screenshot({
      path: path.join(OUT_DIR, '05-activity-add-sheet-mobile.png'),
      fullPage: false,
    });
    await closeSheet(page);

    await openMoreAndSelect(page, 'Badges');
    await delay(280);
    await clickText(page, 'Add Badge');
    await delay(280);
    await page.screenshot({
      path: path.join(OUT_DIR, '06-badge-add-sheet-mobile.png'),
      fullPage: false,
    });
    await closeSheet(page);

    await clickStartsWith(page, 'Daily report ');
    await delay(220);
    await page.screenshot({
      path: path.join(OUT_DIR, '07-reports-after-daily-click-mobile.png'),
      fullPage: false,
    });

    console.log('Baseline screenshots captured in:', OUT_DIR);
  } finally {
    await browser.close();
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
