import { chromium } from 'playwright'; console.log('probe-start'); const b = await chromium.launch({headless:true}); console.log('probe-launched'); await b.close(); console.log('probe-done');
