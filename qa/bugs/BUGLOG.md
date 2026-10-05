# MLO-Calc — Bug Log

Source: static inventory (4 subagents) + source verification by lead. Baseline `flutter test` = 254/254
pass, so these are gaps NOT covered by existing tests. Each fixed bug gets a failing regression test
first (reproduction evidence), then a fix.

Severity: P1 = wrong result/crash a real user hits on a common path; P2 = wrong result on a valid but
less common path, or silent failure; P3 = edge/misconfig/cosmetic.

| ID | Title | Sev | Status |
|----|-------|-----|--------|
| B1 | VA / zero-front-ratio qualification returns Infinity min income & always-fails max loan | P1 | ✅ FIXED |
| B2 | Down-payment validator rejects real $100–$9,999 flat amounts (threshold mismatch w/ controller) | P1 | ✅ FIXED (verified live) |
| B3 | PITI setters (tax/insurance/MI/expenses) skip validation → negative values accepted silently | P2 | ✅ FIXED |
| B4 | Theme mode not persisted → dark mode resets to light on every restart | P2 | ✅ FIXED |
| B5 | ARM `_nextRate`: caps of 0 treated as "unset"; lifetime floor applied after cap can exceed cap | P3 | ✅ FIXED |
| B6 | Rent-vs-buy: rent-increase compounds monthly in break-even but annually in projections | P3 | ✅ FIXED |
| B7 | Share dialog hint chips show `{{{token}}}` (triple) vs renderer's `{{token}}` (double) | P3 | ✅ FIXED |
| B8 | Corrupt persisted JSON (session/history/ARM preset) swallowed silently, partial data loss | P3 | ✅ FIXED (history) |
| B9 | Release `web/index.html` `#loading` overlay left in DOM after first frame (cosmetic) | P3 | NOT A BUG |

### B7 fix
Single-sourced the placeholder format via `ShareTemplateRenderer.placeholder(key) => '{{key}}'`, now used
by both the renderer and the dialog's tap-to-copy chips (`share_quote_dialog.dart:837,886`). Regression:
`test/regression/b7_share_placeholder_format_test.dart`.

### B9 re-assessment — not a defect
`web/index.html:77-84` already hides `#loading` on the `flutter-first-frame` event. The element remaining
in the DOM (as `display:none`) is normal; it is not visible. The earlier "leftover overlay" observation
was the browser-automation pane detecting the hidden node, confirmed by the app rendering cleanly in real
Chrome. No change made.

## Fix evidence
- Regression tests: `test/regression/b1_..`, `b2_..`, `b3_..`, `b4_..` — 13 tests, all green.
- Full suite after fixes: **267/267 pass** (`flutter test`). One pre-existing test
  (`financial_validators_test.dart` "Over 100%") corrected: it encoded the B2 bug (assumed 150 = 150%),
  now asserts 150 = $150 flat is valid, matching the controller's real percent/flat heuristic.
- Live (real Chrome, release build): B2 reproduced pre-fix ("Down payment percentage cannot exceed
  100%" on a $5,000 down payment); post-fix the same input computes L/A = $295,000.00 with no error.
- Note: the app renders and runs correctly on Flutter web (CanvasKit). The earlier "stuck on loader"
  appearance was a browser-automation-pane limitation (can't capture the CanvasKit canvas / SW-cached
  stale bundle), NOT an app defect — confirmed by rendering in real Chrome.

---

## B1 — VA / zero-front-ratio qualification is broken  [P1, FIX]
**Files:** `lib/src/features/calculator/domain/services/qualification_service.dart:26-36,62-67`;
`lib/src/core/models/qualifying_ratio.dart:99` (VA `housingRatio: 0`).
**Root cause:** A `housingRatio` of `0` encodes "no front-end constraint" (VA), but the service treats it
as a literal 0% cap.
- `calculateMaxLoan`: `maxPitiHousing = monthlyIncome * (0/100) = 0` → `maxPiti = min(0, debt) = 0` →
  `maxPi <= 0` → always returns failure `'Insufficient income for housing'`. VA borrowers can NEVER get a
  max-loan result.
- `calculateMinimumIncome`: `minIncomeFront = pitiPayment / (0/100) * 12` → **divide-by-zero → Infinity** →
  `max(Infinity, back)` → returns `Infinity`.
**Repro:** Select VA ratio (0/41) → Qualification → any income/payment → max loan errors; min income = ∞.
**Expected:** A zero (or non-positive) front ratio means the front-end constraint is not applied; qualify
using the back-end (debt) ratio alone.
**Fix:** In both methods, when `ratio.housingRatio <= 0`, skip the housing/front-end term (treat as
unbounded) and use only the debt ratio.

## B2 — Down-payment validation rejects legitimate flat amounts  [P1, FIX]
**Files:** `lib/src/core/validators/financial_validators.dart:135-150`;
`lib/src/features/calculator/application/controllers/loan_quote_controller.dart:600-602` (+ `setDownPayment:305-324`).
**Root cause:** Two different percent-vs-dollars thresholds.
- Controller: `downPayment < 100` → percent; `>= 100` → flat dollars (`:600`).
- Validator: values in `(100, 10000)` → rejected as `'Down payment percentage cannot exceed 100%'` (`:137`).
So entering a real down payment of `$100`–`$9,999` (e.g. `$5,000`) is rejected outright, and the controller
would otherwise have treated it as dollars. Values `99` are silently treated as 99% down.
**Repro:** Calculator → set Price `$300,000` → set Down Payment `5000` → error, loan amount never computes.
**Expected:** A flat dollar down payment below the home price is valid. Thresholds must agree.
**Fix:** Align the validator's percent/flat boundary with the controller's (`100`): reject only
`downPayment` in the impossible percent band, i.e. treat `>= 100` as dollars and validate against price;
treat `< 100` as a percent (0–100 valid). Keep the negative check. Update controller comment accordingly.

## B3 — PITI setters skip validation  [P2, FIX]
**File:** `lib/src/features/calculator/application/controllers/loan_quote_controller.dart:326-352`.
**Root cause:** `setPropertyTax/setHomeInsurance/setMortgageInsurance/setMonthlyExpenses` write straight to
state without calling the existing `FinancialValidators.validate{PropertyTax,Insurance,MonthlyExpenses}`,
unlike `setDownPayment`/rate/term/etc. Negative or absurd values flow into PITI, producing wrong payments
with no error.
**Repro:** Calculator → assign Property Tax `-5000` → accepted; PITI reduced by a negative tax.
**Expected:** Reject negative / over-max PITI inputs the same way other fields are validated, surfacing
`calculationError`.
**Fix:** Route each setter through its validator (MI reuses insurance bounds) and set `calculationError` on
failure, mirroring `setDownPayment`.

## B4 — Theme mode is never persisted  [P2, FIX]
**File:** `lib/src/core/theme/theme_provider.dart` (whole class).
**Root cause:** `ThemeProvider` holds `_themeMode` in memory only; no load/save. Every other user setting
persists via `PreferenceStore`. Toggling to dark and relaunching reverts to light.
**Repro:** Settings → enable dark mode → restart app → back to light.
**Expected:** Selected theme mode persists across launches.
**Fix:** Inject `PreferenceStore`, `load()` the saved mode during bootstrap, and persist on change. Keep a
no-arg default constructor path so existing widget tests that build `ThemeProvider()` still work.

---

## B5 fix — ARM cap is the hard ceiling over floor
**File:** `lib/src/features/arm/domain/services/arm_calculator_service.dart:148-157`
**Product decision:** `0` for periodicCap/lifetimeCap = "no constraint" (unset). Cap is the absolute
maximum rate; floor must not push the rate above it. Fixed by applying floor before cap in `_nextRate`
so the cap always wins on the final clamp. A floor > cap is user input error; cap wins silently.
**Regression:** `test/regression/b5_arm_cap_floor_precedence_test.dart` (4 tests).

## B6 fix — Break-even simulation uses annual rent step
**File:** `lib/src/features/rent_vs_buy/domain/services/rent_vs_buy_calculator.dart:263`
**Product decision:** Rent increases once per year at lease renewal, not continuously. Annual step is
the correct model. Changed `_calculateBreakEvenWithEquity` from monthly compound (`rate/12` per month)
to annual step (`if (month % 12 == 0)` × full annual rate), matching `_generateProjections`.
**Hand-verified:** for the simple test scenario (0% interest/appreciation), annual step → breakEvenMonth
≈ 117; monthly compound → 111.
**Regression:** `test/regression/b6_rent_vs_buy_rent_increase_compounding_test.dart` (3 tests).

## B8 fix — History JSON resilience (partial)
**File:** `lib/src/core/models/calculation_history.dart:602-618`
**Product decision:** Keep app usable. Per-entry try/catch + atomic swap: build a fresh list from
successfully parsed entries, replace `_entries` only after all parsing completes. A corrupt entry is
skipped; valid entries on either side are preserved. Top-level JSON parse failure returns early without
touching existing in-memory state (already true for decode failure, now explicit).
**Scope:** ARM preset service already returns null on failure (correct). Calculator session already catches
FormatException + TypeError specifically (correct). Only the history list needed this fix.
**Regression:** `test/regression/b8_history_json_resilience_test.dart` (4 tests).

---

## Previously logged, not changed this pass (rationale)
- **B7 Share brace hint:** Cosmetic/authoring nuisance; low blast radius. Candidate for a follow-up.

---
## Round 2 (post-PR #9 code: NLP overhaul, updater, chip clear, classic display)
Baseline: analyze clean, 354/354 tests. After fixes: analyze clean, **362/362**.

| ID | Title | Sev | Status |
|----|-------|-----|--------|
| B10 | NLP local parser: "20% down at 6.5%" returned rate=20; "N% down" never captured | P1 | ✅ FIXED (`nlp_down_payment_parsing_test`) |
| B11 | NLP local parser: "down payment 20000" also parsed as monthly payment | P2 | ✅ FIXED (same test) |
| B12 | Updater: release without APK silently "succeeds"; non-200 APK download written as .apk; double-tap Install starts 2 downloads | P2 | ✅ FIXED (`updater_install_guards_test`) |
| B13 | History load ignores 100-entry cap (5,000 persisted entries all loaded) | P3 | ✅ FIXED (`history_scale_cap_test`) |
| B14 | Classic display: value/badge/chip text uses `onSecondary` (white with custom accent) on pale light card → unreadable; seen live in Chrome | P2 | ✅ FIXED (`classic_display_contrast_test`, verified fails pre-fix) |

Not changed (judgment): `isNewer` ignores pre-release suffix (1.2.0-rc1 == 1.2.0); asset with null name
surfaces as generic "Connection failed". Live pass covered release web build smoke only (calculator
inputs, chips); modern layout, NLP sheet, Qualification/Analysis redesign not driven live this round.

### Round 2b (live pass on fixed build, real Chrome)
| ID | Title | Sev | Status |
|----|-------|-----|--------|
| B15 | Settings profile accepts non-numeric NMLS ("12ab") and malformed email, printed on shared quotes | P3 | ✅ FIXED (`b15_mlo_profile_validation_test`) |
| B16 | Voice/Text sheet: Enter inserts a newline (multiline field) instead of submitting; send button/suggestion hiding never update while typing | P2 | ✅ FIXED (`b16_nlp_sheet_typing_test`, verified fails pre-fix) |

Live-verified OK: B14 display contrast fixed; Settings profile save; Voice/Text sheet opens + dismisses;
Rent vs Buy defaults + Calculate renders verdict; Qualification/Analysis/History render, no console errors.
Not verifiable here: scrolling below the fold (automation wheel/keys did not scroll Flutter lists; the
embedded browser viewport is short), Share dialog, modern-layout toggle, Android install flow.

### Round 2c (live: Rent vs Buy, Settings, modern layout, Share)
| ID | Title | Sev | Status |
|----|-------|-----|--------|
| B17 | Modern layout: DnPmt chip shows "$20.00" for a 20% entry; assignment toast says "Rate = $6.50", "Term = $30.00" | P3 | ✅ FIXED (`b17_modern_chip_units_test`) |
| B18 | Rent-vs-Buy net-worth chart: y-labels wrapped/garbled ("$74,350.\n71"), x-axis repeated "Yr 1" ×5 (fractional ticks) | P3 | ✅ FIXED + verified live (widget test fails pre-fix) |
| B19 | Share quote: empty profile fields leave dangling " |" ("Jane \| NMLS# 12ab \|"); `{{down_payment}}` renders "$20" for a 20% down entry | P3 | ✅ FIXED (`b19_share_render_cleanup_test`; down_payment token converted to dollars) |

Live-verified: modern layout + dark mode render, chip assign/double-tap clear/undo, Settings sections incl.
Check for Updates ("latest version"), Voice/Text sheet, Rent-vs-Buy chart fix.
Not verifiable via automation: long-press popup (covered by widget test only).
Observation (product call, unchanged): the Rent-vs-Buy "Net Worth Projection" subtracts cumulative spending from
both sides, so both lines can go negative; it is a relative comparison, not absolute net worth.
Share dialog layout: action row ("Cancel / Save as template / Share") overlaps the placeholder-chip list at
1827x950 — not fixed this round.

### Round 2d (live: Share, Amortization, Qualification)
| ID | Title | Sev | Status |
|----|-------|-----|--------|
| B20 | Share dialog content was a non-scrolling Column: on short windows content ran under the action row / past the card (live: chips overlapped "Cancel / Save as template / Share") | P2 | ✅ FIXED (`b20_share_dialog_scroll_test`, fails pre-fix) |
| B21 | Amortization chart y-axis repeats labels ("$3k $3k $2k $2k $1k $1k $0k") on small loans | P3 | ✅ FIXED (`b21_amortization_axis_labels_test`) |
| B22 | After "Min Income", Qualification shows "Housing DTI 28.0% exceeds 28.00% limit" — min income lands exactly on the limit and float noise (28.000000000000004 > 28) trips the warning; 89% of sampled payments reproduce | P2 | ✅ FIXED (`b22_dti_boundary_test`, 63,456 spurious warnings pre-fix → 0) |

Live-verified OK: B19/B20 share down_payment token ($90,000) and clean message; amortization schedule math
(month 2 interest $1,948.24 ✓), extra-principal card (+$100/mo → 3.4 yrs, $62.9k saved); min income $97,518.86
= PITI×12/0.28 ✓.
Observation (unchanged): Min Income overwrites the user's Annual Income field with the computed value.

### Round 2e (live: Analysis, ARM wizard, History, Loan Programs)
| ID | Title | Sev | Status |
|----|-------|-----|--------|
| B23 | Balloon calculator accepts a balloon year beyond the loan term (40 yrs on a 30-yr loan → "$0.00 after 40 years") | P3 | ✅ FIXED (`b23_balloon_years_test`) |
| B24 | Conforming/FHA limits are 2024 values (`ConformingLoanLimits`: $766,550 / $1,149,825; Loan Programs shows "Max Loan $767K") while the app date is 2026 | P2 | ⚠️ NOT CHANGED — regulatory numbers; needs confirmed current FHFA/HUD figures from the owner |

Live-verified OK: balloon balance 7 yrs = $325,499.05 (hand calc ≈ $325.5k ✓); ARM wizard payment $2,484.92 on
$450k/5.25%/30y ✓ and schedule renders; History lists the calculation with correct summary; Loan Programs list +
New Program editor shows range errors for 150% / -5%.
Not covered: Workspace Dashboard, PDF report, Closing Costs sheet, APR estimator, Future Value, Comparison.

### Round 2f (live: Closing Costs, APR, Future Value, PDF, Workspace Dashboard)
| ID | Title | Sev | Status |
|----|-------|-----|--------|
| B25 | History entry for a solved interest rate (and term) dropped its payment input → Workspace "Recent Activity" showed "$360,000 loan at $0.00/mo → 6.500%" | P2 | ✅ FIXED (`b25_rate_history_payment_test`, fails pre-fix) |

Live-verified OK: Closing Costs "Estimate" (total $5,870, cash to close $95,870 = $90,000 + fees, reflected in the
Analysis summary); APR estimate 6.621% for $4,500 fees on $360k @ 6.5% (plausible); Future Value $521,673.33 =
$450,000 × 1.03^5 ✓; Workspace Dashboard renders pinned tools/templates/recent activity; session (loan inputs)
restores after a full page reload.
Observations (unchanged): PDF Report calls `Printing.sharePdf` with no try/catch or feedback (browser download on
web; nothing visible in automation); automation can only exercise bottom sheets/dialogs after a throwaway click
(first click after a dismiss is dropped by the harness, not the app).
Not covered live: Comparison (needs 2 history entries; widget + golden tests only), long-press popup, Android install.
