const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox'] });
  const page = await browser.newPage();
  await page.setViewport({ width: 390, height: 844, deviceScaleFactor: 2 });

  await page.goto('http://localhost:5002', {
    waitUntil: 'domcontentloaded',
    timeout: 120000,
  });

  await page.waitForFunction(() => !!document.querySelector('flutter-view'), {
    timeout: 120000,
  });

  await page.evaluate(() => {
    const placeholder = document.querySelector(
      'flt-semantics-placeholder, [aria-label="Enable accessibility"]',
    );
    if (placeholder) placeholder.click();
  });

  await new Promise((resolve) => setTimeout(resolve, 1200));

  await page.screenshot({
    path: 'qa-baseline/change-report-2026-06-25/admin-logo-verify.png',
    fullPage: false,
  });

  await browser.close();
  console.log('saved=qa-baseline/change-report-2026-06-25/admin-logo-verify.png');
})().catch((err) => {
  console.error(err);
  process.exit(1);
});
