import { chromium } from 'playwright';
import path from 'path';

const browser = await chromium.launch({
  executablePath: 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
  headless: true,
});

const page = await browser.newPage({ viewport: { width: 1440, height: 1400 } });
const errors = [];
page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
page.on('console', (msg) => {
  if (msg.type() === 'error') errors.push(`console error: ${msg.text()}`);
});

await page.goto('http://127.0.0.1:4173/');
await page.getByRole('button', { name: 'Enable accessibility' }).evaluate((el) => el.click());
await page.waitForTimeout(1500);

const tabs = ['Calculator', 'Amortization', 'Qualification', 'Analysis', 'History'];
for (const tab of tabs) {
  await page.getByRole('button', { name: new RegExp(`^${tab}`) }).first().click();
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join('output', 'playwright', `${tab.toLowerCase()}.png`), fullPage: true });
  console.log(`VISITED ${tab}`);
}

console.log('ERRORS', JSON.stringify(errors, null, 2));
await browser.close();
