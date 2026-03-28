const { chromium } = require('playwright');
const fs = require('fs');

(async () => {
  const baseUrl = 'http://127.0.0.1:8090';
  const outDir = 'output/playwright';
  fs.mkdirSync(outDir, { recursive: true });

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 960 } });
  const page = await context.newPage();

  const flowErrors = [];
  const consoleErrors = [];
  const pageErrors = [];

  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('pageerror', (error) => pageErrors.push(String(error)));

  const shot = async (name) => {
    await page.screenshot({ path: `${outDir}/${name}.png`, fullPage: true });
  };

  const step = async (name, fn) => {
    try {
      console.log(`STEP_START ${name}`);
      await fn();
      console.log(`STEP_OK ${name}`);
    } catch (error) {
      console.log(`STEP_FAIL ${name}`);
      flowErrors.push(`${name}: ${String(error)}`);
    }
  };

  for (let i = 0; i < 20; i += 1) {
    try {
      await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 5000 });
      const title = await page.title();
      if (title.includes('MLO-Calc')) break;
    } catch (_) {}
    await page.waitForTimeout(1000);
  }

  await shot('01-home');

  await step('open share dialog', async () => {
    await page.getByRole('button', { name: 'Share quote' }).click({ timeout: 5000 });
    await page.getByText('Share').first().waitFor({ timeout: 5000 });
    await shot('02-share-dialog');
    await page.keyboard.press('Escape');
  });

  await step('open voice dialog', async () => {
    await page.getByRole('button', { name: 'Voice/Text input' }).click({ timeout: 5000 });
    await page.getByText('Voice Assistant').first().waitFor({ timeout: 5000 });
    await shot('03-voice-dialog');
    await page.keyboard.press('Escape');
  });

  const tabs = [
    ['Amortization', '04-amortization'],
    ['Qualification', '05-qualification'],
    ['Analysis', '06-analysis'],
    ['History', '07-history'],
    ['Calculator', '08-calculator'],
  ];
  for (const [name, image] of tabs) {
    await step(`tab ${name}`, async () => {
      await page.getByText(name, { exact: true }).first().click({ timeout: 5000 });
      await page.waitForTimeout(700);
      await shot(image);
    });
  }

  await step('open loan programs', async () => {
    await page.getByRole('button', { name: 'More' }).click({ timeout: 5000 });
    await page.getByText('Loan Programs', { exact: true }).click({ timeout: 5000 });
    await page.waitForTimeout(900);
    await shot('09-loan-programs');
    await page.goBack();
  });

  await step('open rent vs buy', async () => {
    await page.getByRole('button', { name: 'More' }).click({ timeout: 5000 });
    await page.getByText('Rent vs Buy', { exact: true }).click({ timeout: 5000 });
    await page.waitForTimeout(900);
    await shot('10-rent-vs-buy');
    await page.goBack();
  });

  await step('open api key sheet', async () => {
    await page.getByRole('button', { name: 'More' }).click({ timeout: 5000 });
    await page.getByText('API Key', { exact: true }).click({ timeout: 5000 });
    await page.getByText('Gemini API Key').first().waitFor({ timeout: 5000 });
    await shot('11-api-key');
    await page.keyboard.press('Escape');
  });

  await shot('12-final');
  await browser.close();

  if (pageErrors.length) throw new Error(`Page errors: ${pageErrors.join(' | ')}`);
  if (consoleErrors.length) throw new Error(`Console errors: ${consoleErrors.join(' | ')}`);
  if (flowErrors.length) throw new Error(`Flow errors: ${flowErrors.join(' | ')}`);

  console.log('Smoke verification passed.');
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
