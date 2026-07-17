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
| B5 | ARM `_nextRate`: caps of 0 treated as "unset"; lifetime floor applied after cap can exceed cap | P3 | LOG (handoff) |
| B6 | Rent-vs-buy: rent-increase compounds monthly in break-even but annually in projections | P3 | LOG (handoff) |
| B7 | Share dialog hint chips show `{{{token}}}` (triple) vs renderer's `{{token}}` (double) | P3 | ✅ FIXED |
| B8 | Corrupt persisted JSON (session/history/ARM preset) swallowed silently, partial data loss | P3 | LOG (handoff) |
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

## Logged, not changed this pass (rationale)
- **B5 ARM caps/floor:** Real ARMs use non-zero caps; treating 0 as "unset" is defensible, and floor>cap is
  a data-entry error. Changing semantics risks breaking intended behavior without a product decision.
- **B6 Rent-vs-buy compounding:** The monthly-vs-annual rent-increase difference is an approximation choice;
  "correct" depends on intended model. Needs product decision before altering numbers users may rely on.
- **B7 Share brace hint:** Cosmetic/authoring nuisance; low blast radius. Candidate for a follow-up.
- **B8 Silent corrupt-JSON recovery:** Deliberate "keep app usable" design; the real gap is the absence of
  a user-visible notice. UX decision, not a correctness bug.
