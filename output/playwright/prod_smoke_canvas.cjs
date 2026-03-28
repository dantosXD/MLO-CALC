const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const outDir = 'output/playwright';
  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 1440, height: 960 } });
  const baseUrl = process.env.APP_URL || 'http://127.0.0.1:8092';

  const pageErrors = [];
  const consoleErrors = [];
  page.on('pageerror', (e) => pageErrors.push(String(e)));
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  const shot = async (name) => {
    await page.screenshot({ path: `${outDir}/${name}.png` });
  };

  await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });
  await page.waitForTimeout(20000);
  await shot('canvas-01-home');

  // Focus calculator and run keyboard arithmetic: 9 + 1 = 10
  await page.mouse.click(720, 520);
  await page.keyboard.press('Digit9');
  await page.keyboard.press('Equal'); // '+' on many layouts with shift, fallback
  await page.keyboard.press('Shift+Equal'); // explicit '+'
  await page.keyboard.press('Digit1');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(800);
  await shot('canvas-02-calculator-keyboard');

  // Left rail navigation (desktop layout)
  await page.mouse.click(80, 120); // Amortization
  await page.waitForTimeout(1200);
  await shot('canvas-03-amortization');

  await page.mouse.click(80, 156); // Qualification
  await page.waitForTimeout(1200);
  await shot('canvas-04-qualification');

  await page.mouse.click(80, 190); // Analysis
  await page.waitForTimeout(1200);
  await shot('canvas-05-analysis');

  await page.mouse.click(80, 226); // History
  await page.waitForTimeout(1200);
  await shot('canvas-06-history');

  await page.mouse.click(80, 84); // Calculator
  await page.waitForTimeout(1200);
  await shot('canvas-07-calculator-return');

  // Top-right actions
  await page.mouse.click(1360, 24); // Share icon
  await page.waitForTimeout(1000);
  await shot('canvas-08-share');
  await page.keyboard.press('Escape');

  await page.mouse.click(1400, 24); // Mic icon
  await page.waitForTimeout(1000);
  await shot('canvas-09-voice');
  await page.keyboard.press('Escape');

  await page.mouse.click(1430, 24); // Settings/menu icon
  await page.waitForTimeout(800);
  await shot('canvas-10-settings-menu');
  // Menu item click positions are approximate, each followed by back.
  await page.mouse.click(1320, 220); // Loan Programs
  await page.waitForTimeout(1200);
  await shot('canvas-11-loan-programs');
  await page.goBack();
  await page.waitForTimeout(1200);

  await page.mouse.click(1430, 24); // Settings/menu icon
  await page.waitForTimeout(700);
  await page.mouse.click(1320, 260); // Rent vs Buy
  await page.waitForTimeout(1200);
  await shot('canvas-12-rent-vs-buy');
  await page.goBack();
  await page.waitForTimeout(1200);

  await page.mouse.click(1430, 24); // Settings/menu icon
  await page.waitForTimeout(700);
  await page.mouse.click(1320, 300); // API Key
  await page.waitForTimeout(1000);
  await shot('canvas-13-api-key');
  await page.keyboard.press('Escape');

  await shot('canvas-14-final');
  await browser.close();

  if (pageErrors.length) {
    throw new Error(`Page errors: ${pageErrors.join(' | ')}`);
  }
  if (consoleErrors.length) {
    throw new Error(`Console errors: ${consoleErrors.join(' | ')}`);
  }
  console.log('Canvas smoke verification complete.');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
