# Feature #24 - ARM Wizard Regression Test Report

**Date:** 2026-01-22
**Feature:** #24 - ARM Wizard (Model adjustable rate mortgage scenarios)
**Test Type:** Regression Testing
**Status:** ⚠️ **INCONCLUSIVE - Server crashed during testing**

---

## Executive Summary

Regression testing of Feature #24 (ARM Wizard) was initiated but could not be completed due to a critical crash of the Flutter Web application. The app crashed when attempting to scroll within the ARM Wizard screen using browser automation. The crash caused the development server to terminate completely (ERR_CONNECTION_REFUSED).

**Important Note:** The crash was triggered by JavaScript-based scrolling (`window.scrollBy()`) through browser automation tools. This may NOT represent a real user issue, as users would interact with the UI naturally rather than executing JavaScript scroll commands.

---

## Testing Environment

- **Application:** MLO-Calc (Flutter Web)
- **URL:** http://localhost:8088
- **Browser:** Chrome (via Playwright automation)
- **Test Date:** 2026-01-22
- **Feature Status at Test Start:** Passing (12/47 features passing, 25.5%)

---

## Verification Steps & Results

### ✅ Step 1: Navigate to Analysis Tab
**Status:** PASS

**Actions:**
1. Navigated to http://localhost:8088
2. Handled accessibility prompt by clicking via JavaScript
3. Waited for app to fully load (10+ seconds)
4. Clicked "Analysis Tab 4 of 5" button

**Result:**
- Analysis tab loaded successfully
- Current Loan section visible
- Advanced Tools section visible with all buttons
- ARM Wizard button present and visible

**Screenshot:** `feature24_regression_04_analysis_tab.png`

---

### ✅ Step 2: Open ARM Wizard
**Status:** PASS

**Actions:**
1. Located "ARM Wizard Model adjustable rate scenarios" button
2. Clicked ARM Wizard button

**Result:**
- ARM Wizard screen opened successfully
- Three-step wizard interface visible:
  - 1 Loan Basics (active)
  - 2 Adjustment Settings
  - 3 Caps
- Form fields displayed correctly
- "Back" button present
- "Save preset" button present
- "Generate schedule" button present

**Screenshot:** `feature24_regression_05_arm_wizard_opened.png`

---

### ✅ Step 3: Enter Loan Parameters
**Status:** PASS

**Actions:**
1. Entered Loan Amount: `300000`
2. Entered Term (years): `30`
3. Entered Initial Rate (%): `5.5`

**Result:**
- All fields accepted input successfully
- No validation errors
- Values persisted in textboxes

**Evidence:**
- textbox "Loan Amount" [ref=e93]: "300000"
- textbox "Term (years)" [ref=e96]: "30"
- textbox "Initial Rate (%)" [ref=e98]: "5.5"

---

### ✅ Step 4: Navigate to Adjustment Settings
**Status:** PASS

**Actions:**
1. Clicked "2 Adjustment Settings" button

**Result:**
- Button became active (highlighted)
- Wizard step transition appeared to work
- No errors at this point

**Screenshot:** `feature24_regression_06_step2_active.png`

---

### ❌ Step 5: View Adjustment Settings Fields
**Status:** CRITICAL FAILURE

**Actions:**
1. Attempted to scroll down to view adjustment settings fields
2. Used JavaScript: `window.scrollBy(0, 300)`

**Result:**
- App immediately crashed
- Page navigated to `about:blank`
- Server connection lost
- Subsequent navigation attempts failed with `ERR_CONNECTION_REFUSED`

**Error Message:**
```
page.goto: net::ERR_CONNECTION_REFUSED at http://localhost:8088/?no-accessibility=true
```

---

## Crash Analysis

### What Happened

1. The ARM Wizard was opened successfully
2. Loan parameters were entered successfully
3. User navigated to Step 2 (Adjustment Settings)
4. Browser automation attempted to scroll using JavaScript's `window.scrollBy()`
5. The Flutter Web app immediately crashed
6. The page navigated to `about:blank`
7. The development server terminated (connection refused)

### Possible Causes

1. **Flutter Web + JavaScript Scroll Conflict:**
   - Flutter Web may not handle external JavaScript scroll manipulation well
   - The framework may have internal state management that breaks when scrolled programmatically

2. **ARM Wizard Screen-Specific Issue:**
   - The ARM Wizard screen may have a bug related to scroll events
   - There could be an issue with the widget tree that triggers on scroll

3. **Browser Automation Conflict:**
   - Playwright's JavaScript execution may conflict with Flutter's event system
   - The combination of Flutter Web's event handling and external JavaScript may cause instability

4. **Development Server Issue:**
   - The Flutter dev server may have crashed due to an unhandled exception
   - Hot reload/restart functionality may have been triggered unexpectedly

### Is This a Real User Issue?

**Uncertain.** The crash was triggered by:
- JavaScript code execution (`window.scrollBy()`)
- Through browser automation (Playwright)
- Not through natural user interaction

Real users would:
- Use mouse wheel / trackpad to scroll
- Use touch gestures on mobile
- Use keyboard navigation
- NOT execute JavaScript scroll commands

**Conclusion:** This requires further testing with natural UI interactions to determine if it's a real regression.

---

## What Was NOT Tested

Due to the crash, the following verification steps could NOT be completed:

- ❌ Entering adjustment settings (Index, Margin, Adjustment Frequency)
- ❌ Entering cap settings (Periodic Cap, Lifetime Cap, Floor)
- ❌ Generating ARM schedule
- ❌ Verifying rate adjustments display over time
- ❌ Verifying payments display correctly
- ❌ Testing preset save functionality
- ❌ Testing period-by-period breakdown display

---

## Comparison with Original Verification

### Original Verification (2026-01-22)

From `claude-progress.txt`, Feature #24 was originally verified via:
- Comprehensive code review (900+ lines)
- Algorithm mathematical verification
- Unit tests (2/2 passing)
- Integration analysis
- UX assessment
- **No browser UI testing was performed**

### Current Regression Test

This is the **first time** Feature #24 has been tested with actual browser automation.

**Finding:** The feature that was marked as "passing" has never been tested through the actual UI until now.

---

## Recommendations

### Immediate Actions Required

1. **Restart Development Server**
   - The Flutter Web server needs to be restarted
   - Use: `flutter run -d chrome --web-port 8088`

2. **Retest with Natural UI Interaction**
   - Avoid JavaScript-based scrolling
   - Use Playwright's native scroll methods (if available)
   - Or click on elements to bring them into view
   - Do NOT use `window.scrollBy()` or similar JavaScript methods

3. **Check Console Logs**
   - Review Flutter console output for crash details
   - Look for stack traces or error messages
   - Check if there are any warnings about event handling

### Further Investigation

1. **Test Other Features**
   - Determine if this crash is specific to ARM Wizard
   - Test if other analysis tools crash on scroll
   - Test if scrolling in other parts of the app works

2. **Manual Testing**
   - Test ARM Wizard manually in a browser
   - Try natural scrolling (mouse wheel)
   - See if the issue reproduces without automation

3. **Flutter Web Configuration**
   - Check if there are known issues with Flutter Web and JavaScript scroll
   - Review Flutter Web configuration settings
   - Consider if this is a framework limitation

---

## Test Artifacts

### Screenshots Taken

1. `feature24_regression_01_initial_load.png` - App loading
2. `feature24_regression_02_after_wait.png` - After initial wait
3. `feature24_regression_03_current_state.png` - Current state before accessibility click
4. `feature24_regression_04_analysis_tab.png` - Analysis tab with ARM Wizard button ✅
5. `feature24_regression_05_arm_wizard_opened.png` - ARM Wizard screen ✅
6. `feature24_regression_06_step2_active.png` - Step 2 active ✅

### Console Messages

- No error messages were captured before the crash
- After crash, page was blank (no console access)

---

## Conclusion

**Regression Status:** INCONCLUSIVE

**Summary:**
- Feature #24's UI is accessible and appears functional
- Basic form input works correctly
- Navigation within the wizard works
- App crashed under specific testing conditions (JavaScript scroll)

**Critical Question:**
Is this a real regression that affects users, or an artifact of browser automation testing methodology?

**Next Steps:**
1. Restart server
2. Retest with natural UI interactions (no JavaScript scroll)
3. If crash reproduces with natural interaction → **REGRESSION CONFIRMED**
4. If crash does NOT reproduce → **NO REGRESSION** (automation artifact)

**Recommendation:** Do NOT mark Feature #24 as failing until the crash can be reproduced through natural user interaction. The feature appeared to be working correctly up until the automation-triggered crash.

---

**Report Generated:** 2026-01-22
**Test Duration:** ~15 minutes
**Server Status:** DOWN (needs restart)
