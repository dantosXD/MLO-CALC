# QA Inventory: Calculator & Amortization

Scope: Calculator screen (classic + modern layouts) and its dialogs/sheets, plus the Amortization screen. All line references are relative to repo root.

---

## 1. Calculator Screen

### 1.1 Route / entry point

- Top-level tab `FeatureCatalog.calculatorId`, pinned first in `primaryFeatures`, opened via bottom nav / nav rail in `lib/main.dart` (`lib/src/core/navigation/feature_catalog.dart:61-71`).
- Widget tree: `CalculatorScreen` (`lib/src/features/calculator/presentation/screens/calculator_screen.dart:16-21`) chooses between **Classic** layout (inline in this file) and **Modern** layout (`ModernCalculator`, `lib/src/features/calculator/presentation/widgets/modern_calculator.dart:12`) based on `LayoutPreferenceProvider.isModern` (`calculator_screen.dart:158-161`).
- App bar actions available from this tab (`lib/main.dart:286-361`): Share quote, Voice/Text input (opens `NlpDialog`), overflow menu → Settings, "How to Use" (`InfoDialog.show`), Workspace, Loan Programs, Rent vs Buy.

### 1.2 Inputs

All numeric entry happens through the on-screen calculator keypad (no free-text `TextField`, except NLP dialog and Closing Costs sheet, documented separately). The keypad digit/operator input is buffered in `CalculatorDisplayNotifier` and "assigned" to a financial field by pressing a labeled field button.

| Field (label) | Setter | Data type / units | Validation (file:line) |
|---|---|---|---|
| Price | `setPrice` | double, USD | `FinancialValidators.validatePrice`: required, >0, min $10,000 (`AppConstants.minPrice`), max $200,000,000 (`financial_validators.dart:105-121`, `constants.dart:52-53`) |
| L/A (Loan Amount) | `setLoanAmount` | double, USD | `validateLoanAmount`: required, >0, min $1,000, max $100,000,000 (`financial_validators.dart:47-65`, `constants.dart:41-42`) |
| Term | `setTermYears` | double, years | `validateTermYears`: required, >0, min 1yr, max 40yr (`financial_validators.dart:68-86`, `constants.dart:45-46`) |
| Pmt / I/O (Payment) | `setPayment` | double, USD/month | `validatePayment`: required, >0, max $1,000,000/month (`financial_validators.dart:89-102`, `constants.dart:49`) |
| DnPmt (Down Payment) | `setDownPayment` | double — **dual-purpose**: <100 = percent, ≥100 = flat $ | `validateDownPayment`: ≥0; if 100 < value < 10,000 → rejected outright as "cannot exceed 100%"; if ≥10,000, must be < price (`financial_validators.dart:124-153`) |
| Int (Interest Rate) | `setInterestRate` | double, % APR | `validateInterestRate`: required, >0, min 0.1%, max 30% (`financial_validators.dart:26-44`, `constants.dart:37-38`) |
| Tax (annual property tax) | `setPropertyTax` | double, USD/year | `validatePropertyTax`: optional, ≥0, max $1M/yr (`financial_validators.dart:156-167`) — **not actually wired**: `LoanQuoteController.setPropertyTax` skips validation entirely (`loan_quote_controller.dart:326-331`) |
| Ins (annual home insurance) | `setHomeInsurance` | double, USD/year | Same gap: `setHomeInsurance` has no validation call (`loan_quote_controller.dart:333-338`) |
| HOA/Expenses (monthly) | `setMonthlyExpenses` | double, USD/month | Same gap: `setMonthlyExpenses` unvalidated (`loan_quote_controller.dart:347-352`) |
| Mortgage Insurance (PMI, monthly, set only via NLP/qualification path) | `setMortgageInsurance` | double, USD | Unvalidated (`loan_quote_controller.dart:340-345`) |
| Interest-Only toggle | `toggleInterestOnly` | bool | none |
| Display mode (swipe up/down on display) | `cycleDisplayMode` | enum: standardPI / interestOnly / piti | Gated by data availability (`loan_quote_state.dart` / `loan_quote_controller.dart:384-415`) |

Keypad-level input constraints: `FinancialValidators.validateInputLength` caps raw display string at 15 chars (`constants.dart:66`), enforced in `CalculatorDisplayNotifier` (not opened in this pass but referenced by both screens).

### 1.3 Buttons / actions / gestures

Classic layout (`calculator_screen.dart:218-596`):
- Field-assign buttons: Price, L/A, Term, Pmt/I/O, DnPmt, Int, Tax, Ins — tap = assign current display value to that field (double-tap on L/A, Term, Pmt, Int = clear that field via `_clearField`, shows a SnackBar, `calculator_screen.dart:251-255,276-280,308-312,362-366`).
- `Term` button: if display has a value, sets term; **if display is empty**, solves for term (`calculatorProvider.calculateTerm()`) — dual-mode button (`calculator_screen.dart:262-275`).
- `Int` button: same dual-mode — set rate, or solve for rate if blank (`calculator_screen.dart:346-361`).
- `Pmt`/`I/O` long-press → opens Payment Options bottom sheet (`_showPaymentOptions`, `calculator_screen.dart:304-307,625-674`) with Interest-Only switch and "View PITI Breakdown" button → opens PITI breakdown sheet (`_showPitiBreakdown`, `calculator_screen.dart:676-745`).
- Keypad: digits 0-9, `.`, `+ - × ÷`, `%`, `=`, `AC` (clear all), Backspace (tap=1 char, long-press=clear all display).
- Memory button `M`: tap = recall if memory set, else opens menu; long-press always opens menu with M+, M-, MR (if set), MC (if set) (`calculator_screen.dart:787-966`).
- `0` button long-press → menu for `00` / `000` insertion (`calculator_screen.dart:968-1063`).
- Desktop-only `KeyboardListener`: digits, decimal, +/-/×/÷, Enter/`=`, Escape (clear all), Backspace/Delete (`calculator_screen.dart:80-153`).

Modern layout (`modern_calculator.dart`) mirrors the same semantics with a card-style display:
- Swipe up/down on the display card cycles `displayMode` (`modern_calculator.dart:248-260`).
- `_StatChip`s (L/A, Rate, Term, Pmt) tap = assign-or-solve, double-tap = clear, long-press on Pmt = Payment Options sheet (`modern_calculator.dart:332-424`, `499-543`).
- `_RowChip`s (Price, DnPmt, Tax, Ins, HOA) tap = assign from display (`modern_calculator.dart:634-691`).
- Keypad AC/backspace/%/÷/digits/+-×/=, `00` composite key (`modern_calculator.dart:814-984`).

### 1.4 Modals / sheets / dialogs

- **Payment Options bottom sheet**: opened from long-press on Pmt/I/O button/chip; contains Interest-Only switch + "View PITI Breakdown" button (classic only) (`calculator_screen.dart:625-674`, `modern_calculator.dart:499-543`).
- **PITI Breakdown bottom sheet** (classic only): read-only rows for P&I, Property Tax, Home Insurance, Mortgage Insurance (if >0), HOA (if >0), Total Monthly (`calculator_screen.dart:676-745`).
- **InfoDialog** ("How to Use"): opened from app bar overflow menu; static help text + "Version 1.0.0" (`info_dialog.dart:1-69`).
- **NlpDialog** ("Voice Assistant"): opened from app bar mic icon (`main.dart:310-317`); contains `VoiceWaveform` visualizer, free-text `TextField` (mic dictation or manual typing), 2 suggestion chips, status text, Cancel / Mic / Send actions (`nlp_dialog.dart:15-435`).
- **ClosingCostsSheet**: NOT opened from the Calculator screen — its only call site is `Analysis` screen's `_openClosingCosts` (`lib/src/features/analysis/presentation/screens/analysis_screen.dart:396-403`). Included here per task scope since it operates on `CalculatorProvider.closingCosts`. `DraggableScrollableSheet` with 16 currency `TextField`s (Origination, Points, Processing, Underwriting, Appraisal, Credit Report, Flood Cert, Lender/Owner Title Insurance, Settlement, Recording, Transfer Taxes, Prepaid Interest/Insurance/Taxes, Other Fees), debounced 400ms auto-save (`closing_costs_sheet.dart:299-320`), "Estimate" button (`estimateClosingCosts`), footer showing Total Closing Costs and Estimated Cash to Close (`closing_costs_sheet.dart:246-278`).

### 1.5 States

- **Empty**: all fields null; display shows `0`; L/A, Rate, Term, Pmt chips render `--` (`animated_display.dart:184-213`, `modern_calculator.dart:382-409`).
- **Loading**: none intrinsic to calculator arithmetic (synchronous); NLP dialog has an explicit processing state (`_isProcessing`, spinner in Send button, `nlp_dialog.dart:421-427`) and a "queued while offline" state (`nlp_dialog.dart:233-251`).
- **Error**: `inputError` from either `LoanQuoteController` or `CalculatorProvider` renders in place of the mode label with red-tinted badge/background (`animated_display.dart` badge logic via `isError`; `modern_calculator.dart:242-326`). NLP dialog shows red status text prefixed "Error: ..." (`nlp_dialog.dart:378-388`) and never surfaces raw exception text (`_friendlyError`, `nlp_dialog.dart:48-69`).
- **Populated**: L/A, Rate, Term, Pmt chips show formatted values; PITI row appears only if any of tax/insurance/PMI/HOA set (`animated_display.dart:217-268`).

### 1.6 Computation rules

Core TVM math lives in `lib/src/core/math/loan_math.dart`, wrapped by `lib/src/features/calculator/domain/services/core_calculation_service.dart` for rounding/failure handling.

- **Monthly P&I payment**: `M = P * [r(1+r)^n] / [(1+r)^n - 1]`, `r = rate/100/12`, `n = termYears*12` (`loan_math.dart:15-35`). Guard: if `loanAmount<=0 || interestRate<=0 || termYears<=0` returns `0` — **note**: with `interestOnly=true`, returns `loanAmount * r` instead (`loan_math.dart:27-30`).
- **Interest-only payment**: `I = P * r` (`loan_math.dart:37-50`).
- **Loan amount from payment**: `P = M * [(1+r)^n - 1] / [r(1+r)^n]` (`loan_math.dart:52-68`).
- **Term solve**: `n = -ln(1 - (P*r)/M) / ln(1+r)`, months→years; if `loanAmount*r >= payment` returns 0 ("never pays off") (`loan_math.dart:70-90`).
- **Rate solve**: Newton-Raphson in `loan_math.dart` (rarely used) and a hardened version with bisection fallback + convergence tracking in `core_calculation_service.dart:91-187` (used by the app). Result rounded to 3 decimals (`core_calculation_service.dart:186`).
- **Rounding**: all monetary calc outputs rounded to cents via `DecimalUtils.roundToCents` (half-up rounding, `decimal_utils.dart:19-21,26-34`) before being returned as `CalcSuccess`.
- **Failure surfacing**: `CoreCalculationService` treats `payment<=0 || NaN || Infinite` as failure "Unable to calculate payment" (`core_calculation_service.dart:29-30`) — this means **any accepted-but-degenerate input that mathematically yields ≤0 payment (impossible given validators reject rate/term/loanAmount ≤0) will show a generic error**, not a specific one.
- **Down payment → loan amount**: `downPaymentAmount = price * (downPayment/100)` if `downPayment < 100`, else `downPaymentAmount = downPayment` (flat dollars); `loanAmount = price - downPaymentAmount` (`loan_quote_controller.dart:595-609`).
- **PITI monthly total**: `payment + tax/12 + insurance/12 + PMI/12 + HOA` (`loan_quote_state.dart:126-133`, also duplicated in `calculator_screen.dart:683-689` for the breakdown sheet).
- **Cash to close**: `closingCosts.total + (down payment amount, using the same <100=% heuristic) ` or, if no down payment, `price - loanAmount` (`loan_quote_state.dart:112-124`).
- **Closing costs estimate**: origination $0, processing $500, underwriting $500, appraisal $500, credit report $50, flood cert $20, lender title = `loanAmount * 0.005`, owner title = `price * 0.003`, settlement $1000, recording $150, transfer taxes $0 (`closing_costs.dart:110-129`).
- **Auto-solve logic**: `LoanQuoteController.calculate()` tracks the last 3 manually-edited fields (of loanAmount/rate/term/payment) and solves the 4th; also auto-clears the "opposite" field (payment vs loan amount) when one is edited to avoid stale derived values (`loan_quote_controller.dart:196-292,466-543`).

### 1.7 Acceptance criteria

1. **Given** empty calculator, **when** user enters Price then Down Payment (as a percent value <100) then taps DnPmt, **then** Loan Amount is computed as `price*(1-downPayment/100)` and displayed without requiring a manual L/A entry.
2. **Given** Loan Amount, Rate, and Term are all set and Payment is empty, **when** any of the three changes, **then** Payment recalculates automatically and a history entry of type `payment` is recorded (`loan_quote_controller.dart:611-652`).
3. **Given** a valid Loan Amount, Rate, and Payment (no Term), **when** the user taps Term, **then** Term is solved via `calculateTerm` and, if the payment is too low to ever amortize the loan, the field shows the failure message "Payment too low for loan" rather than a nonsensical term.
4. **Given** the Interest-Only toggle is switched on via Payment Options, **when** Loan Amount/Rate/Term are all present, **then** displayed payment recalculates immediately as `loanAmount * monthlyRate` with no principal amortization.
5. **Given** Tax, Insurance, and HOA are populated, **when** the user swipes up on the display (or taps the mode chip's swipe), **then** display mode cycles Standard P&I → Interest-Only (if eligible) → PITI, and PITI mode shows `payment + monthlyEscrowExpenses`.
6. **Given** the user enters an interest rate below 0.1% or above 30%, **when** they tap Int, **then** the app rejects the value with a specific error message and does not silently clamp or accept it.
7. **Given** the user double-taps a set field's button/chip (L/A, Term, Payment, Rate), **then** that field is cleared, a "<Field> cleared" SnackBar appears for ~1.2s, and dependent computed fields are also cleared/recalculated per the manual-input tracking rules.
8. **Given** the ClosingCostsSheet is opened with an existing Loan Amount and Price, **when** the user taps "Estimate", **then** all 16 fields refresh to the estimate formulas and the footer total/cash-to-close update immediately.

### 1.8 Risk-based edge cases

1. **Down payment ambiguity at the 100 boundary**: a dollar down payment of exactly $100–$9,999 is validator-rejected ("cannot exceed 100%"), and $99 is silently interpreted as *99%* rather than $99 (`financial_validators.dart:137-141`, `loan_quote_controller.dart:600-602`). High risk of user confusion/incorrect loan amount.
2. **Rate at validator floor (0.1%)**: confirm payment/loan-amount/term math is numerically stable near `r ≈ 0.0000833` (interest almost linear) — not a true zero-rate straight-line case since 0% is blocked by `validateInterestRate` (`financial_validators.dart:30-32`), but this floor still stresses the formulas' rounding.
3. **Rate at validator ceiling (30%)** and **term at ceiling (40yr)**: verify `pow(1+r, n)` doesn't overflow/behave oddly at max inputs; combined with min loan amount check `n * r` extremes for the Newton-Raphson rate solver's clamp logic (`core_calculation_service.dart:168-169` clamps 0.01–40, i.e. the algorithm's internal clamp differs from the UI's validated max of 30%).
4. **Payment too low to amortize**: `payment <= loanAmount*r` should hit "Payment too low for loan" (term solve, `loan_math.dart:84-86`) or "Unable to converge on interest rate" (rate solve) — verify user-facing error is specific, not a generic Dart exception.
5. **Unvalidated PITI fields**: Tax, Home Insurance, Mortgage Insurance, Monthly Expenses have validator functions defined (`validatePropertyTax`, `validateInsurance`, `validateMonthlyExpenses`) but the controller setters never call them (`loan_quote_controller.dart:326-352`) — negative or absurdly large values (e.g. -$500 tax, $50M HOA) may be accepted and silently corrupt PITI/cash-to-close math.
6. **Rounding drift across repeated round-trips**: solving Payment → then Loan Amount from that rounded Payment → then Term, etc., may not return to the original inputs due to cent-rounding at each step (`decimal_utils.dart:19-21` applied per calculation).
7. **Manual-input-order tracking with clears mixed with sets**: rapidly setting/clearing more than 3 of {loanAmount, rate, term, payment} in various orders (`_manualInputOrder` cap of 3, `loan_quote_controller.dart:581-593`) — verify the "4th field" solved is always the intended one and stale manual flags don't cause wrong-field solving.
8. **Interest-only + auto-solve interaction**: toggling Interest-Only after Payment was manually entered — does the displayed payment recompute from I-O formula, or keep the stale manual payment (`toggleInterestOnly`, `loan_quote_controller.dart:370-382`)?
9. **Down payment ≥ price**: entering a flat-dollar down payment equal to or exceeding price should be rejected (`validateDownPayment`, `financial_validators.dart:144-149`) — verify UI surfaces this instead of producing negative loan amount.
10. **Display string length cap (15 chars) mid-entry**: entering a very large price/loan amount (e.g. $99,999,999,999) that exceeds `maxInputLength` — verify graceful truncation/rejection rather than crash (`constants.dart:66`).
11. **NLP dialog offline + cached response race**: query matches cache while device is also offline — verify cached path (`nlp_dialog.dart:207-231`) takes precedence over the offline-queue path (`nlp_dialog.dart:233-251`) consistently.
12. **Swipe-to-cycle display mode when only Standard P&I is eligible**: swiping should no-op cleanly, not throw on an empty mode list (`cycleDisplayMode`, `loan_quote_controller.dart:384-392` returns early if `modes.length <= 1`).

---

## 2. Amortization Screen

### 2.1 Route / entry point

- Top-level tab `FeatureCatalog.amortizationId`, pinned second in `primaryFeatures` (`feature_catalog.dart:72-82`), rendered by `AmortizationScreen` (`lib/src/features/amortization/presentation/screens/amortization_screen.dart:12-14`).
- Depends on `CalculatorProvider.loanQuoteController` / `.amortizationController` (shared state with the Calculator tab) — no local inputs of its own; it reads whatever Loan Amount/Rate/Term/Payment are already set on the Calculator screen (`amortization_screen.dart:32-34`).

### 2.2 Inputs

None directly on this screen (read-only consumer of Calculator's state). The only screen-level input is implicit: the "Generate" button is enabled only if Loan Amount, Interest Rate, and Term are all non-null and no generation is in progress (`amortization_screen.dart:341-347`).

### 2.3 Buttons / actions

- **Generate** button: calls `amortizationController.generateSchedule()`; disabled while `isComputingAmortization` is true, shows a 20×20 spinner + "Generating..." label while running (`amortization_screen.dart:340-363`).
- **Copy CSV** button (only shown once schedule data exists and not computing): builds `Month,Payment,Principal,Interest,Balance` CSV text and copies to clipboard, shows a SnackBar confirmation (`amortization_screen.dart:365-383`, CSV builder `_generateCsv` at `amortization_screen.dart:15-28`).
- Chart legend / tooltip: tapping/dragging on the `AmortizationChart` line chart shows a tooltip with Principal/Interest for the touched month (`amortization_chart.dart:181-199`).

### 2.4 Modals / sheets / dialogs

None on this screen.

### 2.5 States

- **Empty** (no schedule generated yet): scrollable column showing the summary card, then a centered "No amortization schedule generated / Enter loan details and press 'Generate'" placeholder with a table icon (`amortization_screen.dart:40-77`).
- **Loading**: `Generate` button shows spinner + "Generating..." text; schedule computation runs off the UI thread via `compute()` (`amortization_service.dart:37`, `AmortizationController.generateSchedule`, `amortization_controller.dart:29-64`).
- **Error**: no explicit error UI. If `buildSchedule` returns an empty list (e.g., computed payment ≤ 0), the screen just stays in the "no schedule" empty state — no distinct error message is shown to the user for a resolvable-but-empty computation vs. never having pressed Generate (`amortization_service.dart:26-28`).
- **Populated**: `NestedScrollView` with summary card + `AmortizationChart` (line chart, Principal vs Interest) as scrollable header, and a `ListView.builder` monthly table (Month/Payment/Principal/Interest/Balance, zebra striping, final $0 balance highlighted in primary color) as the body (`amortization_screen.dart:81-258`).

### 2.6 Computation rules

- **Schedule caching**: `AmortizationController` caches by a fingerprint string of `loanAmount|interestRate|termYears|payment` (`amortization_controller.dart:115-122,36-46`) — repeated identical requests are served from cache without recomputation.
- **Payment resolution for schedule/analysis**: if the quote's `payment` is set, use it as-is; otherwise, if `interestRate<=0`, use straight-line `loanAmount/months`; otherwise use `LoanMath.calculatePayment` (`amortization_service.dart:151-172`). Since the calculator validator floors rate at 0.1%, the `interestRate<=0` branch is effectively **dead code** reachable only through non-validated/programmatic paths.
- **Monthly schedule generation** (`_generateSchedule`, runs in `compute()` isolate, `amortization_service.dart:189-236`): for each month, `interestPaid = round(balance * monthlyRate)`, `principalPaid = payment - interestPaid`; on the final month or when `principalPaid >= balance`, pay off the exact remaining balance instead; balance floored to 0 if `< $0.005` (`DecimalUtils.isEffectivelyZero`); loop breaks early once `balance == 0` (loan paid off ahead of schedule if a payment override higher than the amortizing payment was supplied).
- **Remaining balance at N years**: simple month-by-month simulation from `loanAmount`, capped at `balance > 0`, with the same overpayment-prevention guard (`amortization_service.dart:40-77`).
- **Bi-weekly conversion** (`calculateBiWeekly`, `amortization_service.dart:79-149`): `biWeeklyPayment = round(monthlyPayment/2)`, `biWeeklyRate = interestRate/100/26`; simulate up to 2000 periods (~76.9 years) with `principalPaid = biWeeklyPayment - interestPaid`, breaking early (no infinite loop) `if (principalPaid <= 0)` — meaning a too-small bi-weekly payment silently produces `newTermYears` far short of payoff rather than an error. `interestSaved = originalInterest - totalInterest`, where `originalInterest = (monthlyPayment * originalMonths) - loanAmount`.
- **Chart Y-axis scaling**: `maxY = ceil(max(maxPrincipal, maxInterest) * 1.2)`, gridline interval clamped to [$10,000, $200,000] (`amortization_chart.dart:47-54,85`).
- **CSV export formatting**: uses `CurrencyFormatter.formatNumber(..., decimals: 2)` then strips thousands-separator commas per field (`amortization_screen.dart:19-25`) — must verify negative/zero values and locale-specific separators don't break the strip logic.

### 2.7 Acceptance criteria

1. **Given** Loan Amount, Rate, and Term are all set on the Calculator tab, **when** the user opens the Amortization tab, **then** the summary card reflects those exact values and the Generate button is enabled.
2. **Given** any of Loan Amount/Rate/Term is missing, **when** the user views the Amortization tab, **then** Generate is disabled and the empty-state placeholder is shown.
3. **Given** a schedule has been generated, **when** the user taps Generate again with unchanged inputs, **then** the cached result is returned instantly (no spinner flash) per the fingerprint cache.
4. **Given** a schedule has been generated, **when** the user taps "Copy CSV", **then** the clipboard contains a valid CSV with header row and one row per amortization month, matching the on-screen table values.
5. **Given** a schedule with N months, **when** the user scrolls to month N (final month), **then** balance displays exactly $0.00 and is styled in the primary/highlight color.
6. **Given** the chart is rendered, **when** the user taps a point on either line, **then** a tooltip shows the correct Principal or Interest value and month number.
7. **Given** loan inputs change on the Calculator tab while the Amortization tab is open, **then** the summary card updates live (via `AnimatedBuilder` on `Listenable.merge`) without requiring navigation away and back.

### 2.8 Risk-based edge cases

1. **Very long terms (40yr = 480 months)**: verify schedule generation, chart rendering (480 x-axis points), and CSV export all remain performant and the chart's `interval: (data.length/5).ceilToDouble()` bottom-axis labeling doesn't produce duplicate/overlapping "Yr N" labels.
2. **Payment supplied that's far above the amortizing payment** (e.g., user manually overrode Pmt to something large): schedule should pay off in far fewer months than `termYears*12`, and the loop-break-on-`balance==0` (`amortization_service.dart:230-233`) must not skip emitting the final partial-payoff entry incorrectly.
3. **Payment insufficient to cover interest** in `remainingBalance`/schedule: with `payment <= balance*monthlyRate`, `principalPaid` would be negative — verify the overpay guard (`principalPaid > balance` only) doesn't mask a payment that's actually never reducing balance (interest-only or negative amortization scenario is not explicitly special-cased in the schedule builder, only in the guard for exceeding balance).
4. **Bi-weekly conversion with a too-small implied payment**: `principalPaid <= 0` breaks the loop early (`amortization_service.dart:123-126`) — verify `newTermYears`/`interestSaved` returned in this case are not presented as if the loan paid off (they will look artificially small/wrong since `periods` stopped early).
5. **Rounding cent-drift accumulation** over 360-480 iterations: verify final balance reaches exactly 0 (via `isEffectivelyZero` snap, `amortization_service.dart:212-214`) and never ends at e.g. $0.01 or -$0.01 residue.
6. **Cache staleness across "clear" operations**: `AmortizationController.clear(clearCache: false)` is called from `applyHistoryEntry` (`calculator_provider.dart:284-288`) — verify restoring an older history entry doesn't serve a schedule cached under a *different* prior fingerprint that happens to collide.
7. **CSV comma-stripping on negative or very large values**: `_generateCsv` strips only `,` from formatted numbers (`amortization_screen.dart:19-25`) — verify negative interest/principal (shouldn't normally occur, but rounding edge cases) or values ≥ $1,000,000 (with multiple commas) still produce well-formed CSV cells.
8. **Concurrent Generate taps**: rapidly double-tapping Generate before `isComputingAmortization` flips true — verify no duplicate `compute()` isolate spawn or race on `_state`.
9. **Very small loan amount at max term** (e.g., $1,000 loan amount minimum over 40 years) — payment may round to a value where `interestPaid` rounds to more than the tiny payment itself in month 1, an edge that stresses the "principalPaid negative" path described in #3.
10. **Chart with a single-month schedule** (loan paid off immediately, e.g., tiny loan + large override payment): `data.length == 1` — verify `maxX: data.length.toDouble() - 1 = 0` doesn't break `LineChart` rendering (zero-width X range).

---

## Notable cross-cutting observations (not confirmed bugs, flagged for QA attention)

- `financial_validators.dart` defines `validatePropertyTax`, `validateInsurance`, `validateMonthlyExpenses`, and `validatePaymentSufficiency`, but `LoanQuoteController.setPropertyTax` / `setHomeInsurance` / `setMortgageInsurance` / `setMonthlyExpenses` never call them (`loan_quote_controller.dart:326-352`). These fields can currently accept negative or extreme values without any validation error being surfaced.
- The down-payment "under 100 = percent, else = dollar amount" heuristic (`loan_quote_controller.dart:600-602`, `loan_quote_state.dart:100-104`, `loan_quote_state.dart:114-119`) combined with the validator's dead zone for $100–$9,999 (`financial_validators.dart:137-141`) is the single highest-risk UX/correctness issue found in this pass — worth a dedicated bug ticket.
- `LoanMath.calculateInterestRate` (Newton-Raphson, `loan_math.dart:93-138`) appears unused by the production flow — `CoreCalculationService.solveInterestRate` reimplements its own hardened bisection/Newton hybrid (`core_calculation_service.dart:91-187`). Confirm the older `LoanMath` method isn't reachable from any other caller (e.g., tests) with different guarantees.
