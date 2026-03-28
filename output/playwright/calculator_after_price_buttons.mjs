import { chromium } from 'playwright';

const browser = await chromium.launch({
  executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  headless: true,
});
const page = await browser.newPage({ viewport: { width: 1440, height: 1400 } });
await page.goto('http://127.0.0.1:4173/');
await page.waitForTimeout(65000);
const enable = page.locator('flt-semantics-placeholder[aria-label="Enable accessibility"]');
if (await enable.count()) {
  await enable.first().evaluate((el) => el.click());
  await page.waitForTimeout(1500);
}
await page.getByRole('button', { name: 'Price' }).first().click({ force: true });
await page.keyboard.type('400000');
await page.waitForTimeout(500);
const buttons = page.getByRole('button');
const count = await buttons.count();
const names = [];
for (let i = 0; i < count; i++) {
  const btn = buttons.nth(i);
  names.push(((await btn.getAttribute('aria-label')) || (await btn.textContent()) || '').trim());
}
console.log(JSON.stringify(names, null, 2));
await browser.close();
