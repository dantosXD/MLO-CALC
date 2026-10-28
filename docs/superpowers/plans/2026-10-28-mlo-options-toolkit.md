# MLO Options Toolkit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the MLO the scenarios they quote daily (program-accurate MI, buydowns, refi benefit, second liens, LE-style fees/APR, income calcs, payment-to-price) and an **Options Builder** that turns one member's facts into a side-by-side, branded options sheet.

**Architecture:** Each calculator is a pure `const` service in `lib/src/features/<feature>/domain/services/` with input/result models in `domain/models/`, following `rent_vs_buy` (`RentVsBuyCalculator` + `RentVsBuyInputs`). Screens live in `presentation/screens/` and are registered in `FeatureCatalog.workspaceFeatures`. The Options Builder composes the services; it adds no math of its own.

**Tech Stack:** Flutter/Dart ^3.9, Provider, get_it, `pdf`/`printing`, `http` (all already installed; **no new dependencies**).

**Spec:** This plan's source is the 2026-10-28 conversation (feature gap list, items 1–8). Out of scope by user decision: live rates/pricing engine, team/branch features. Also out: CRM/lead capture and cloud sync, which need a backend this local tool doesn't have.

## Global Constraints

- No new pub dependencies. Rates are entered by the MLO; nothing is fetched except an optional logo URL (Task 9).
- All money math uses `double` and `DecimalUtils.roundToCents` for display values, as in existing services.
- Percent inputs are whole percents (`6.5` = 6.5%), matching `LoanMath`.
- Annual vs monthly: `LoanQuoteState.propertyTax`, `homeInsurance` and `mortgageInsurance` are **annual dollars** (`pitiPayment` divides by 12). Every new writer into the calculator must pass annual dollars.
- 2026 limits (one-unit): conforming baseline `832750`, high-cost ceiling `1249125`. FHA floor `541287`, ceiling `1249125`.
- FHA (HUD ML 2023-05): UFMIP `1.75`% of base loan. Annual MIP: see the Task 1 table. Duration is `132` months if original LTV ≤ 90, otherwise life of loan.
- VA funding fee: purchase first use `<5%` down `2.15`, `5–<10%` `1.50`, `≥10%` `1.25`. Subsequent use `<5%` `3.30`, then `1.50`/`1.25`. Cash-out refi first `2.15` / subsequent `3.30`. IRRRL `0.50`. Exempt (service-connected disability) `0`.
- USDA: upfront guarantee `1.00`%, annual `0.35`%.
- Before merging Task 1, re-check the VA and FHA tables against VA.gov and HUD (fee tables change by mortgagee letter); the values above were current as of 2026-10-28.
- Every screen shows `—` for any result that is null, NaN or infinite. Never render `NaN`, `Infinity` or a negative rate.
- Each screen task registers a `FeatureCatalogEntry` in `FeatureCatalog.workspaceFeatures` (`lib/src/core/navigation/feature_catalog.dart`) with a new `static const String <x>Id`.
- CI gate per task: `dart format lib test`, `flutter analyze` with no new issues, `flutter test --exclude-tags=golden`.

## Review Focus

1. **Fee-table boundaries:** LTV exactly 95 / 90 / 78 and base loan exactly `726200` use HUD's "≤" side. Pinned in Task 1 tests.
2. **Buydown deeper than the note rate:** a 3-2-1 on a 2.5% note must return a validation error, never a negative rate. Pinned in Task 3.
3. **Refi with no savings:** break-even shows "Never" (no `Infinity` months) and NTB fails. Pinned in Task 4.
4. **Blank or zero inputs on every new screen:** no NaN or Infinity text. Pinned in each screen task's widget test (`shows dash for empty inputs`).
5. **Logo URL unreachable or offline:** the PDF still renders without the logo, with no exception. Pinned in Task 9.

---

### Task 0: Fix default tax/insurance units bug

`CalculatorProvider.setPrice` (`lib/src/features/calculator/application/providers/calculator_provider.dart:226-236`) writes `price * rate / 100 / 12` (monthly) into fields that `LoanQuoteState.pitiPayment` treats as annual. The result is that PITI understates tax and insurance 12× when Settings defaults are used.

**Files:**
- Modify: `lib/src/features/calculator/application/providers/calculator_provider.dart:230,233` (drop `/ 12`), and the same `/ 12` in `applyDefaultsIfEmpty` if present.
- Modify: `test/regression/item3_calculator_defaults_wiring_test.dart:45,55,86,87`

- [ ] **Step 1: Change the expectations to annual dollars.** On a $300,000 price: `propertyTax` `closeTo(3600, 0.01)` at 1.2%, `homeInsurance` `closeTo(1500, 0.01)` at 0.5%.
- [ ] **Step 2:** Run `flutter test test/regression/item3_calculator_defaults_wiring_test.dart`. Expected: FAIL (300 ≠ 3600).
- [ ] **Step 3:** Remove the `/ 12` on both lines.
- [ ] **Step 4:** Re-run. Expected: PASS. Then run the full suite.
- [ ] **Step 5:** Commit `fix: default tax/insurance stored as annual dollars`.

### Task 1: Government fee schedule + 2026 loan limits

**Files:**
- Create: `lib/src/core/math/government_fees.dart`
- Test: `test/unit/government_fees_test.dart`

**Interfaces — Produces:**
```dart
enum VaUse { first, subsequent }
enum VaPurpose { purchase, cashOutRefi, irrrl }
class LoanLimits2026 { static const conformingBaseline = 832750.0; static const highCostCeiling = 1249125.0; static const fhaFloor = 541287.0; static const fhaCeiling = 1249125.0; }
class GovernmentFees {
  const GovernmentFees();
  double fhaUpfrontMipRate();                                    // 1.75
  double fhaAnnualMipRate({required double baseLoan, required double ltv, required double termYears});
  int? fhaMipMonths({required double ltv});                      // 132 or null (= life of loan)
  double vaFundingFeeRate({required double downPaymentPercent, required VaUse use, required VaPurpose purpose, bool exempt = false});
  double usdaUpfrontRate();                                      // 1.00
  double usdaAnnualRate();                                       // 0.35
}
```

FHA annual MIP table (ML 2023-05); `big` means base loan > 726200:

| Term | Loan | LTV | Rate |
|---|---|---|---|
| >15y | ≤726200 | ≤95 / >95 | 0.50 / 0.55 |
| >15y | big | ≤95 / >95 | 0.70 / 0.75 |
| ≤15y | ≤726200 | ≤90 / >90 | 0.15 / 0.40 |
| ≤15y | big | ≤78 / ≤90 / >90 | 0.15 / 0.40 / 0.65 |

- [ ] **Step 1: Write failing tests** in a `group('GovernmentFees')`:
  - `fhaAnnualMipRate(baseLoan: 300000, ltv: 96.5, termYears: 30) == 0.55`
  - `(…ltv: 95, termYears: 30) == 0.50` (boundary)
  - `(baseLoan: 726200, ltv: 96.5, termYears: 30) == 0.55`; `(baseLoan: 726201, …) == 0.75`
  - `(baseLoan: 800000, ltv: 78, termYears: 15) == 0.15`; `ltv: 85 → 0.40`; `ltv: 91 → 0.65`
  - `fhaMipMonths(ltv: 90) == 132`; `fhaMipMonths(ltv: 90.01) == null`
  - `vaFundingFeeRate(downPaymentPercent: 0, use: first, purpose: purchase) == 2.15`; `4.99 → 2.15`; `5 → 1.50`; `10 → 1.25`; `(0, subsequent, purchase) == 3.30`; `(0, first, irrrl) == 0.50`; `(0, subsequent, cashOutRefi) == 3.30`; `exempt: true → 0`
- [ ] **Step 2:** Run `flutter test test/unit/government_fees_test.dart`. Expected: FAIL (file missing).
- [ ] **Step 3:** Implement `GovernmentFees` per the table and the Global Constraints values.
- [ ] **Step 4:** Re-run. Expected: PASS.
- [ ] **Step 5:** Commit `feat: 2026 government fee schedule and loan limits`.

### Task 2: Program-accurate MI → calculator

Today `LoanProgram.miConfig` is stored but **never used in any calculation**; MI is typed in by hand. This task makes a selected program drive MI and upfront fees.

**Files:**
- Create: `lib/src/features/loan_programs/domain/services/program_cost_service.dart`
- Modify: `lib/src/features/loan_programs/domain/models/loan_program.dart:221-353` (update `maxLoanAmount` to `LoanLimits2026` values: conventional `conformingBaseline`, FHA `fhaFloor`; FHA `annualPercent` 0.55)
- Modify: `lib/src/features/calculator/application/providers/calculator_provider.dart` (add `applyLoanProgram`)
- Modify: `lib/src/features/loan_programs/presentation/screens/loan_programs_screen.dart` (the `onSelect` action, near line 315, gets an "Use in calculator" button)
- Test: `test/unit/program_cost_service_test.dart`, `test/unit/calculator_apply_program_test.dart`

**Interfaces:**
- Consumes: `GovernmentFees`, `VaUse`, `VaPurpose`, `LoanLimits2026` (Task 1).
- Produces:
```dart
class BorrowerEligibility { const BorrowerEligibility({this.vaUse = VaUse.first, this.vaExempt = false}); final VaUse vaUse; final bool vaExempt; }
class ProgramCosts { final double baseLoan; final double upfrontFee; final double totalLoan; final double annualMi; final int? miMonths; final bool exceedsLimit; }
class ProgramCostService {
  const ProgramCostService();
  ProgramCosts compute({required LoanProgram program, required double price, required double downPayment, required double termYears, BorrowerEligibility eligibility = const BorrowerEligibility()});
}
// CalculatorProvider:
void applyLoanProgram(LoanProgram program, {BorrowerEligibility eligibility = const BorrowerEligibility()});
```
Rules: FHA/VA/USDA finance the upfront fee (`totalLoan = baseLoan + upfrontFee`). Annual MI is `totalLoan × rate`. FHA uses `GovernmentFees`. VA has `annualMi` 0. Conventional uses `miConfig.annualPercent` only when LTV > 80, else 0. Jumbo and non-QM have no MI. `exceedsLimit` is `baseLoan > program.maxLoanAmount` (false when null). `applyLoanProgram` sets `loanAmount = totalLoan` and `mortgageInsurance = annualMi` (**annual**), then calls `calculate()`.

- [ ] **Step 1: Write failing tests:**
  - FHA, price 400000, down 14000, 30y: `baseLoan 386000`, `upfrontFee 6755`, `totalLoan 392755`, `annualMi closeTo(2160.15, 0.01)` (0.55%), `miMonths null`.
  - VA, price 400000, down 0, first use: `upfrontFee 8600`, `annualMi 0`. With `vaExempt: true`: `upfrontFee 0`.
  - Conventional, 20% down: `annualMi 0`. With 5% down: `annualMi == baseLoan * 0.005`.
  - Conventional, price 1000000, 10% down: `exceedsLimit true`.
  - `calculator_apply_program_test`: after `applyLoanProgram(fha…)`, `provider.loanAmount == 392755` and `provider.mortgageInsurance closeTo(2160.15, 0.01)`.
- [ ] **Step 2:** Run both tests. Expected: FAIL.
- [ ] **Step 3:** Implement the service, update the defaults, add `applyLoanProgram` and the screen button (pops back to the calculator tab).
- [ ] **Step 4:** Run the tests plus the full suite. Expected: PASS.
- [ ] **Step 5:** Commit `feat: loan programs drive MI and upfront fees`.

### Task 3: Temporary buydowns

**Files:**
- Create: `lib/src/features/buydown/domain/models/buydown.dart`, `lib/src/features/buydown/domain/services/buydown_calculator.dart`, `lib/src/features/buydown/presentation/screens/buydown_screen.dart`
- Modify: `lib/src/core/navigation/feature_catalog.dart` (`buydownId = 'buydown'`, category `'Quote'`)
- Test: `test/unit/buydown_calculator_test.dart`, `test/widget/buydown_screen_test.dart`

**Interfaces — Produces:**
```dart
enum BuydownType { twoOne, oneZero, threeTwoOne, oneOne }   // steps: [2,1], [1], [3,2,1], [1,1]
class BuydownYear { final int year; final double rate; final double payment; final double monthlySubsidy; }
class BuydownResult { final double notePayment; final List<BuydownYear> years; final double totalSubsidy; }
class BuydownCalculator {
  const BuydownCalculator();
  BuydownResult calculate({required double loanAmount, required double noteRate, required double termYears, required BuydownType type}); // throws ArgumentError if noteRate - firstStep <= 0
}
```
Each buydown-year payment is `LoanMath.calculatePayment` at `noteRate - step` on the full loan and term. `monthlySubsidy = notePayment - payment`. `totalSubsidy = Σ monthlySubsidy × 12`.

- [ ] **Step 1: Write failing tests:**
  - 2-1 on 400000 @ 7%, 30y: `years[0].rate == 5`, `years[1].rate == 6`. `totalSubsidy closeTo(12 × (p7 − p5) + 12 × (p7 − p6), 0.01)` using `LoanMath` payments (≈ 9,323).
  - `oneZero` has 1 year; `threeTwoOne` has 3 years.
  - `throwsArgumentError` for `threeTwoOne` at `noteRate: 2.5`.
  - Widget: entering 0 for the loan shows `—` and no `NaN`. A 3-2-1 at 2.5% shows the text "Buydown exceeds note rate".
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the service. The screen has inputs for loan amount, note rate and term (prefilled from `CalculatorProvider`), a `SegmentedButton<BuydownType>`, a year table, a total-subsidy card, and the line "Seller/builder credit needed: $X".
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: temporary buydown calculator`.

### Task 4: Refinance benefit (break-even + NTB)

**Files:**
- Create: `lib/src/features/refinance/domain/models/refinance.dart`, `lib/src/features/refinance/domain/services/refinance_analyzer.dart`, `lib/src/features/refinance/presentation/screens/refinance_screen.dart`
- Modify: `feature_catalog.dart` (`refinanceId = 'refinance'`, category `'Analyze'`)
- Test: `test/unit/refinance_analyzer_test.dart`, `test/widget/refinance_screen_test.dart`

**Interfaces:**
- Consumes: `AdvancedCalculations.calculateRefinanceBreakEven` (existing), `LoanMath`, `GovernmentFees` (FHA MIP for combined rate).
- Produces:
```dart
enum RefiProgram { conventional, fhaStreamline, vaIrrrl }
class RefinanceInputs { currentBalance, currentRate, currentRemainingYears, currentAnnualMiRate, newRate, newTermYears, closingCosts, cashOut, program }
class RefinanceResult { final double currentPayment; final double newPayment; final double monthlySavings; final double? breakEvenMonths; final double lifetimeInterestChange; final bool? ntbMet; final String? ntbReason; }
class RefinanceAnalyzer { const RefinanceAnalyzer(); RefinanceResult analyze(RefinanceInputs i); }
```
NTB rules: VA IRRRL is met if `breakEvenMonths <= 36`. FHA streamline is met if `(currentRate + currentAnnualMiRate) − (newRate + newMip) >= 0.5`. Conventional is `null` (no rule). `breakEvenMonths` is `null` when savings ≤ 0 (map the existing helper's `double.infinity` to null). The new loan amount is `currentBalance + cashOut`.

- [ ] **Step 1: Write failing tests:**
  - 300000 balance, 7.5% → 6.25%, 28y remaining → 30y new, costs 6000: `monthlySavings > 0`, `breakEvenMonths closeTo(costs / savings, 0.01)`.
  - VA IRRRL with break-even 40 months: `ntbMet false`, `ntbReason` contains "36".
  - FHA 6.75 + 0.55 → 6.25 + 0.55: `ntbMet true`. 6.75 → 6.5: `ntbMet false`.
  - New rate higher: `breakEvenMonths null`. Widget shows "Never".
  - `cashOut 50000` raises `newPayment`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement the analyzer and the screen, plus a "Save to History" button using `HistoryController.addQuoteEntry` with notes `'Refi: …'`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: refinance break-even and net tangible benefit`.

### Task 5: Second liens — piggyback and HELOC

**Files:**
- Create: `lib/src/features/second_lien/domain/models/second_lien.dart`, `.../domain/services/second_lien_calculator.dart`, `.../presentation/screens/second_lien_screen.dart`
- Modify: `feature_catalog.dart` (`secondLienId = 'second_lien'`, category `'Quote'`)
- Test: `test/unit/second_lien_calculator_test.dart`, `test/widget/second_lien_screen_test.dart`

**Interfaces — Produces:**
```dart
class PiggybackResult { final double firstLoan; final double secondLoan; final double firstPayment; final double secondPayment; final double combinedPayment; final double singleLoanPaymentWithMi; final double monthlyDifference; }
class HelocResult { final double maxLine; final double cltv; final double interestOnlyPayment; final double fullyAmortizingPayment; }
class SecondLienCalculator {
  const SecondLienCalculator();
  PiggybackResult piggyback({required double price, required double firstLtv, required double secondLtv, required double firstRate, required double secondRate, required double termYears, required double secondTermYears, required double singleLoanMiAnnualPercent});
  HelocResult heloc({required double homeValue, required double firstBalance, required double maxCltv, required double drawAmount, required double rate, required double repayYears}); // maxLine clamps to >= 0
}
```

- [ ] **Step 1: Write failing tests:**
  - Piggyback 80-10-10 on 500000: `firstLoan 400000`, `secondLoan 50000`. The single-loan comparison uses 450000 with MI.
  - HELOC: value 600000, first 350000, maxCltv 85 → `maxLine 160000`. Draw 100000 → `cltv closeTo(75, 0.01)`. `interestOnlyPayment == LoanMath().calculateInterestOnlyPayment(…)`.
  - First balance above maxCltv × value → `maxLine 0`.
  - Widget: empty inputs show `—`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement. The screen has two tabs, Piggyback and HELOC.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: piggyback and HELOC calculators`.

### Task 6: Loan Estimate–style fee sheet + APR

**Files:**
- Modify: `lib/src/features/calculator/domain/models/closing_costs.dart` (add `initialEscrow` field with JSON key `'initialEscrow'`, default 0, and the getters below)
- Modify: `lib/src/features/calculator/presentation/widgets/closing_costs_sheet.dart` (group by LE section, show APR)
- Test: `test/unit/closing_costs_le_test.dart`

**Interfaces — Produces (on `ClosingCosts`):**
```dart
Map<LeSection, double> get bySection;   // enum LeSection { a, b, c, e, f, g, h }
double get prepaidFinanceCharges;
double apr({required double loanAmount, required double interestRate, required double termYears}); // delegates to AdvancedCalculations.calculateAPR(loanFees: prepaidFinanceCharges, points: 0)
```
Section map: **A** = origination, discountPoints, processing, underwriting. **B** = appraisal, creditReport, floodCertification. **C** = titleInsuranceLender, settlementFee. **E** = recordingFees, transferTaxes. **F** = prepaidInterest, prepaidHomeInsurance, prepaidPropertyTaxes. **G** = initialEscrow. **H** = titleInsuranceOwner, otherFees.
Finance charges = origination, discountPoints, processing, underwriting, settlementFee, prepaidInterest. Appraisal, credit, flood, title, recording, transfer, insurance, taxes and escrow are excluded per Reg Z 1026.4(c)(7).
Ceiling: monthly MI is not in the APR payment stream (`// ponytail:` comment at the call site; add it if MLOs compare APR against LOS output).

- [ ] **Step 1: Write failing tests:**
  - With all fields set to distinct values, `bySection[LeSection.a] == origination + points + processing + underwriting`, and so on for each section. The sum of sections equals `total + initialEscrow`.
  - `prepaidFinanceCharges` excludes appraisal (change appraisal → unchanged).
  - `apr(loanAmount: 300000, interestRate: 6.5, termYears: 30)` with 4000 of finance charges is `> 6.5` and `< 6.7`.
  - Old JSON without `initialEscrow` parses to 0.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement, and render section headers "A. Origination Charges" … "H. Other" with subtotals plus an APR row.
- [ ] **Step 4:** Run the tests plus `test/widget/calculator_*`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: LE section fee sheet with APR`.

### Task 7: Income & debt calculators

**Files:**
- Create: `lib/src/features/income/domain/models/income.dart`, `.../domain/services/income_calculator.dart`, `.../presentation/screens/income_screen.dart`
- Modify: `feature_catalog.dart` (`incomeId = 'income'`, category `'Qualify'`)
- Test: `test/unit/income_calculator_test.dart`, `test/widget/income_screen_test.dart`

**Interfaces — Produces:**
```dart
class ScheduleCYear { final double netProfit, depreciation, depletion, businessUseOfHome, amortization, nonrecurring; double get adjusted; } // sum of add-backs minus nonrecurring income
enum StudentLoanAgency { fannie, freddie, fha, va, usda }
class IncomeCalculator {
  const IncomeCalculator();
  double selfEmployedMonthly({required ScheduleCYear priorYear, required ScheduleCYear recentYear}); // recent >= prior: (prior+recent)/24 ; else recent/12 ; floor 0
  double variableMonthly({required double priorYear, required double recentYear, required double ytd, required int ytdMonths}); // same trend rule over the 2 full years
  double rentalMonthly({required double grossMonthlyRent, required double monthlyPitia}); // 0.75*rent - pitia (may be negative = debt)
  double studentLoanMonthly({required StudentLoanAgency agency, required double balance, required double reportedPayment});
}
```
Student loans: if `reportedPayment > 0`, return it. Otherwise Fannie uses 1% of the balance, Freddie / FHA / USDA use 0.5%, and VA uses `balance × 0.05 / 12`.

- [ ] **Step 1: Write failing tests:**
  - Schedule C with an increasing year: 60000 then 72000 adjusted → `5500`. Declining, 72000 then 60000 → `5000`.
  - Rental: rent 2000, PITIA 1200 → `300`. Rent 1200, PITIA 1200 → `-300`.
  - Student loan, balance 40000 with payment 0: fannie `400`, fha `200`, va `closeTo(166.67, 0.01)`. A reported payment of 250 → `250` for every agency.
  - Widget: the "Send to Qualification" button calls `CalculatorProvider.setAnnualIncome(total × 12)` and `setMonthlyDebt(debts)`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement. The screen has sections for Self-employed, Variable, Rental and Student loans, a running total, and "Send to Qualification".
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: income and student-loan calculators`.

### Task 8: Payment-to-price (reverse affordability)

**Files:**
- Create: `lib/src/features/qualification/domain/services/affordability_solver.dart`
- Modify: `lib/src/features/qualification/presentation/screens/qualification_screen.dart` (add a "Max price for a target payment" card)
- Test: `test/unit/affordability_solver_test.dart`

**Interfaces — Produces:**
```dart
class AffordabilityResult { final double price; final double loanAmount; final double principalAndInterest; final double monthlyTaxInsMi; }
class AffordabilitySolver {
  const AffordabilitySolver();
  AffordabilityResult? maxPrice({required double targetPiti, required double rate, required double termYears, required double downPaymentPercent, required double taxRatePercent, required double insuranceRatePercent, required double hoaMonthly, required double miAnnualPercent}); // null if target <= hoa
}
```
Closed form: `price = (targetPiti − hoa) / ((1 − d)·k + (tax + ins)/1200 + (1 − d)·mi/1200)`, where `k = LoanMath.calculatePayment(1, rate, term)` and `d = down / 100`.

- [ ] **Step 1: Write failing tests:**
  - Round trip: plug the returned `price` back into a forward PITI calculation and get `targetPiti` within 0.01 (for 3000, 6.5%, 30y, 10% down, 1.2% tax, 0.5% ins, 0 HOA, 0.5% MI).
  - Target 200 with HOA 300 → `null`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement and add the card, with an "Use this price" button calling `setPrice` and `setDownPayment`.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: max price from target payment`.

### Task 9: Branding on PDFs and shares

**Files:**
- Modify: `lib/src/features/settings/domain/providers/mlo_profile_provider.dart` (add `applyUrl`, `logoUrl`, and cached `logoBytesBase64` in prefs keys `mlo_apply_url`, `mlo_logo_url`, `mlo_logo_b64`; add `{{applyUrl}}` to `toTokenMap`)
- Create: `lib/src/features/reporting/domain/services/brand_header.dart`
- Modify: `lib/src/features/reporting/domain/services/report_service.dart:13-44` (accept `BrandInfo? brand`, use `buildBrandHeader`), `lib/src/features/settings/presentation/screens/settings_screen.dart` (fields), `share_templates_provider.dart` (default templates end with `{{applyUrl}}` when non-empty)
- Test: `test/unit/brand_header_test.dart`, `test/unit/mlo_profile_logo_test.dart`

**Interfaces — Produces:**
```dart
class BrandInfo { final String name, nmls, company, phone, email, applyUrl, disclaimer; final Uint8List? logo; final int accentColor; }
pw.Widget buildBrandHeader(BrandInfo brand, {String? title});   // logo left (if any), name + "NMLS #…" + contact right
pw.Widget buildBrandFooter(BrandInfo brand);                      // disclaimer + apply URL
// MloProfileProvider:
Future<bool> refreshLogo({http.Client? client});   // GET logoUrl, cache base64; false (keeps old bytes) on any error/non-200/>500KB
BrandInfo toBrandInfo();
```
Ceiling: the logo comes from a URL because no image-picker dependency is installed. `// ponytail:` note: add `file_selector` if MLOs ask to pick a file.

- [ ] **Step 1: Write failing tests:**
  - `refreshLogo` with a `MockClient` (from `package:http/testing.dart`) returning 404 → `false`, `logoBytesBase64` unchanged. Returning 200 with PNG bytes → `true` and the bytes are cached.
  - A `MockClient` that throws `SocketException` → `false`, no throw.
  - `ReportService.generateLoanReport` with `brand.logo == null` returns non-empty bytes. With 1×1 PNG bytes it also returns non-empty bytes.
  - `toTokenMap()['applyUrl']` equals the saved URL.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement and wire Settings fields with a "Fetch logo" button.
- [ ] **Step 4:** Run the tests plus `test/regression/b15_*`, `b7_*`, `b19_*`. Expected: PASS.
- [ ] **Step 5:** Commit `feat: branded PDF header/footer and apply link`.

### Task 10: Options Builder — engine

**Files:**
- Create: `lib/src/features/options/domain/models/member_profile.dart`, `.../domain/models/loan_option.dart`, `.../domain/services/options_builder.dart`
- Test: `test/unit/options_builder_test.dart`

**Interfaces:**
- Consumes: `ProgramCostService`, `BorrowerEligibility` (Task 2), `BuydownCalculator` (3), `SecondLienCalculator` (5), `LoanMath`, `DefaultLoanPrograms.programs`.
- Produces:
```dart
class MemberProfile { final double price; final double cashAvailable; final double annualIncome; final double monthlyDebt; final double annualTax; final double annualInsurance; final double hoaMonthly; final bool isVeteran; final BorrowerEligibility eligibility; final bool ruralEligible; }
class RateSheet { final Map<String, double> ratesByProgramId; } // MLO-entered, e.g. {'conventional_30': 6.75, 'fha_30': 6.25}
class LoanOption { final String id; final String title; final String programId; final double loanAmount; final double downPayment; final double rate; final double principalAndInterest; final double monthlyMi; final double piti; final double cashToClose; final double? backEndDti; final List<String> flags; final BuydownResult? buydown; }
class OptionsBuilder { const OptionsBuilder(); List<LoanOption> build(MemberProfile m, RateSheet r, {double estimatedClosingCostsPercent = 3}); }
```
Generated options (skip any whose program has no rate in the `RateSheet`): Conventional 30 and 15 at max down (≤ cashAvailable − closing costs) and at 20% down if affordable; FHA 30 at 3.5%; VA 30 at 0% (only if `isVeteran`); USDA 30 at 0% (only if `ruralEligible`); Conventional 30 + 2-1 buydown; 80-10-10 piggyback (second rate = conventional rate + 2, as an editable default). Flags: `'Exceeds loan limit'`, `'DTI over program max'` (vs `program.debtRatio`), `'Short on cash'` (cashToClose > cashAvailable). Sort by `piti` ascending.

- [ ] **Step 1: Write failing tests:**
  - A non-veteran, non-rural member → no option has `programId` `va_30` or `usda_30`. Making them a veteran adds `va_30`.
  - A program missing from the `RateSheet` is omitted.
  - Price 400000, cash 20000 → the conventional 20%-down option is absent, and the FHA option has `cashToClose <= 20000` or carries the `'Short on cash'` flag.
  - Income 60000, debt 1500 → the FHA option's `backEndDti` is `closeTo((piti + 1500) / 5000 × 100, 0.01)`.
  - The result is sorted by `piti`.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement by composing the earlier services. No new math.
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: options builder engine`.

### Task 11: Options Builder — screen, options sheet, history

**Files:**
- Create: `lib/src/features/options/presentation/screens/options_screen.dart`, `lib/src/features/options/application/rate_sheet_store.dart` (saves today's rates in `PreferenceStore` key `options_rate_sheet`), `lib/src/features/reporting/domain/services/options_report_service.dart`
- Modify: `feature_catalog.dart` (`optionsId = 'options'`, category `'Quote'`, **pinned: true**, as it's the headline workflow)
- Test: `test/unit/rate_sheet_store_test.dart`, `test/unit/options_report_service_test.dart`, `test/widget/options_screen_test.dart`

**Interfaces:**
- Consumes: `OptionsBuilder`, `MemberProfile`, `RateSheet`, `LoanOption` (Task 10). `BrandInfo`, `buildBrandHeader/Footer` (Task 9). `CalculatorProvider.applyLoanProgram` (Task 2). `HistoryController.addQuoteEntry`.
- Produces:
```dart
class RateSheetStore { RateSheetStore(PreferenceStore prefs); RateSheet load(); Future<void> save(RateSheet s); }
class OptionsReportService { static Future<Uint8List> generate({required List<LoanOption> options, required MemberProfile member, required BrandInfo brand, String? memberName}); }
```
Screen flow: member facts form → today's rates (prefilled from `RateSheetStore`) → option cards (PITI large; cash to close, rate, MI, DTI, and flags as chips) → checkboxes to pick 2–4 options → actions "Options sheet PDF" (`printing` share), "Save to History" (one `addQuoteEntry` per option, notes = option title, so the existing Comparison screen can compare them) and "Open in Calculator" per card.

- [ ] **Step 1: Write failing tests:**
  - `RateSheetStore` round-trips `{'fha_30': 6.25}`. Corrupt JSON loads an empty sheet with no throw.
  - `OptionsReportService.generate` with 3 options returns non-empty bytes, and also with an empty brand.
  - Widget: an empty form shows `—` and the PDF button is disabled. After filling the member facts plus one rate, at least one option card renders. "Save to History" adds N entries for N selected options.
- [ ] **Step 2:** Run the tests. Expected: FAIL.
- [ ] **Step 3:** Implement and register in `service_locator.dart` if `RateSheetStore` needs DI (follow how `PreferenceStore` is provided).
- [ ] **Step 4:** Run the tests. Expected: PASS.
- [ ] **Step 5:** Commit `feat: options builder screen and branded options sheet`.

### Task 12: Wrap-up

- [ ] **Step 1:** Run the full CI locally: `dart format --set-exit-if-changed lib test`, `flutter analyze`, `flutter test --exclude-tags=golden`, `flutter test --tags=golden`. All green.
- [ ] **Step 2:** Run a live web smoke test (`flutter build web --release`, served on a fresh port per CLAUDE.md): open each new workspace entry and run one realistic member through the Options Builder to a PDF.
- [ ] **Step 3:** Add one line to the CLAUDE.md Architecture section: "Options Builder (`features/options`) composes the per-feature calculators; government fee tables live in `core/math/government_fees.dart` and must be re-verified yearly."
- [ ] **Step 4:** Commit `docs: note options builder and fee-table upkeep`.
