# QA Inventory: Qualification, Analysis, Rent vs Buy, Loan Programs

Scope: read-only documentation for QA test-pass planning. All file paths relative to repo root.

---

## 1. Qualification

**Files:**
- `lib/src/features/qualification/presentation/screens/qualification_screen.dart`
- `lib/src/features/calculator/application/controllers/qualification_controller.dart`
- `lib/src/features/calculator/domain/services/qualification_service.dart`
- `lib/src/features/calculator/domain/models/qualification_result.dart`
- `lib/src/features/qualification/application/providers/qualifying_ratios_provider.dart`
- `lib/src/core/models/qualifying_ratio.dart`

### Route/entry point
Tab in the main workspace navigation, id `qualification` (`lib/src/core/navigation/feature_catalog.dart:84-92`), pinned, builds `QualificationScreen()`. No parameters — screen reads shared `CalculatorProvider` and `QualifyingRatiosProvider` via `provider` package.

### Inputs

| Field | Type | Units | Constraints found in code |
|---|---|---|---|
| Select Ratio (dropdown) | `DropdownButton<String>` of ratio ids | n/a | Populated from `ratiosProvider.allRatios` (built-in + custom); no validation, always has ≥5 built-ins (`qualification_screen.dart:143-162`) |
| Annual Income | `TextField`, `TextInputType.number` | USD | `double.tryParse`; no min/max/required enforced in UI — invalid text silently becomes `null` via `calculatorProvider.setAnnualIncome(value: null)` (`qualification_screen.dart:270-273`). Service layer requires `>0` (`qualification_service.dart:22`) |
| Monthly Debt Payments | `TextField`, `TextInputType.number` | USD | Same pattern; no floor/ceiling in UI; defaults to `0` when null in calculations (`qualification_screen.dart:276-289`, `qualification_controller.dart:108,160`) |
| Ratio Editor: Name | `TextField` | text | Required — blocked via SnackBar "Please enter a name" if empty on save (`qualification_screen.dart:636-641`) |
| Ratio Editor: Description | `TextField` | text, optional | Empty string coerced to `null` (`qualification_screen.dart:649-651`) |
| Ratio Editor: Housing DTI % | `TextField`, `TextInputType.number` | percent | No min/max validation; empty text falls back to existing/28.0 default; unparsable text also silently falls back to default (`qualification_screen.dart:628-631`) — **a typo like "2x8" silently becomes 28, not an error** |
| Ratio Editor: Total DTI % | `TextField`, `TextInputType.number` | percent | Same fallback pattern, default 36.0 (`qualification_screen.dart:632-634`) |

### Buttons/actions
- **Add Custom Ratio** (icon button, `Icons.add`) — opens ratio editor dialog for new ratio (`qualification_screen.dart:116-119`).
- **Manage Ratios** (icon button, `Icons.list`) — opens bottom sheet listing all ratios (`qualification_screen.dart:121-125`).
- **Edit** (text button, shown only when selected ratio is not built-in) — opens editor pre-filled (`qualification_screen.dart:232-237`).
- **Max Loan** button — enabled only when `annualIncome`, `interestRate`, `termYears` are all set; calls `calculateMaxQualifyingLoan(useRatio1: true)` then shows result dialog (`qualification_screen.dart:358-380`).
- **Min Income** button — enabled only when `loanAmount`, `interestRate`, `termYears` set; calls `calculateMinimumIncome(useRatio1: true)` then shows result dialog (`qualification_screen.dart:383-407`).
- Ratio list tile popup menu: **Duplicate**, **Edit** (custom only), **Delete** (custom only, with confirmation dialog) (`qualification_screen.dart:882-931`).
- Result dialog **OK** — dismisses only.

### Modals/sheets/dialogs
- **Ratio editor dialog** (`_showRatioEditor`) — `AlertDialog` with Name, Description, Housing DTI %, Total DTI % fields; Cancel/Save(or Add) actions (`qualification_screen.dart:545-674`).
- **Ratios list bottom sheet** (`_showRatiosList`) — `DraggableScrollableSheet` (initial 0.6, min 0.3, max 0.9) listing built-in then custom ratios, each with select/duplicate/edit/delete (`qualification_screen.dart:676-805`).
- **Delete confirmation dialog** — "Delete Ratio?" Cancel/Delete (`qualification_screen.dart:771-788`).
- **Result dialog** — shown after Max Loan / Min Income calculation, title + message + formatted currency value or "N/A" (`qualification_screen.dart:511-543`).

### States
- **Loading**: `ratiosProvider.isLoading` → full-screen `CircularProgressIndicator` (`qualification_screen.dart:87-89`), true while async preference load resolves (`qualifying_ratios_provider.dart:19-24,58-61`).
- **Empty/not-set**: Loan Parameters card shows "Not set" for rate/term/loan amount when null (`qualification_screen.dart:318-339`); Max Loan/Min Income buttons disabled until prerequisites set.
- **Error**: no inline error text widget on the qualification screen itself — errors surface only via `calculatorProvider.inputError`/`_state.calculationError`, which this screen does not render (see Risk below). Ratio-editor validation error surfaces via SnackBar.
- **Populated**: DTI warnings section + "Current Loan Summary" card appear once `payment != null` (`qualification_screen.dart:414-502`).

### Computation rules
- Max Loan (`qualification_service.dart:14-51`):
  - Guard: `annualIncome<=0 || interestRate<=0 || termYears<=0` → failure "Incomplete rate/term/income data" (line 22-24).
  - `monthlyIncome = annualIncome/12`
  - `maxPitiHousing = monthlyIncome * (housingRatio/100)`
  - `maxTotalDebt = monthlyIncome * (debtRatio/100)`
  - `maxPitiDebt = maxTotalDebt - monthlyDebt`
  - `maxPiti = min(maxPitiHousing, maxPitiDebt)`
  - `maxPi = maxPiti - monthlyEscrows`
  - If `maxPi<=0` → failure "Insufficient income for housing" (line 34-36).
  - `loanAmount = LoanMath.calculateLoanAmount(payment: maxPi, interestRate, termYears)` (annuity-PV formula, `loan_math.dart:55-68`).
- Min Income (`qualification_service.dart:53-68`):
  - Guard: `pitiPayment<=0` → failure "No payment to evaluate".
  - `minIncomeFront = (pitiPayment / (housingRatio/100)) * 12`
  - `minIncomeBack = ((pitiPayment+monthlyDebt) / (debtRatio/100)) * 12`
  - Result = `max(minIncomeFront, minIncomeBack)`.
- Built-in ratios (`qualifying_ratio.dart:78-119`): Conventional 28/36, FHA 31/43, **VA 0/41** (housingRatio explicitly 0 — "VA doesn't use front-end ratio"), USDA 29/41, Jumbo 28/43.
- DTI live warnings (`enhanced_validators.dart:126-141,178-`): `calculateHousingDti`/`calculateDti` return `0` if `monthlyGrossIncome<=0` (guards div-by-zero); `getDtiWarnings` flags front-end DTI over limit and back-end DTI over limit with severity tiers.

### Acceptance criteria
1. Given valid annual income, interest rate, and term are set, when the user taps "Max Loan", then a result dialog shows a positive currency amount and the underlying `CalcResult` is `CalcSuccess`.
2. Given annual income is not entered, when the screen renders, then "Max Loan" and "Min Income" buttons are disabled (`onPressed: null`).
3. Given the user selects "VA" from the ratio dropdown and taps "Max Loan" with any positive income, when the calculation runs, then it fails with "Insufficient income for housing" because `housingRatio=0` forces `maxPitiHousing=0` — see Risk item 1.
4. Given the user opens the ratio editor and enters a housing DTI of "abc" (non-numeric), when they tap Save, then the ratio is saved silently using the previous/default value (28) rather than showing a validation error.
5. Given a custom ratio is selected and the user taps "Delete" then confirms, when deletion completes, then the selected ratio reverts to the first built-in ratio (Conventional).
6. Given monthly debt exceeds `maxTotalDebt`, when "Max Loan" is calculated, then `maxPitiDebt` is negative, `maxPiti` is negative/zero, and the dialog reports "Insufficient income for housing".
7. Given the housing/back-end DTI exceeds the selected ratio's limits after a payment is calculated, when the screen rebuilds, then `ValidationWarningsDisplay` renders at least one warning above the Loan Summary card.
8. Given a ratio is built-in, when viewed in the ratios list bottom sheet, then it has no Edit/Delete menu entries (`onEdit`/`onDelete` are null for built-ins).

### Risk-based edge cases
1. **VA ratio (housingRatio=0) breaks Max Loan and Min Income entirely** — `maxPitiHousing` is always 0, so `maxPi<=0` always fails (`qualification_service.dart:27-36`); Min Income divides by `0/100=0` producing `Infinity` (`qualification_service.dart:62-63`). High risk — VA is a built-in, commonly-tested program.
2. Zero/blank annual income → `double.tryParse` returns `null` → income treated as unset, buttons disabled, no user-visible error explaining why.
3. Negative income or negative monthly debt (no lower-bound validation on qualification screen's plain `TextField`s) — code path only checks `<=0` for income/rate/term, not for `monthlyDebt`, so a negative debt would incorrectly increase `maxPitiDebt`.
4. Monthly debt greater than gross monthly income → `maxPitiDebt` negative → correctly fails, but message "Insufficient income for housing" is generic and doesn't distinguish debt-driven vs housing-ratio-driven failure.
5. Ratio editor: non-numeric or empty DTI text is masked by silent fallback to previous/default value rather than surfaced as invalid input.
6. Extremely high interest rate or term (e.g., 0.001% or 100 years) — no upper bound validation before being passed to `LoanMath.calculateLoanAmount`.
7. Deleting the currently-selected custom ratio while Max Loan/Min Income dialog is open — check for stale ratio reference vs UI re-sync.
8. `inputError`/`calculationError` state exists in `QualificationController` (`qualification_controller.dart:97,114-118,139,148-153`) but `QualificationScreen` never reads or displays it — failures are silent aside from the loan amount simply not being calculated (the result dialog still opens showing "N/A" only if the caller passes a null value, but currently the button's `onPressed` calls `calculateMaxQualifyingLoan` unconditionally and always opens the dialog even on failure, showing stale/`N/A` value).
9. Rounding: `QualifyingRatio.displayName`/`_formatRatioValue` trims trailing zeros via regex — verify percentages like `28.00` display as `28` and `28.50` as `28.5`.
10. Rapid duplicate-then-delete-then-duplicate on ratios — confirm UUID generation (`Uuid().v4()`) avoids id collisions and persisted list stays consistent.

---

## 2. Analysis

**Files:**
- `lib/src/features/analysis/presentation/screens/analysis_screen.dart`
- `lib/src/core/scenarios/scenario_catalog.dart`, `scenario_definition.dart`, `scenario_engine.dart`, `scenario_field.dart`, `scenario_result.dart`

### Route/entry point
Tab in main workspace, id `analysis` (`feature_catalog.dart:95-103`), pinned, builds `AnalysisScreen()`.

### Inputs

| Field | Type | Units | Constraints |
|---|---|---|---|
| Balloon Payment "Years" | `TextField`, number | years | `double.tryParse`; must be `> 0` or SnackBar "Please enter a valid number of years" (`analysis_screen.dart:172-188`) |
| Future Value sheet: Annual Appreciation Rate | `TextField`, decimal | percent | `double.tryParse`; both rate and years required or SnackBar "Enter valid rate and term." (`analysis_screen.dart:468-476`); pre-filled `3.0` |
| Future Value sheet: Years | `TextField`, decimal | years | Same guard; pre-filled `5` |
| APR sheet: Loan Fees | `TextField`, decimal | USD | `double.tryParse`; pre-filled `4500`; required with points or SnackBar "Provide valid fees and points." (`analysis_screen.dart:569-577`) |
| APR sheet: Discount Points | `TextField`, decimal | percent | Pre-filled `0` |

### Buttons/actions
- **Advanced Tools card** (`_AdvancedToolsCard`) six buttons: PDF Report, Closing Costs, ARM Wizard, Future Value, APR Estimator, Rent vs Buy (`analysis_screen.dart:704-740`).
  - PDF Report → `_generateReport`: blocked with SnackBar if `loanAmount == null`, else generates PDF via `ReportService.generateLoanReport` and calls `Printing.sharePdf` (`analysis_screen.dart:370-386`).
  - Closing Costs → opens `ClosingCostsSheet` modal bottom sheet, transparent background (`analysis_screen.dart:396-403`).
  - ARM Wizard → `context.read<AppRouter>().openArmWizard()`, pushes `ArmWizardScreen` (`analysis_screen.dart:388-390`, `app_router.dart:77-81`).
  - Future Value → opens bottom sheet calculator described below; blocked with SnackBar if no `price`/`loanAmount` set (`analysis_screen.dart:405-416`).
  - APR Estimator → opens bottom sheet; blocked with SnackBar if loanAmount/interestRate/termYears missing (`analysis_screen.dart:506-517`).
  - Rent vs Buy → `context.read<AppRouter>().openRentVsBuy()` → navigates to Rent vs Buy feature (`analysis_screen.dart:392-394`).
- **Calculate Balloon Payment** button — enabled only when loanAmount/interestRate/termYears set; computes and displays remaining balance (`analysis_screen.dart:164-194`).
- **Analyze Bi-Weekly Payments** button — enabled only when loanAmount/interestRate/payment set; computes bi-weekly conversion map (`analysis_screen.dart:272-289`).
- Future Value sheet **Calculate** button; APR sheet **Estimate APR** button.

### Modals/sheets/dialogs
- **Closing Costs bottom sheet** (`ClosingCostsSheet`, transparent, scroll-controlled).
- **Future Value Projection bottom sheet** — `StatefulBuilder` with rate/years inputs and result text (`analysis_screen.dart:421-504`).
- **APR Estimator bottom sheet** — fees/points inputs and result text (`analysis_screen.dart:522-605`).

### States
- Screen wraps all content in `AnimatedBuilder` listening to `loanQuoteController`, `amortizationController`, `qualificationController` — entire screen rebuilds on any of their changes (`analysis_screen.dart:35-40`).
- **Not-set/empty**: Current Loan card fields show "Not set" per field when null (`analysis_screen.dart:60-93`).
- **Populated**: Balloon Balance container and Bi-Weekly result container appear only after a successful button press and `setState` (`analysis_screen.dart:195-238`, `290-359`).
- No explicit loading/error state widgets on this screen; the report-generation and PDF share are `await`ed without a loading indicator during PDF generation (`analysis_screen.dart:383-385`) — a slow PDF build gives no spinner feedback.

### Computation rules
- Balloon remaining balance: `AmortizationController.remainingBalance(years)` (`amortization_controller.dart:66-83`) returns `0` if loan params missing; otherwise delegates to `AmortizationService.remainingBalance` (amortization schedule walk).
- Bi-weekly conversion: `AmortizationController.biWeeklyAnalysis()` (`amortization_controller.dart:85-105`) returns empty map if prerequisites missing; else `AmortizationService.calculateBiWeekly`.
- Future Value: `fv = basePrice * (1 + rate/100)^years` (`analysis_screen.dart:478`) — simple compound growth, `basePrice = provider.price ?? provider.loanAmount`.
- APR: Newton's-method solver in `AdvancedCalculations.calculateAPR` (`advanced_calculations.dart:161-` ), computing standard monthly P&I on `loanAmount`, `totalFees = loanFees + loanAmount*(points/100)`, `netLoanAmount = loanAmount - totalFees`, iterating APR until convergence (guards `testRate<=0 || isNaN` by resetting to nominal rate, `advanced_calculations.dart:187-200`).
- Scenario engine (`lib/src/core/scenarios/*`) — this is a **schema/metadata catalog for an NLP-driven scenario runner**, not a UI-bound calculator on this screen. `ScenarioCatalog.defaults` defines two schemas: `purchase_quote` (inputs: price, downPayment, loanAmount, interestRate, termYears, propertyTax, homeInsurance, mortgageInsurance, monthlyExpenses → results: payment, pitiPayment, cashToClose) and `qualification_max_loan` (inputs: annualIncome, monthlyDebt, interestRate, termYears → result: maxLoanAmount). `ScenarioEngine` (`scenario_engine.dart`) is an abstract interface (`evaluate(Map<String,double?>) -> Map<String,double?>`) with no concrete implementation found in the reviewed files — actual math lives in `CalculatorProvider`/`QualificationService` as documented above.

### Acceptance criteria
1. Given no loan amount is set, when the user taps "PDF Report", then a SnackBar reads "Calculate a loan first to generate a report." and no PDF is generated.
2. Given loanAmount/interestRate/termYears are all set and the user enters a positive integer in "Years" and taps "Calculate Balloon Payment", then a "Remaining Balance" card appears with a formatted currency value.
3. Given the user enters "0" or a negative number in the balloon "Years" field, when they tap the button, then a SnackBar reads "Please enter a valid number of years" and no balance is shown.
4. Given price and loan amount are both null, when the user taps "Future Value", then a SnackBar reads "Set a price or loan amount first." and the sheet does not open.
5. Given loanAmount/interestRate/termYears missing, when the user taps "APR Estimator", then a SnackBar reads "Need loan amount, rate, and term first." and the sheet does not open.
6. Given valid loan fees and points, when the user taps "Estimate APR" in the sheet, then a numeric APR percentage renders, and it differs from the nominal rate whenever fees/points > 0.
7. Given the user taps "Rent vs Buy" from Advanced Tools, then `AppRouter.openRentVsBuy()` navigates to the Rent vs Buy feature.

### Risk-based edge cases
1. Balloon "Years" greater than the loan term (e.g., 50 years on a 30-year loan) — verify `remainingBalance` doesn't return a negative or nonsensical value.
2. APR points value negative or > 100% — no validation catches this before calling `calculateAPR`; `pointsAmount = loanAmount*(points/100)` could exceed the loan amount, making `netLoanAmount` negative.
3. APR Newton's-method: if `dfVal` stays near zero across iterations, verify it doesn't loop into `NaN`/`Infinity` and instead returns `bestApr` cleanly (loop shown truncated at line 200 — bounds check needed).
4. Future Value with negative appreciation rate (e.g., "-3") — `pow(1+rate/100, years)` mathematically valid but should be checked against home value going to near-zero over long `years`.
5. Bi-weekly analysis requested when `payment` is 0 (interest rate 0 edge case from `LoanMath.calculatePayment` returning 0) — confirm `biWeeklyAnalysis` doesn't divide by zero downstream.
6. Rapid successive taps on "Calculate Balloon Payment" / "Analyze Bi-Weekly Payments" while `AnimatedBuilder` is mid-rebuild — check for dropped `setState` or stale controller text (`_balloonYearsController.text` is read directly in the result label at line 227, not a cached value).
7. PDF generation for a loan with `null` optional fields (e.g., no PMI, no HOA) — verify `ReportService.generateLoanReport` doesn't throw on missing optional fields.

---

## 3. Rent vs Buy

**Files:**
- `lib/src/features/rent_vs_buy/presentation/screens/rent_vs_buy_screen.dart`
- `lib/src/features/rent_vs_buy/domain/services/rent_vs_buy_calculator.dart`
- `lib/src/features/rent_vs_buy/domain/models/rent_vs_buy_calculation.dart`

### Route/entry point
Reached via Analysis screen "Rent vs Buy" tool button → `AppRouter.openRentVsBuy()` → `openFeatureById(FeatureCatalog.rentVsBuyId)` (`app_router.dart:90-92`; catalog entry `feature_catalog.dart:131-`). Also listed as its own catalog entry (secondary/non-pinned feature).

### Inputs
All are free-text `TextField`s with `decimal: true` keyboard, **no `TextFormField`/validator — any unparsable text silently falls back to a hardcoded default via `double.tryParse(...) ?? default`** (`rent_vs_buy_screen.dart:71-92`). No min/max bounds anywhere.

| Field | Units | Default if blank/invalid |
|---|---|---|
| Home Price | USD | 400000 |
| Down Payment | % | 20 |
| Interest Rate | % | 6.5 |
| Term | years | 30 |
| Property Tax Rate | %/yr | 1.2 |
| Home Insurance | $/yr | 1800 |
| HOA | $/mo | 0 |
| Maintenance | %/yr | 1 |
| Closing Costs | % | 3 |
| PMI Rate | %/yr | 0.5 |
| Monthly Rent | USD | 2000 |
| Annual Increase (rent) | % | 3 |
| Renters Insurance | $/mo | 25 |
| Home Appreciation | %/yr | 3 |
| Investment Return | %/yr | 7 |
| Tax Bracket | % | 22 |
| Analysis Period | dropdown: 5/7/10/15/20/30 years | 10 (fallback if null) |

### Buttons/actions
- **Calculate** (`FilledButton.icon`) — always enabled, re-parses every controller and runs `RentVsBuyCalculator.calculate` (`rent_vs_buy_screen.dart:70-98,136-143`).
- App bar toggle icon (`Icons.visibility`/`visibility_off`) — "Show/Hide Methodology" toggles `_showMethodology` (`rent_vs_buy_screen.dart:117-124`).
- Inputs `ExpansionTile` — collapses/expands input form; auto-expanded (`initiallyExpanded: _result == null`) until first calculation (`rent_vs_buy_screen.dart:164-168`).
- Methodology section: each step is an `ExpansionTile` (`_MethodologyStep`) showing formula, inputs, explanation (`rent_vs_buy_screen.dart:749-822`).

### Modals/sheets/dialogs
None — everything is inline on one scrollable screen.

### States
- **Empty/initial**: `_result == null` → only input section + Calculate button shown; input `ExpansionTile` starts expanded.
- **Populated**: after Calculate, shows Results Summary card, Cost Comparison card, Net Worth Projection line chart, and (if toggled) Methodology breakdown (`rent_vs_buy_screen.dart:146-157`).
- No loading state — `_calculate()` runs synchronously (in-memory loop over `analysisYears*12` months), no async/await, no spinner.
- No explicit error state — invalid input never surfaces an error; it's masked by default-value substitution (see Risk #1 below).

### Computation rules (all in `rent_vs_buy_calculator.dart`)
- Monthly P&I: standard amortization via `LoanMath.calculatePayment`; if `principal<=0 || years<=0` → `0`; if `annualRate<=0` → straight-line `principal/(years*12)` (interest-free) (`rent_vs_buy_calculator.dart:228-246`).
- Monthly Property Tax = `(homePrice * propertyTaxRate/100) / 12`.
- Monthly Home Insurance = `homeInsuranceAnnual / 12`.
- Monthly PMI: only computed **if `ltv > 80`**: `(loanAmount * pmiRate/100) / 12`; else `0` (`rent_vs_buy_calculator.dart:72-92`). `ltv = (loanAmount/homePrice)*100` (`rent_vs_buy_calculation.dart:79`) — **divides by `homePrice` with no zero-guard.**
- Monthly Maintenance = `(homePrice * maintenancePercent/100) / 12`.
- Monthly Tax Benefit = `(loanAmount * interestRate/100 * marginalTaxRate/100) / 12` — uses **first-year interest as a flat approximation for every month of the entire analysis window** (not amortization-accurate) (`rent_vs_buy_calculator.dart:113-135`).
- Monthly Opportunity Cost (renter) = `(downPayment+closingCosts) * investmentReturnRate/100 / 12`.
- `MonthlyBuyingCosts.total = P&I + tax + insurance + PMI + HOA + maintenance − taxBenefit`.
- `MonthlyRentingCosts.total = rent + rentersInsurance` (opportunity cost excluded from "total", shown separately as a footnote) (`rent_vs_buy_calculation.dart:127-129`, `rent_vs_buy_screen.dart:501-505`).
- Break-even (`rent_vs_buy_calculator.dart:176-212`):
  - `monthlySavings = rentingCosts.total − buyingCosts.total`.
  - If `monthlySavings > 0` (buying cheaper): `breakEvenMonths = ceil(totalUpfrontCost / monthlySavings)`.
  - If `monthlySavings < 0` (renting cheaper): month-by-month equity/net-worth simulation (`_calculateBreakEvenWithEquity`) up to `analysisYears*12` months, returns first month where `netWorthBuying >= netWorthRenting`, else caps at `analysisYears*12`.
  - **If `monthlySavings == 0` exactly, `breakEvenMonths` stays its initialized `0`** → UI displays "Immediately" (`_formatBreakEven`, `rent_vs_buy_screen.dart:420-427`), which is misleading when costs are merely tied, not favorable.
- Yearly projections (`_generateProjections`): compounds home value by appreciation, amortizes loan balance month-by-month, compounds rent by `annualRentIncrease` (applied once per 12 months, at `month==11`), compounds investment value, tracks cumulative costs and derived net worth for both paths.

### Acceptance criteria
1. Given default inputs (unmodified fields), when the user taps "Calculate", then Results Summary, Cost Comparison, and Net Worth chart all render without error.
2. Given `downPaymentPercent` set so LTV > 80% (e.g., 5% down), when calculated, then the Cost Comparison "PMI" row appears with a nonzero value and its own methodology step.
3. Given `downPaymentPercent` = 20 or more (LTV ≤ 80%), when calculated, then no "PMI" row is shown and monthly PMI is 0.
4. Given monthly renting total is less than monthly buying total, when calculated, then the summary reads "Renting May Be Better" and break-even uses the equity-simulation path.
5. Given monthly buying total is less than monthly renting total, when calculated, then the summary reads "Buying is Better" and break-even = `ceil(upfront/savings)` months.
6. Given the user types a non-numeric string into "Home Price" (e.g., "abc") and taps Calculate, then the calculation silently substitutes 400000 rather than showing a validation error — verify this is intentional/acceptable for QA sign-off.
7. Given "Home Price" is set to 0, when the user taps Calculate, then `ltv` is `NaN` (0/0*100) and the PMI branch (`ltv > 80`) evaluates to `false` (NaN comparisons are false in Dart), so no crash occurs but LTV-dependent behavior may be silently wrong.
8. Given "Show Methodology" is toggled on, when the results are populated, then every calculation step from `CalculationBreakdown.steps` is listed with formula, inputs, and explanation text.

### Risk-based edge cases
1. **Silent default substitution on invalid/blank input** — every field uses `double.tryParse(...) ?? default`; there is no user-visible indication that their input was ignored. High risk for a financial tool (e.g., user intends `$0` HOA override but leaves stale text; user typos price and gets a materially different result with no warning).
2. **Home Price = 0** → `ltv = NaN` (`rent_vs_buy_calculation.dart:79`, divide by zero) — confirm downstream widgets (percent formatting) don't crash on NaN.
3. **Negative Home Price or negative Monthly Rent** — no lower-bound validation; formulas will produce negative monthly costs/rent that flow into "total" sums without any guard.
4. **Down Payment % > 100** → `downPaymentAmount > homePrice` → negative `loanAmount` → `_calculateMonthlyPayment` returns 0 (guarded by `principal<=0`), but downstream `ltv` becomes negative, and PMI condition `ltv>80` is false — verify no negative-loan artifacts leak into projections.
5. **Interest Rate = 0** → P&I uses straight-line `principal/(years*12)` instead of amortization formula (`rent_vs_buy_calculator.dart:236-238`) — confirm this is the intended "interest-free" behavior and not a bug.
6. **monthlySavings exactly 0** → break-even stays `0` and displays "Immediately", which is misleading (see Computation rules above).
7. **Extreme rent or price values** (e.g., rent = $500,000/mo, price = $1) — verify chart rendering (`fl_chart`) and currency formatting (`CurrencyFormatter.formatCompactCurrency`) don't overflow or throw with extreme magnitudes.
8. **Analysis Period change after a calculation was already run** — dropdown updates `_analysisYears` via `setState` but does **not** auto-recalculate; stale `_result` remains displayed until "Calculate" is tapped again — verify this doesn't confuse testers into thinking the period changed the result.
9. Rounding via `DecimalUtils.roundToCents` at every intermediate step (`rent_vs_buy_calculator.dart` throughout) — verify cumulative rounding across a 30-year/360-month loop doesn't produce a materially different final loan balance vs a single closed-form calc.
10. **Annual rent increase compounding timing** — increase applied only once per 12 months at `month==11` mid-loop in `_generateProjections` but the standalone `_calculateBreakEvenWithEquity` applies `monthlyRentIncrease` **every month** (`rent_vs_buy_calculator.dart:263,291-293`) — this is a **different compounding method between the two internal calculations** (monthly-compounded vs annual-step) and could produce inconsistent rent figures between the break-even month number and the yearly projection table for the same inputs.

---

## 4. Loan Programs

**Files:**
- `lib/src/features/loan_programs/presentation/screens/loan_programs_screen.dart`
- `lib/src/features/loan_programs/presentation/widgets/loan_program_editor.dart`
- `lib/src/features/loan_programs/application/providers/loan_programs_provider.dart`
- `lib/src/features/loan_programs/domain/models/loan_program.dart`

### Route/entry point
Secondary (non-pinned) feature-catalog entry, id `loan_programs` (`feature_catalog.dart:56,121-130`) → builds `LoanProgramsScreen()`. Editor reached via `AppRouter.openLoanProgramEditor({program})` → pushes `LoanProgramEditor(program: program)` (`app_router.dart:98-100`).

### Inputs — Loan Programs Screen
No text inputs; list/selection screen only.

### Inputs — Loan Program Editor (`LoanProgramEditor`, wrapped in a `Form`)

| Field | Type | Units | Validation |
|---|---|---|---|
| Program Name | `TextFormField` | text | Required — `'Name is required'` if empty (`loan_program_editor.dart:138-139`) |
| Description | `TextFormField`, `maxLines: 2` | text | Optional, no validator |
| Program Type | `DropdownButtonFormField<LoanProgramType>` | enum | 7 options (conventional/fha/va/usda/jumbo/nonQm/custom); on change auto-fills DTI/down-payment/MI defaults via `_applyTypeDefaults` (`loan_program_editor.dart:355-411`) |
| Housing Ratio (%) | `TextFormField`, number | percent | Required; must parse and be `0–100` else `'Enter 0-100'` (`loan_program_editor.dart:190-197`) |
| Debt Ratio (%) | `TextFormField`, number | percent | Same 0–100 validator (`loan_program_editor.dart:211-218`) |
| Min Down Payment (%) | `TextFormField`, number | percent | Required, 0–100 validator (`loan_program_editor.dart:240-247`) |
| Max Loan Amount | `TextFormField`, number | USD | Optional, **no validator at all** — any text or none accepted, parsed with `double.tryParse` on save (nullable) (`loan_program_editor.dart:252-262`) |
| Has Mortgage Insurance | `SwitchListTile` | bool | Toggles visibility of MI sub-fields |
| Auto-calculate MI | `SwitchListTile` | bool | Only shown if MI enabled |
| Upfront MI (%) | `TextFormField`, number | percent | Optional, **no validator** |
| Annual MI (%) | `TextFormField`, number | percent | Optional, **no validator** |
| Funding Fee (%) | `TextFormField`, number | percent | Optional, **no validator** |
| Cancel at LTV (%) | `TextFormField`, number | percent | Optional, **no validator**, default text `'80'` |

### Buttons/actions
- **Add Custom Program** (app bar icon + FAB "New Program") — opens editor with `program: null` (`loan_programs_screen.dart:20-24, 88-92`).
- Program card tap / popup menu **Select** — `provider.selectProgram(program)` then syncs `calculatorProvider.setQualRatio1(program.toQualifyingRatio())` and shows a SnackBar with the program name and DTI (`loan_programs_screen.dart:100-122`).
- Popup menu **Duplicate** — `provider.duplicateProgram(program)`, SnackBar "Created "..."" (`loan_programs_screen.dart:124-135`).
- Popup menu **Edit** (custom programs only, `onEdit: null` for built-ins) — opens editor pre-filled (`loan_programs_screen.dart:56-57,77`).
- Popup menu **Delete** (custom only) — confirmation dialog, then `provider.deleteProgram(id)`, SnackBar "Program deleted" (`loan_programs_screen.dart:137-168`).
- Editor **Save** (app-bar icon or `TextButton.icon`, responsive by screen width `<420`) — validates form, builds `MortgageInsuranceConfig` if `_hasMiConfig`, calls `addProgram`/`updateProgram`, pops on success, SnackBar on `catch(e)` (`loan_program_editor.dart:96-121,413-478`).

### Modals/sheets/dialogs
- **Delete Program? confirmation dialog** — Cancel/Delete (`loan_programs_screen.dart:142-158`).
- Editor is a full-screen route (`Scaffold`), not a dialog/sheet.

### States
- **Loading**: `provider.isLoading` → `CircularProgressIndicator` (`loan_programs_screen.dart:29-31`). Unlike `QualifyingRatiosProvider` (which self-loads via `scheduleMicrotask(load)` in its constructor, `qualifying_ratios_provider.dart:21-24`), `LoanProgramsProvider`'s constructor does not call `load()` (`loan_programs_provider.dart:18-19`) — it is loaded externally by `app_bootstrap_gate.dart:44,56` (`programs.load()` inside `Future.wait([...])` during app bootstrap). Confirmed **not** a bug in the current wiring, but any future refactor that constructs `LoanProgramsProvider` outside the bootstrap gate (e.g., in a test harness or a new provider tree) would silently re-introduce a permanent loading spinner — worth a regression test that exercises the Loan Programs screen through the real bootstrap flow.
- **Empty**: "Custom Programs" section only rendered `if (provider.customPrograms.isNotEmpty)` (`loan_programs_screen.dart:62-81`); no explicit "no custom programs" placeholder message otherwise.
- **Error**: `updateProgram`/`deleteProgram` throw `Exception` for built-in or not-found programs (`loan_programs_provider.dart:154-156,176-177`) — screen doesn't call these paths on built-ins (menu items are `null`), so exceptions should be unreachable via UI, but direct provider misuse would surface only via editor's generic `catch (e)` SnackBar "Error: $e" (`loan_program_editor.dart:467-472`) — nowhere in `LoanProgramsScreen` itself is there a try/catch around `deleteProgram`/`duplicateProgram` calls, so an exception there would be unhandled.
- **Populated**: Selected Program card + Built-in list + Custom list.

### Computation rules
- No direct payment math on these screens; `LoanProgram.toQualifyingRatio()` maps `housingRatio`/`debtRatio` straight into a `QualifyingRatio` consumed by the Qualification feature (`loan_program.dart:122-132`).
- Built-in programs (`DefaultLoanPrograms.programs`, `loan_program.dart:222-353`) include:
  - Conventional 30/15-Year: 28/36 DTI, 3% min down, $766,550 cap, 0.5%/0.4% annual MI.
  - FHA 30-Year: 31/43 DTI, 3.5% min down, $472,030 cap, 1.75% UFMIP + 0.85% annual MIP.
  - VA 30-Year: 41/41 DTI (note: **not 0 here**, unlike the Qualification feature's built-in VA `QualifyingRatio` which uses `housingRatio: 0`, see Qualification section Risk #1 — this is an **inconsistency between the two VA definitions** in the codebase), 0% min down, no cap, 2.15% funding fee.
  - USDA 30-Year: 29/41 DTI, 0% min down, no cap, 1.0% guarantee + 0.35% annual fee.
  - Jumbo 30-Year: 28/43 DTI, 10% min down, no cap, no MI.
  - Bank Statement (Non-QM): 43/50 DTI, 10% min down, $3,000,000 cap.
  - **DSCR Investment: `housingRatio: 0, debtRatio: 0`** ("Not applicable"/"Uses DSCR instead") (`loan_program.dart:338-351`) — if a user selects this program, `toQualifyingRatio()` still produces a `QualifyingRatio` with both ratios at 0, which if fed into `QualificationService.calculateMaxLoan`/`calculateMinimumIncome` reproduces the same **div-by-zero / always-fails bug pattern** as VA in the Qualification screen (see cross-feature risk below).
- Type-default auto-fill (`_applyTypeDefaults`, `loan_program_editor.dart:355-411`) hardcodes the same figures as `DefaultLoanPrograms` for 6 of 7 types; `custom` type intentionally leaves fields untouched.

### Acceptance criteria
1. Given the user opens "New Program" and leaves Name blank, when they tap Save, then form validation blocks submission with "Name is required" and no program is created.
2. Given the user selects "FHA" from the Program Type dropdown while creating a new program, when the dropdown changes, then Housing Ratio auto-fills to 31, Debt Ratio to 43, Min Down to 3.5, Max Loan to 472030, and MI fields to 1.75/0.85.
3. Given a built-in program card, when viewed, then its popup menu has no "Edit" or "Delete" entries.
4. Given a custom program is selected as active and the user duplicates it, then a new program named "<name> (Copy)" appears in Custom Programs with a new UUID (not equal to the source id).
5. Given a user enters "150" into Housing Ratio (%), when they tap Save, then validation blocks with "Enter 0-100".
6. Given the user selects any program (built-in or custom), when selection completes, then the Qualification feature's `qualRatio1` updates to that program's housing/debt ratio and a confirmation SnackBar appears.
7. Given a custom program is deleted while it was the active selection, then the active selection reverts to the first built-in program (`conventional_30`).

### Risk-based edge cases
1. **DSCR (0/0 DTI) and, cross-feature, VA (0/41 in Qualification vs 41/41 in Loan Programs)** — selecting DSCR and running Max Loan/Min Income in Qualification will fail or divide by zero exactly like the standalone VA `QualifyingRatio` bug; the **VA ratio inconsistency between `DefaultQualifyingRatios` (0/41) and `DefaultLoanPrograms` VA (41/41)** means testers must verify which VA numbers actually reach the qualification math depending on entry point (ratio dropdown vs loan-program selection) — high-value regression case.
2. Max Loan Amount field in the editor has **no validator at all** — a negative number or non-numeric junk (`double.tryParse` returns `null`, treated as "no cap") could silently remove an intended cap.
3. MI sub-fields (Upfront/Annual/Funding Fee/Cancel LTV) have **no bounds validation** — e.g., a 500% annual MI or negative funding fee would be accepted.
4. `LoanProgramsProvider` relies on `app_bootstrap_gate.dart` to call `load()` (unlike `QualifyingRatiosProvider`'s self-loading constructor) — low risk today since bootstrap wiring is correct, but any test harness or DI change that skips the bootstrap gate will leave the Loan Programs screen stuck on its loading spinner forever. Worth an explicit regression test through the real app-start flow.
5. Deleting a custom program that is not currently selected vs one that is selected — confirm both paths correctly update `_selectedProgram` (or leave it alone) and persist via `_saveSelectedProgram`.
6. Editing a program's Type after entering custom DTI values — `_applyTypeDefaults` **overwrites** user-entered Housing/Debt Ratio and other fields without confirmation; a user who tweaked values then accidentally changes the Program Type dropdown loses their edits silently.
7. Rapid duplicate taps on the same program (double-tap) — verify two independent UUIDs are created rather than a race/duplicate entry.
8. JSON round-trip robustness: `LoanProgram.fromJson`/`MortgageInsuranceConfig.fromJson` assume required keys exist and correct types (`as String`, `as num`) — a corrupted or partially-written persisted preference blob would throw during `load()`, caught only by the generic `catch (e)` with `debugPrint`, leaving `_customPrograms` at whatever partial state existed (`loan_programs_provider.dart:61-66`) — worth a corrupted-storage regression test.

---

## Cross-Cutting Bugs Worth Flagging to Dev

1. **VA qualifying ratio has `housingRatio: 0`** (`lib/src/core/models/qualifying_ratio.dart:99`), which makes `QualificationService.calculateMaxLoan` always fail with "Insufficient income for housing" (`qualification_service.dart:27,31,34-36`) and makes `calculateMinimumIncome`'s front-end formula divide by zero (`qualification_service.dart:62-63`, `(ratio.housingRatio/100)` = 0). Any QA pass on VA qualification will hit this immediately.
2. **VA definition inconsistency**: `DefaultQualifyingRatios` VA = 0/41 vs `DefaultLoanPrograms` VA = 41/41 (`loan_program.dart:280-281`). Two different sources of truth for the same loan program's DTI limits.
3. **DSCR loan program (0/0 DTI)** will hit the same divide-by-zero/always-fail pattern if a user selects it and then uses Qualification's Max Loan/Min Income buttons — likely intentional (DSCR doesn't use DTI) but there's no UI guard preventing the user from doing this and getting a confusing failure or `Infinity`.
4. **Rent vs Buy: all 16 inputs silently substitute hardcoded defaults on invalid/blank text** (`rent_vs_buy_screen.dart:71-92`) with zero user-facing feedback — a financial calculator masking bad input this broadly is a high-risk UX/trust issue.
5. **Rent vs Buy: `ltv = loanAmount/homePrice*100` has no zero-guard** and will produce `NaN` if Home Price is 0 (`rent_vs_buy_calculation.dart:79`).
6. **Rent vs Buy: inconsistent rent-increase compounding** between `_calculateBreakEvenWithEquity` (monthly compounding) and `_generateProjections` (annual step at month 11) — same inputs can yield subtly different rent trajectories depending which internal method computed them (`rent_vs_buy_calculator.dart:263,291-293` vs `356-360`).
7. **Qualification screen never surfaces `QualificationController.inputError`/`calculationError`** to the user — failures (e.g., VA bug above) are invisible beyond the loan amount simply not updating; the Max Loan/Min Income buttons still open a result dialog unconditionally after calling the calculation, regardless of success/failure.
8. **`LoanProgramsProvider` has no auto-load call in its constructor** unlike the analogous `QualifyingRatiosProvider` (`loan_programs_provider.dart:18-19` vs `qualifying_ratios_provider.dart:21-24`) — currently safe because `app_bootstrap_gate.dart:44,56` explicitly calls `programs.load()` during startup, but this is a fragile implicit dependency worth a regression test.
