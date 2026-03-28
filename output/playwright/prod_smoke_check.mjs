import { chromium } from 'playwright';
import { mkdir } from 'node:fs/promises';

const baseUrl = process.env.APP_URL ?? 'http://127.0.0.1:8090';
const outDir = 'output/playwright';

await mkdir(outDir, { recursive: true });

const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({ viewport: { width: 1440, height: 960 } });
const page = await context.newPage();

const consoleErrors = [];
page.on('console', (msg) => {
  if (msg.type() === 'error') {
    consoleErrors.push(msg.text());
  }
});

const pageErrors = [];
page.on('pageerror', (error) => {
  pageErrors.push(String(error));
});
const flowErrors = [];
console.log('SMOKE_START');

async function shot(name) {
  await page.screenshot({ path: `${outDir}/${name}.png`, fullPage: true });
}

async function waitForApp() {
  for (let i = 0; i < 20; i += 1) {
    try {
      await page.goto(baseUrl, { waitUntil: 'domcontentloaded', timeout: 5000 });
      await page.waitForFunction(() => document.title.includes('MLO-Calc'), null, {
        timeout: 5000,
      });
      return;
    } catch {
      await page.waitForTimeout(1000);
    }
  }
  throw new Error(`App did not become available at ${baseUrl}`);
}

async function openMainTab(name, shotName) {
  await page.getByText(name, { exact: true }).first().click();
  await page.waitForTimeout(800);
  await shot(shotName);
}

async function step(name, fn) {
  try {
    console.log(`STEP_START ${name}`);
    await fn();
    console.log(`STEP_OK ${name}`);
  } catch (error) {
    console.log(`STEP_FAIL ${name}`);
    flowErrors.push(`${name}: ${String(error)}`);
  }
}

await waitForApp();
console.log('APP_READY');
await shot('01-home');

// Calculator smoke
await step('calculator visible', async () => {
  await page.getByText('Calculator', { exact: true }).first().waitFor({ timeout: 5000 });
});
await shot('02-calculator-arithmetic');

// Share quote dialog smoke
await step('share quote dialog', async () => {
  await page.getByRole('button', { name: 'Share quote' }).click();
  await page.getByText('Share').first().waitFor({ timeout: 5000 });
  await shot('03-share-dialog');
  await page.keyboard.press('Escape');
});

// Voice/text dialog smoke
await step('voice dialog', async () => {
  await page.getByRole('button', { name: 'Voice/Text input' }).click();
  await page.getByText('Voice Assistant').first().waitFor({ timeout: 5000 });
  await shot('04-voice-dialog');
  await page.keyboard.press('Escape');
});

// Main navigation tabs
await step('open amortization tab', async () => openMainTab('Amortization', '05-amortization'));
await step('open qualification tab', async () => openMainTab('Qualification', '06-qualification'));
await step('open analysis tab', async () => openMainTab('Analysis', '07-analysis'));
await step('open history tab', async () => openMainTab('History', '08-history'));
await step('return calculator tab', async () => openMainTab('Calculator', '09-calculator-return'));

// Settings menu routes
await step('open loan programs', async () => {
  await page.getByRole('button', { name: 'More' }).click();
  await page.getByText('Loan Programs', { exact: true }).click();
  await page.waitForTimeout(1200);
  await shot('10-loan-programs');
  await page.goBack();
  await page.waitForTimeout(800);
});

await step('open rent vs buy', async () => {
  await page.getByRole('button', { name: 'More' }).click();
  await page.getByText('Rent vs Buy', { exact: true }).click();
  await page.waitForTimeout(1200);
  await shot('11-rent-vs-buy');
  await page.goBack();
  await page.waitForTimeout(800);
});

await step('open API key sheet', async () => {
  await page.getByRole('button', { name: 'More' }).click();
  await page.getByText('API Key', { exact: true }).click();
  await page.getByText('Gemini API Key').first().waitFor({ timeout: 5000 });
  await shot('12-api-key-sheet');
  await page.keyboard.press('Escape');
});

await shot('13-final-state');
console.log('FLOW_DONE');

await browser.close();

if (pageErrors.length > 0) {
  throw new Error(`Page errors detected: ${pageErrors.join(' | ')}`);
}

if (consoleErrors.length > 0) {
  throw new Error(`Console errors detected: ${consoleErrors.join(' | ')}`);
}

if (flowErrors.length > 0) {
  throw new Error(`Flow errors detected: ${flowErrors.join(' | ')}`);
}

console.log('Smoke verification passed.');
