const puppeteer = require('puppeteer');
const path = require('path');

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function clickByText(page, text) {
  await page.evaluate((label) => {
    const nodes = Array.from(document.querySelectorAll('flt-semantics, [role="button"], button, div, span'));
    const exact = nodes.filter((n) => ((n.innerText || n.textContent || '').trim() === label));
    const target = exact[exact.length - 1];
    if (target) target.click();
  }, text);
}

async function main() {
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2 });

  await page.goto('http://localhost:5002', { waitUntil: 'domcontentloaded', timeout: 120000 });
  await page.waitForFunction(() => !!document.querySelector('flutter-view'), { timeout: 120000 });
  await page.evaluate(() => {
    const ph = document.querySelector('flt-semantics-placeholder, [aria-label="Enable accessibility"]');
    if (ph) ph.click();
  });

  await sleep(800);
  await clickByText(page, 'Activities');
  await sleep(900);

  const out = path.join(process.cwd(), 'qa-baseline', 'activity-after-current.png');
  await page.screenshot({ path: out, fullPage: true });
  console.log(out);

  await browser.close();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
