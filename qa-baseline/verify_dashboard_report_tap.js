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

  await page.evaluate(() => {
    window.scrollBy({ top: 520, behavior: 'instant' });
  });

  await new Promise((resolve) => setTimeout(resolve, 600));

  await page.evaluate(() => {
    const nodes = Array.from(
      document.querySelectorAll('flt-semantics, [role="button"], button, div, span'),
    );

    const target = nodes.find((node) =>
      ((node.textContent || '').toLowerCase().includes('daily participation')),
    );

    if (target) target.click();
  });

  await new Promise((resolve) => setTimeout(resolve, 1200));

  const hasReports = await page.evaluate(() =>
    document.body.innerText.toLowerCase().includes('reports dashboard'),
  );

  console.log('reports_opened=' + hasReports);
  await browser.close();

  if (!hasReports) {
    process.exit(2);
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
