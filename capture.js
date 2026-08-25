const puppeteer = require('puppeteer');
(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.setViewport({width: 1440, height: 900});
  await page.goto('https://app.guestifynow.com', {waitUntil: 'networkidle2'});
  await page.screenshot({path: 'guestify.png', fullPage: true});
  await browser.close();
})();
