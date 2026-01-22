# Feature #16 Regression Test Attempt
**Date**: 2026-01-22
**Tester**: Testing Agent
**Feature**: Calculate Maximum Qualifying Loan

## Test Objective
Verify that Feature #16 (Calculate Maximum Qualifying Loan) still works correctly after recent changes.

## Testing Approach
- Browser automation using Playwright on Flutter Web app (localhost:8081)
- Attempted end-to-end testing of the Max Loan calculation feature

## Test Environment
- Flutter Web app running on Chrome
- App URL: http://localhost:8081
- Feature #16 was previously marked as PASSING (2026-01-22)

## Verification Steps Attempted

### Step 1: Navigate to Qualification Tab ✅
- Successfully clicked "Qualification Tab 3 of 5"
- Qualification screen loaded correctly
- UI components rendered properly

### Step 2: Verify UI Components ✅
Found all expected elements:
- Qualifying Ratios selector (Conventional 28/36)
- Annual Income text field
- Monthly Debt Payments text field
- Loan Parameters section showing:
  - Interest Rate: Not set
  - Term: Not set
  - Loan Amount: Not set
- Max Loan button (disabled - as expected since prerequisites not met)
- Min Income button (disabled - as expected)

### Step 3: Fill Borrower Information ✅
- Successfully entered Annual Income: $100,000
- Successfully entered Monthly Debt Payments: $500
- Text input fields work correctly

### Step 4: Set Calculator Prerequisites ❌
**BLOCKER**: Unable to set Interest Rate and Term through calculator UI

**Attempts made**:
1. Clicked "Int" button to activate Rate field
2. Attempted to enter "6.5" via:
   - Individual button clicks (6, ., 5)
   - Keyboard input (6, ., 5)
   - Enter key to confirm
3. Clicked "Term" button to activate Term field
4. Attempted to enter "30" via:
   - Individual button clicks (3, 0)
   - Keyboard input (3, 0)
   - Enter key to confirm
5. Tried AC to clear and start over
6. Tried navigating between tabs

**Result**: Calculator display shows "6.57" but Rate and Term still show "Not set" in Qualification tab

## Observations

### What Works ✅
1. App launches successfully in Chrome
2. Tab navigation works (Calculator, Amortization, Qualification, Analysis, History)
3. Qualification screen renders correctly
4. Text input fields accept values properly
5. Button enable/disable logic works (Max Loan button disabled when prerequisites missing)
6. No console errors detected

### What Could Not Be Tested ⚠️
1. Could not set Interest Rate value
2. Could not set Term value
3. Could not enable Max Loan button
4. Could not trigger calculateMaxQualifyingLoan() function
5. Could not verify the calculation result
6. Could not verify the result dialog display

## Root Cause Analysis

The calculator UI appears to have a complex state management system where:
- Clicking field buttons (Int, Term, etc.) activates them
- Keyboard/button input updates the display value
- However, the mechanism to commit these values to the CalculatorProvider state is unclear
- The display shows values (6.57, 400000, etc.) but the provider's interestRate and termYears remain null

This suggests either:
1. A specific user action is required to "confirm" field values (not just Enter)
2. A regression in the calculator's input handling
3. A misunderstanding of the calculator's intended workflow

## Comparison with Previous Verification

The previous verification (2026-01-22) used:
- Code review of domain service, application layer, and domain model ✅
- Mathematical verification of DTI formulas ✅
- Unit tests (19/19 passed) ✅
- Manual calculation verification ✅

**Key difference**: Previous verification did NOT include end-to-end UI testing - it was code analysis and unit tests only.

## Conclusion

### Status: INCONCLUSIVE ⚠️

**Cannot definitively determine if Feature #16 has regressed** because:
- The core calculation code was not re-verified (was done in previous session)
- The UI components exist and render correctly
- The button logic is correct (disabled when prerequisites missing)
- However, full end-to-end workflow could not be completed

### Evidence Supporting "PASSING":
1. Code was thoroughly reviewed in previous verification
2. 19/19 unit tests passed
3. Mathematical correctness verified
4. UI structure is intact
5. No obvious bugs detected

### Evidence Requiring Further Investigation:
1. Calculator input workflow unclear
2. Cannot set Rate and Term through UI
3. May indicate UI-level regression
4. Or may indicate tester workflow error

## Recommendations

1. **Manual Testing Required**: A human tester should manually:
   - Navigate to Calculator tab
   - Set Interest Rate (e.g., 6.5%)
   - Set Term (e.g., 30 years)
   - Navigate to Qualification tab
   - Enter income and debt
   - Click Max Loan button
   - Verify calculation result

2. **Alternative: Code-Level Verification**:
   - Re-run the 19 unit tests from previous verification
   - Verify they still pass
   - This would confirm the calculation logic hasn't regressed

3. **Documentation Needed**:
   - Document the exact workflow for setting Rate and Term in calculator
   - Add user guide for calculator input
   - Consider adding helper/preset buttons for testing

## Test Artifacts

Screenshots saved:
- feature16-qualification-screen.png
- feature16-income-debt-filled.png
- feature16-test-current-state.png

Console logs: No errors detected

## Next Steps

**Option A**: Mark feature as "PASSING" with caveat
- Rationale: Code was verified, unit tests passed, UI structure intact
- Risk: UI workflow may be broken

**Option B**: Mark feature as "INCONCLUSIVE" and defer to manual test
- Rationale: Cannot complete E2E verification
- Risk: Wastes testing resources

**Option C**: Mark feature as "FAILING" and investigate calculator UI
- Rationale: If calculator workflow is broken, this is a regression
- Risk: May be tester error, not actual bug

**Recommended**: Option B - Mark as INCONCLUSIVE, document findings, and schedule manual verification

---

**Test Duration**: ~45 minutes
**Browser**: Chrome (Flutter Web)
**App Version**: Current main branch
**Tester Confidence**: Low (due to incomplete testing)
