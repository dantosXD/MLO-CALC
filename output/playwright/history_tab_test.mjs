import { chromium } from 'playwright';

async function setup(page) {
  await page.goto('http://127.0.0.1:4173/');
  await page.waitForTimeout(65000);
  const enable = page.locator('flt-semantics-placeholder[aria-label="Enable accessibility"]');
  if (await enable.count()) {
    await enable.first().evaluate((el) => el.click());
    await page.waitForTimeout(1500);
  }
}

const browser = await chromium.launch({
  executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  headless: true,
});
const page = await browser.newPage({ viewport: { width: 1440, height: 1400 } });
const errors = [];
page.on('pageerror', (err) => errors.push('pageerror: ' + err.message));
page.on('console', (msg) => { if (msg.type() === 'error') errors.push('console error: ' + msg.text()); });
await setup(page);
await page.getByRole('button', { name: /^History/ }).first().click();
await page.waitForTimeout(2000);
await page.screenshot({ path: 'output/playwright/history-tab.png', fullPage: true });
console.log('TEXT', (await page.locator('body').innerText()).slice(0, 2000));
console.log('ERRORS', JSON.stringify(errors, null, 2));
await browser.close();
