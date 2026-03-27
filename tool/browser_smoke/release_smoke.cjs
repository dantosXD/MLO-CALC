const { chromium } = require('playwright');
const fs = require('node:fs/promises');
const path = require('node:path');

const repoRoot = path.resolve(__dirname, '..', '..');
const outDir = path.join(repoRoot, 'output', 'playwright');
const baseUrl = process.env.SMOKE_BASE_URL || 'http://127.0.0.1:4173/';
const browserExecutablePath =
  process.env.SMOKE_BROWSER_EXECUTABLE_PATH ||
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const headless = process.env.SMOKE_HEADLESS !== 'false';
const viewport = { width: 1440, height: 960 };
const shellTabs = ['Calculator', 'Amortization', 'Qualification', 'Analysis', 'History'];
let accessibilityEnabled = false;

function escapeRegExp(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function slugify(value) {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}

async function ensureVisible(locator, label, timeout = 15000) {
  await locator.first().waitFor({ state: 'visible', timeout });
}

function getOverflowButton(page) {
  return page
    .getByRole('button', { name: /^(More|Settings)$/i })
    .first();
}

function getShellTabButton(page, name) {
  return page
    .getByRole(
      'button',
      { name: new RegExp(`^${escapeRegExp(name)}(?: Tab \\d+ of \\d+)?$`) },
    )
    .first();
}

async function enableAccessibility(page) {
  if (accessibilityEnabled) {
    return;
  }

  const overflowButton = getOverflowButton(page);
  if (await overflowButton.count()) {
    accessibilityEnabled = true;
    return;
  }

  const placeholder = page.locator(
    'flt-semantics-placeholder[aria-label="Enable accessibility"]',
  ).first();

  await placeholder.waitFor({ state: 'attached', timeout: 30000 });
  await placeholder.evaluate((el) => {
    el.click();
  });

  await overflowButton.waitFor({ state: 'visible', timeout: 30000 });
  accessibilityEnabled = true;
}

async function clickButton(page, name, timeout = 15000) {
  const locator = page
    .getByRole('button', { name: new RegExp(`^${escapeRegExp(name)}$`) })
    .first();
  await locator.waitFor({ state: 'visible', timeout });
  await locator.click();
}

async function clickCompositeButton(page, name, timeout = 15000) {
  const locator = page
    .getByRole('button', { name: new RegExp(`^${escapeRegExp(name)}(?:\\b.*)?$`) })
    .first();
  await locator.waitFor({ state: 'visible', timeout });
  await locator.click();
}

async function clickTabButton(page, name, timeout = 15000) {
  const locator = getShellTabButton(page, name);
  await locator.waitFor({ state: 'visible', timeout });
  await locator.click();
}

async function clickMenuItem(page, name, timeout = 15000) {
  const roleLocator = page
    .getByRole('menuitem', { name: new RegExp(`^${escapeRegExp(name)}$`) })
    .first();

  try {
    await roleLocator.waitFor({ state: 'visible', timeout });
    await roleLocator.click();
    return;
  } catch (_) {}

  const buttonLocator = page
    .getByRole('button', { name: new RegExp(`^${escapeRegExp(name)}$`) })
    .first();
  try {
    await buttonLocator.waitFor({ state: 'visible', timeout });
    await buttonLocator.click();
    return;
  } catch (_) {}

  const textLocator = page.getByText(name, { exact: true }).first();
  await textLocator.waitFor({ state: 'visible', timeout });
  await textLocator.click();
}

async function clickTextbox(page, name, value, timeout = 15000) {
  const locator = page
    .getByRole('textbox', { name: new RegExp(`^${escapeRegExp(name)}$`) })
    .first();
  await locator.waitFor({ state: 'visible', timeout });
  await locator.fill(value);
}

async function waitForShellReady(page) {
  await enableAccessibility(page);
  await ensureVisible(getOverflowButton(page), 'More');

  for (const tab of shellTabs) {
    await ensureVisible(getShellTabButton(page, tab), tab);
  }

  await ensureVisible(
    page.getByRole('button', { name: /^Share quote$/ }),
    'Share quote',
  );
  await ensureVisible(
    page.getByRole('button', { name: /^Voice\/Text input$/ }),
    'Voice/Text input',
  );
}

async function openMoreMenuItem(page, name) {
  await ensureVisible(getOverflowButton(page), 'More');
  await getOverflowButton(page).click();
  await clickMenuItem(page, name);
}

async function dismissToShell(page) {
  for (let i = 0; i < 2; i += 1) {
    await page.keyboard.press('Escape');
    try {
      await ensureVisible(getOverflowButton(page), 'More', 2000);
      return;
    } catch (_) {
      // Keep trying. Some modals require one escape per layer.
    }
  }

  await waitForShellReady(page);
}

async function returnFromRoute(page) {
  const backButton = page.getByRole('button', { name: /^Back$/ }).first();
  if (await backButton.count()) {
    await backButton.click();
  } else {
    await page.goBack({ waitUntil: 'domcontentloaded', timeout: 15000 }).catch(() => {});
  }

  await waitForShellReady(page);
}

async function closeDialog(page, buttonName = 'Cancel') {
  const cancelButton = page
    .getByRole('button', { name: new RegExp(`^${escapeRegExp(buttonName)}$`) })
    .last();
  await cancelButton.waitFor({ state: 'visible', timeout: 15000 });
  await cancelButton.click();
}

async function captureFailure(page, stepName, error, pageErrors, consoleErrors) {
  await fs.mkdir(outDir, { recursive: true });

  const suffix = slugify(stepName || 'smoke-failure');
  const screenshotPath = path.join(outDir, `release-smoke-${suffix}.png`);
  const logPath = path.join(outDir, `release-smoke-${suffix}.json`);

  try {
    await page.screenshot({ path: screenshotPath, fullPage: true });
  } catch (_) {
    // Ignore screenshot failures so we still preserve the error payload.
  }

  const payload = {
    step: stepName,
    url: page.url(),
    error: String(error && error.stack ? error.stack : error),
    pageErrors,
    consoleErrors,
  };

  await fs.writeFile(logPath, JSON.stringify(payload, null, 2), 'utf8');
  console.error(`Saved failure artifacts to ${screenshotPath} and ${logPath}`);
}

async function assertNoRuntimeErrors(stepName, pageErrors, consoleErrors) {
  if (pageErrors.length || consoleErrors.length) {
    const details = [
      pageErrors.length ? `page errors: ${pageErrors.join(' | ')}` : null,
      consoleErrors.length ? `console errors: ${consoleErrors.join(' | ')}` : null,
    ]
      .filter(Boolean)
      .join(' ; ');

    throw new Error(`${stepName}: ${details}`);
  }
}

async function main() {
  await fs.mkdir(outDir, { recursive: true });

  await fs.access(browserExecutablePath).catch(() => {
    throw new Error(
      `Browser executable not found at ${browserExecutablePath}. Set SMOKE_BROWSER_EXECUTABLE_PATH to override.`,
    );
  });

  const pageErrors = [];
  const consoleErrors = [];
  let currentStep = 'startup';
  let page;
  const browser = await chromium.launch({
    executablePath: browserExecutablePath,
    headless,
  });

  try {
    const context = await browser.newContext({ viewport });
    page = await context.newPage();
    page.setDefaultTimeout(15000);

    page.on('pageerror', (error) => {
      pageErrors.push(error.stack || error.message || String(error));
    });
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        consoleErrors.push(msg.text());
      }
    });

    async function step(name, fn) {
      currentStep = name;
      console.log(`STEP_START ${name}`);
      await fn();
      await assertNoRuntimeErrors(name, pageErrors, consoleErrors);
      console.log(`STEP_OK ${name}`);
    }

    await step('load shell', async () => {
      await page.goto(baseUrl, {
        waitUntil: 'domcontentloaded',
        timeout: 60000,
      });
      await waitForShellReady(page);
    });

    await step('assert shell controls', async () => {
      for (const tab of shellTabs) {
        await ensureVisible(getShellTabButton(page, tab), tab);
      }

      await ensureVisible(getOverflowButton(page), 'More');
      await ensureVisible(
        page.getByRole('button', { name: /^Share quote$/ }),
        'Share quote',
      );
      await ensureVisible(
        page.getByRole('button', { name: /^Voice\/Text input$/ }),
        'Voice/Text input',
      );
    });

    await step('qualification empty-name validation', async () => {
      await clickTabButton(page, 'Qualification');
      await clickButton(page, 'Manage Ratios');
      await ensureVisible(
        page.getByText('Qualifying Ratios', { exact: true }),
        'Qualifying Ratios',
      );

      await page.getByRole('button').first().click();
      await ensureVisible(
        page.getByText('Add Custom Ratio', { exact: true }),
        'Add Custom Ratio',
      );

      await page.getByRole('button', { name: /^Add$/ }).last().click();
      await closeDialog(page, 'Cancel');
      await ensureVisible(
        page.getByText('Please enter a name', { exact: true }),
        'Please enter a name',
      );
      await dismissToShell(page);
    });

    await step('workspace dashboard return', async () => {
      await openMoreMenuItem(page, 'Workspace Dashboard');
      await ensureVisible(
        page.getByText('Workspace Dashboard', { exact: true }),
        'Workspace Dashboard',
      );
      await ensureVisible(
        page.getByRole('button', { name: /^Open$/ }),
        'Open',
      );
      await clickButton(page, 'Open');
      await waitForShellReady(page);
    });

    await step('loan programs route', async () => {
      await openMoreMenuItem(page, 'Loan Programs');
      await ensureVisible(page.getByText('Loan Programs', { exact: true }), 'Loan Programs');
      await ensureVisible(
        page.getByText('Built-in Programs', { exact: true }),
        'Built-in Programs',
      );
      await ensureVisible(
        page.getByRole('group', { name: /Conventional 30-Year/ }).first(),
        'Conventional 30-Year',
      );
      await returnFromRoute(page);
    });

    await step('rent vs buy fractional term', async () => {
      await openMoreMenuItem(page, 'Rent vs Buy');
      await ensureVisible(
        page.getByText('Rent vs Buy Analysis', { exact: true }),
        'Rent vs Buy Analysis',
      );
      await clickTextbox(page, 'Term', '7.5');
      await clickButton(page, 'Calculate');
      await ensureVisible(page.getByText(/Renting May Be Better/), 'Renting May Be Better');
      await ensureVisible(page.getByText(/Break-even:/), 'Break-even:');
      await returnFromRoute(page);
    });

    await step('share quote dialog', async () => {
      await clickButton(page, 'Share quote');
      await ensureVisible(page.getByText('Share Quote', { exact: true }), 'Share Quote');
      await closeDialog(page, 'Cancel');
    });

    await step('voice text dialog', async () => {
      await clickButton(page, 'Voice/Text input');
      await ensureVisible(
        page.getByText('Voice Assistant', { exact: true }),
        'Voice Assistant',
      );
      await ensureVisible(
        page.getByRole('checkbox', {
          name: /^Calculate payment for a \$350,000 loan at 5\.5% for 30 years$/,
        }),
        'sample prompt',
      );
      await page.getByRole('checkbox', {
        name: /^Calculate payment for a \$350,000 loan at 5\.5% for 30 years$/,
      }).click();
      await clickButton(page, 'Process');
      await ensureVisible(
        page.getByText('Error: Add your Gemini API key in Settings.', {
          exact: true,
        }),
        'Add your Gemini API key in Settings.',
      );
      await closeDialog(page, 'Cancel');
    });

    await step('analysis and arm wizard', async () => {
      await clickTabButton(page, 'Analysis');
      await clickCompositeButton(page, 'PDF Report');
      await clickTabButton(page, 'Calculator');
      await waitForShellReady(page);

      await clickTabButton(page, 'Analysis');
      await clickCompositeButton(page, 'ARM Wizard');
      await ensureVisible(page.getByText('ARM Wizard', { exact: true }), 'ARM Wizard');
      await clickButton(page, 'Generate schedule');
      await ensureVisible(
        page.getByRole('group', { name: /^ARM Schedule$/ }),
        'ARM Schedule',
      );
      await ensureVisible(page.getByText(/Months 1-60/), 'ARM schedule row');
      await returnFromRoute(page);
    });

    await step('utility dialogs', async () => {
      await openMoreMenuItem(page, 'How to Use');
      await ensureVisible(page.getByText('How to Use', { exact: true }), 'How to Use');
      await closeDialog(page, 'Got it');

      await openMoreMenuItem(page, 'Calculator Layout Preview');
      await ensureVisible(page.getByText('Choose Layout', { exact: true }), 'Choose Layout');
      await returnFromRoute(page);

      await openMoreMenuItem(page, 'Toggle theme');
      await waitForShellReady(page);

      await openMoreMenuItem(page, 'API Key');
      await ensureVisible(page.getByText('Gemini API Key', { exact: true }), 'Gemini API Key');
      await ensureVisible(
        page.getByText(
          'Your key is stored locally on this device using secure storage.',
          { exact: true },
        ),
        'secure storage message',
      );
      await dismissToShell(page);
    });

    await assertNoRuntimeErrors('final', pageErrors, consoleErrors);
    console.log('Release browser smoke passed.');
  } catch (error) {
    try {
      if (page) {
        await captureFailure(page, currentStep, error, pageErrors, consoleErrors);
      }
    } catch (_) {
      // Ignore artifact capture errors here; the original error still matters.
    }

    throw error;
  } finally {
    if (browser) {
      await browser.close().catch(() => {});
    }
  }
}

main().catch(async (error) => {
  console.error(error);
  process.exitCode = 1;
});
