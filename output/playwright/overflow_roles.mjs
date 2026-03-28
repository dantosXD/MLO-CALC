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
await page.getByRole('button', { name: 'More' }).click();
await page.waitForTimeout(1000);
for (const role of ['menuitem','button','link']) {
  const loc = page.getByRole(role);
  const count = await loc.count();
  const names = [];
  for (let i = 0; i < count; i++) {
    const el = loc.nth(i);
    names.push(((await el.getAttribute('aria-label')) || (await el.textContent()) || '').trim());
  }
  console.log(role.toUpperCase(), count, JSON.stringify(names));
}
await browser.close();
