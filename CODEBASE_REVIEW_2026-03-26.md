# MLO-CALC Codebase Review
**Date:** 2026-03-26
**Reviewers:** 7 specialized parallel subagents (Architecture, Security, Test Coverage, Performance, Code Quality, Flutter, Dart)

---

## Executive Summary

| Area | Grade | Top Finding |
|------|-------|-------------|
| Architecture | C+ | No centralized router; mixed DI wiring sites; domain models in provider files |
| Security | D | Live API key committed to repo; financial data in plaintext SharedPreferences |
| Test Coverage | D+ | Core math engine (`LoanMath`, `QualificationService`) untested; broken golden |
| Performance | C | FlSpot rebuilt every frame; monolithic provider; formatter alloc per build |
| Code Quality | B- | Errors swallowed silently; 2024 loan limits stale; format inconsistency |
| Flutter | C | God-widgets; duplicate lifecycle code; deprecated M2 API; no `mounted` guard |
| Dart | B- | Unawaited constructors + `double` financial precision are the main risks |

---

## CRITICAL Issues (act immediately)

### CRIT-1 — Live Gemini API Key Committed to Repo
**File:** `zen-mcp-server/.env:2`
A live `AIzaSy...` Gemini API key is stored in plaintext. The `.gitignore` has no `.env` rule, so this file is tracked by git.
- **Action:** Revoke the key in Google Cloud Console NOW
- `git rm --cached zen-mcp-server/.env`
- Add `**/.env` and `.env` to `.gitignore`
- Run `git log -p | grep AIza` to audit history for prior commits

### CRIT-2 — BuildContext Used After Async Gap Without `mounted` Guard
**File:** `lib/src/features/analysis/presentation/screens/analysis_screen.dart:374`
`_generateReport` calls two sequential `await`s with no `if (!mounted) return` in between. If the user navigates away during PDF generation, the second call throws a `FlutterError` on an unmounted widget.
- **Fix:** Add `if (!mounted) return;` after each `await`

### CRIT-3 — Unawaited Futures in Constructors
**Files:**
- `lib/src/core/services/connectivity_service.dart:18`
- `lib/src/core/services/analytics_service.dart:134`
- `lib/src/core/utils/unit_conversion.dart:20`
- `lib/src/features/nlp/application/providers/nlp_settings_provider.dart:19`
- `lib/src/features/share/application/providers/share_templates_provider.dart:16`

`_init()` / `_load()` called without `await` or `unawaited()` in constructors — exceptions silently vanish into the unhandled-Future zone.
- **Fix:** Replace bare calls with `unawaited(_load())` (importing `dart:async`) or use a static `create()` factory

---

## Architecture

### High

**H1 — UI widget holds direct service reference**
`lib/main.dart:106-107` — `_MainNavigatorState` field-injects `NLPCalculatorService` directly from `serviceLocator`. UI widgets should not hold domain services.
Fix: Expose the service through `NlpSettingsProvider` and access via `context.read<>()` inside `_showNLPDialog`.

**H2 — Mixed DI wiring: serviceLocator fallbacks in controllers**
Files: `loan_quote_controller.dart:32`, `qualification_controller.dart:17`, `amortization_controller.dart:14`, `calculator_session_repository.dart:13`, `arm_wizard_provider.dart:12`
All use `?? serviceLocator<X>()` fallbacks alongside explicit injection — two competing wiring sites.
Fix: Remove fallbacks; require callers to always inject explicitly; `CalculatorProvider`'s factory should be the single wiring site.

**H3 — Domain models defined inside provider file**
`lib/src/features/comparison/application/providers/comparison_provider.dart:50-273` — `ComparisonData`, `ComparisonEntryView`, `ComparisonSummary`, and helper functions live inside the provider file.
Fix: Extract to `lib/src/features/comparison/domain/models/comparison_data.dart`.

**H4 — No centralized router**
`Navigator.push` calls scattered across `analysis_screen.dart:379,385`, `history_screen.dart:52`, `loan_programs_screen.dart:95`, `main.dart:178,420,448`.
Fix: Centralize all navigation through `FeatureCatalog._openFeatureById` or introduce an `AppRouter` service.

### Medium

**M1 — `AnalyticsService` as root `ChangeNotifierProvider`**
`lib/main.dart:59` — `AnalyticsService` has no UI state but is in the root provider tree, enabling tree-wide rebuild propagation.
Fix: Register as `LazySingleton` in `service_locator.dart`, drop `ChangeNotifier` mixin.

**M2 — Cross-feature dependency**
`lib/src/features/qualification/presentation/screens/qualification_screen.dart:4` — Qualification screen directly imports `CalculatorProvider`.
Fix: Introduce a shared `LoanParametersReadModel` interface in `lib/src/core/`.

**M3 — `AmortizationScreen` drills through provider facade**
`lib/src/features/amortization/presentation/screens/amortization_screen.dart:31-33` — reaches through `CalculatorProvider` to grab raw controller instances.
Fix: Use `context.watch<AmortizationController>()` directly (already registered as `ListenableProxyProvider`).

**M4 — `ThemeProvider` declared in `main.dart`**
`lib/main.dart:64` — Entry point should be bootstrap-only.
Fix: Move to `lib/src/core/theme/`.

**M5 — `main.dart` imports 22 packages including concrete widget types**
Fix: Wrap navigation targets in `FeatureCatalog` so `main.dart` only imports the catalog.

### Low
- `ArmWizardProvider` scoped at screen level (only feature that does this) — document the intended scoping strategy
- `CalculatorProvider` factory and individual controllers duplicate wiring logic

---

## Security

### Critical
See **CRIT-1** above.

### High

**H1 — Financial session data in plaintext SharedPreferences**
`lib/src/features/calculator/domain/services/persistence_service.dart:24-42` — `annualIncome`, `monthlyDebt`, `loanAmount`, `interestRate`, `downPayment`, `propertyTax`, `homeInsurance` all saved as unencrypted JSON.
Fix: Move to `flutter_secure_storage` (already a project dependency) or exclude from device backups.

**H2 — API key migration window**
`lib/src/features/nlp/application/providers/nlp_settings_provider.dart:62-71` — During migration from SharedPreferences to SecureStorage, the raw API key briefly exists unencrypted. Devices that haven't migrated yet still hold the key in plaintext.
Fix: Force migration on first launch; document that the old `geminiApiKey` SharedPreferences key is compromised on unmigrated devices.

### Medium

**M1 — NLP cache stores financial queries unencrypted**
`lib/src/features/nlp/domain/services/nlp_cache_service.dart:59-67` — Caches user query strings and parsed `CalculationRequest` responses (income, debt, loan amounts) in SharedPreferences.
Fix: Move cache to `flutter_secure_storage` or strip financial values before persisting.

**M2 — Prompt injection risk**
`lib/src/features/nlp/domain/services/nlp_calculator_service.dart:70` — User input embedded directly in Gemini prompt with only control-character stripping and 500-char truncation.
Fix: Wrap user input in XML delimiters (`<user_query>...</user_query>`); validate response strictly against JSON schema before parsing.

**M3 — `debugPrint` of API key errors in release builds**
`lib/src/features/nlp/application/providers/nlp_settings_provider.dart:50,74`
Fix: Wrap in `if (kDebugMode)` guards.

**M4 — Analytics metadata not sanitized**
`lib/src/core/services/analytics_service.dart:243-249` — Free-form `params` map could include financial values.
Fix: Define an explicit allowlist of trackable metadata keys.

### Low
- `.gitignore` has no `.env` rule (see CRIT-1)
- `developer.log` error objects could expose key material from SDK exceptions — use `error: e.toString()`
- `connectivity_service.dart:41` — `debugPrint` emits online/offline status in release builds without `kDebugMode` guard
- No SQLite usage found at runtime — `features.db` is dev tooling only

---

## Test Coverage

### Coverage Map

```
TESTED (unit)
  FinancialValidators          ████████░░  Strong — boundary/null/negative covered
  CalculatorProvider           ███████░░░  Good, but through provider only
  ArmCalculatorService         ████░░░░░░  2 happy-path scenarios only
  QualifyingRatiosProvider     ████████░░  Strong CRUD and persistence coverage
  ComparisonProvider           ██░░░░░░░░  1 test, happy path only
  CalculatorSessionRepository  ████░░░░░░  Legacy migration + save/reload
  CalculatorControllers        ████░░░░░░  LoanQuote, Qualification, Amortization happy paths

UNTESTED (unit)
  LoanMath                     ░░░░░░░░░░  CRITICAL
  CoreCalculationService       ░░░░░░░░░░  CRITICAL
  QualificationService         ░░░░░░░░░░  CRITICAL
  AmortizationService          ░░░░░░░░░░  HIGH
  RentVsBuyCalculator          ░░░░░░░░░░  HIGH
  AdvancedCalculations         ░░░░░░░░░░  HIGH
  DecimalUtils                 ░░░░░░░░░░  HIGH (used in every calc)
  ComparisonExporter           ░░░░░░░░░░  LOW-MED
  NlpCalculatorService.fromJson░░░░░░░░░░  MED

WIDGET TESTS
  CalculatorScreen             ████████░░  Strong
  ComparisonScreen             █████░░░░░  Layout/interaction, no data accuracy
  QualificationScreen          ██████░░░░  DTI regression + field sync
  AmortizationScreen           ███░░░░░░░  Layout only — no schedule content
  WorkspaceDashboardScreen     ████░░░░░░  Render check
  ArmWizardScreen              ░░░░░░░░░░  None
  HistoryScreen                ░░░░░░░░░░  None
  RentVsBuyScreen              ░░░░░░░░░░  None
  AnalysisScreen               ░░░░░░░░░░  None

GOLDEN TESTS
  ComparisonScreen             BROKEN — text reflow diff, baseline not updated
```

### Top 3 Test Priorities

**Priority 1 — Direct unit tests on `LoanMath` and `CoreCalculationService`**
Every single calculation in the app depends on these. No direct tests exist — only indirect coverage through 3 layers of indirection.
Tests needed:
- `calculatePayment(400000, 7.0, 30)` returns `2661.21` (known reference value)
- `calculatePayment(0, 7.0, 30)` returns 0 without throwing
- `calculateInterestRate` converges correctly and handles payment-equals-interest-only boundary
- `CoreCalculationService` returns `CalculationResult.failure` when `LoanMath` returns 0 or NaN

**Priority 2 — Isolated unit tests for `QualificationService`**
The qualification flow is the most legally and financially consequential feature. Currently only tested through `CalculatorProvider`.
Tests needed:
- `calculateMaxLoan` direct call with known `QualifyingRatio` → verify exact loan amount
- Housing-ratio-binding vs debt-ratio-binding scenarios (assert which constraint wins)
- `maxPi <= 0` failure path (debt exceeds income's DTI allowance)

**Priority 3 — `RentVsBuyCalculator`**
300+ lines, multi-step model with PMI boundary logic, break-even, projections — zero tests at any layer.
Tests needed:
- PMI at exactly 80% LTV (should be zero); at 80.01% (should apply)
- Break-even month: known monthly savings ÷ upfront cost = expected month
- Zero-rate path in `_calculateMonthlyPayment`

### Critical Edge Cases Not Covered
| Gap | Risk |
|-----|------|
| `LoanMath.calculatePayment` with `loanAmount == 0`, `interestRate == 0`, `termYears == 0` | HIGH |
| Newton-Raphson solver at payment = interest-only boundary | HIGH |
| `AmortizationService.buildSchedule` with `interestRate <= 0` | MED |
| `RentVsBuyCalculator` with LTV exactly at 80% (PMI boundary) | HIGH |
| `QualificationService.calculateMaxLoan` when `maxPi <= 0` | HIGH |
| Down payment >= purchase price (100% down, loan = 0) | MED |

---

## Performance

### Critical

**C-1 — FlSpot dataset reallocated on every build**
`lib/src/features/amortization/presentation/widgets/amortization_chart.dart:119-143`
Both `lineBarsData` series call `.map(...).toList()` over the full dataset inside `build()`. For a 30-year loan = 360 `FlSpot` allocations per `AnimatedBuilder` frame (every keystroke).
Fix: Convert to `StatefulWidget`; cache `List<FlSpot>` in `initState`/`didUpdateWidget`, only recompute when `data` reference changes.

**C-2 — Monolithic `CalculatorProvider` causes full tree rebuild on every digit press**
`lib/src/features/calculator/application/providers/calculator_provider.dart:79-83,299-304`
All 4 child controllers forward every change to `CalculatorProvider.notifyListeners()`. `Consumer2<CalculatorProvider, CalculatorDisplayNotifier>` in `modern_calculator.dart:180` wraps the entire calculator body.
Fix: Use `Selector` with narrow projections, or split into focused child providers.

### High

**H-1 — `_getMaxY()` iterates 360 entries inside `build()`**
`amortization_chart.dart:197-208` — Not memoized. Fix: Cache with `FlSpot` lists (see C-1).

**H-2 — Mortgage payment recalculated per-row per slider drag frame**
`comparison_screen.dart:159-173,203-250` — Each `setState` from slider `onChanged` recalculates `_project()` → `LoanMath.calculatePayment()` for every view row at 60fps.
Fix: Debounce slider changes; cache `_AdjustedProjection` values keyed on delta values.

**H-3 — `NumberFormat.simpleCurrency()` created per `build()` call**
`comparison_screen.dart:28,309,469`, `arm_wizard_screen.dart:324`, `rent_vs_buy_screen.dart:652,708`
Fix: Hoist to `static final` field at the class level.

**H-4 — `SharedPreferences.getInstance()` called on every write**
`qualifying_ratios_provider.dart:65,79,140`, `loan_programs_provider.dart:74,85,92`, `persistence_service.dart:11,41`
Fix: Store the instance as a field after first `await SharedPreferences.getInstance()`.

**H-5 — DTI computation inline in `AnimatedBuilder`**
`qualification_screen.dart:411-448` — `DtiValidator.calculateHousingDti`, `calculateDti`, `getDtiWarnings` all called synchronously on every keystroke inside a `Builder` inside an `AnimatedBuilder`.
Fix: Move DTI validation into `QualificationController`; expose `dtiWarnings` getter.

### Medium

- `amortization_screen.dart:272-330` — `CurrencyFormatter` list alloc inside `AnimatedBuilder` on every rebuild
- `history_screen.dart:81-104` — `Consumer<ComparisonProvider>` wraps every list item; use `Selector` scoped to `isSelected(id)`
- `workspace_dashboard_screen.dart:13` — `context.watch<HistoryController>()` rebuilds full dashboard on any history mutation
- `rent_vs_buy_screen.dart:528-546` — `FlSpot` projection lists re-mapped on every `setState`
- `amortization_controller.dart:51-52` — Unnecessary 50ms `Future.delayed` before `compute()`

---

## Code Quality

### High

**H1 — Errors silently swallowed as `debugPrint`**
Not guarded by `kDebugMode` and not surfaced to UI:
- `analytics_service.dart:165,192`
- `qualifying_ratios_provider.dart:54,69,82`
- `loan_programs_provider.dart:64,78,92`
- `nlp_settings_provider.dart:50,74`
- `layout_preference_provider.dart:30,46`
Fix: Expose an error state field in providers, or use `FlutterError.reportError`.

**H2 — Unsafe `!` on `overlay` (potential null dereference)**
`calculator_screen.dart:823,959` — `Navigator.of(context).overlay!.context.findRenderObject()` will throw during route transitions.
Fix: Use `?.` and bail early if null.

**H3 — `NlpCacheService._save()` catch block is `// Silently fail`**
`nlp_cache_service.dart:68-70` — No logging whatsoever; queued offline requests silently lost.
Fix: Add at least a `debugPrint` or surface to caller.

**H4 — Commented-out `print` in production catch block**
`calculation_history.dart:350` — `// print('Error parsing calculation history: $e')` — error is now silently discarded entirely.
Fix: Remove comment and add `FlutterError.reportError` or rethrow.

### Medium

**M1 — ~30 raw `Color(0xFF...)` literals in `calculator_screen.dart`**
Lines `175,222,241,264,294,295,319,342,356,370,387,411,425,431,437,444,458,464,470,477,491,497,503,510,530,536,611,758,759,934`
`AppConstants` defines these same colors as named constants but `calculator_screen.dart` never uses them.
Fix: Replace with `AppConstants` named constants or `CalculatorPalette`.

**M2 — Conforming loan limits hardcoded to 2024**
`enhanced_validators.dart:51` — `standardLimit = 766550`, `fhaFloorLimit = 472030` — two years stale as of 2026.
Fix: Add `// TODO: Update annually per FHFA` at minimum; ideally load from versioned config.

**M3 — `_WarningTile` private widget missing `super.key`**
`enhanced_validators.dart:315-319` — triggers `use_key_in_widget_constructors` lint.
Fix: Add `({super.key, required this.warning, required this.compact})`.

**M4 — `toStringAsFixed(2)` bypasses `CurrencyFormatter` in 15+ places**
`analysis_screen.dart:63,87,94,100,210,301,315,486`, `comparison_screen.dart:403,531`, `comparison_exporter.dart:11-13`, `amortization_screen.dart:20-23,213,220,227,234`
Fix: Replace with `CurrencyFormatter.formatCurrency(value)`.

**M5 — `RentVsBuyCalculator._calculateMonthlyPayment` duplicates `LoanMath.calculatePayment`**
`rent_vs_buy_calculator.dart:186-197` — parallel formula with no `DecimalUtils` rounding.
Fix: Inject `LoanMath` and delegate.

**M6 — DTI magic thresholds as raw literals**
`qualification_screen.dart:618,620,622,623` — `28.0`, `36.0` literals instead of `DtiValidator` named constants.

**M7 — `amortization_controller.dart:54-67` — async errors not surfaced**
`try/finally` catches nothing; exception propagates to `async void` call site and is dropped.

**M8 — `CalculationEntry` getters cast `Map` values as `double?` instead of `num?`**
`calculation_history.dart:216,221,232` — JSON-decoded integers will `TypeError`.
Fix: Use `(inputs['loanAmount'] as num?)?.toDouble()`.

### Low
- No `directives_ordering` rule in `analysis_options.yaml` — import style inconsistent
- `calculation_history.dart` uses string-literal enum values (`'payment'`, `'loan_amount'`) — typos produce silent fallback
- `analysis_options.yaml` has no enabled rules beyond the flutter_lints baseline
- `formatters.dart:128-144` — `try/catch` wrapping `double.tryParse` is dead code (it never throws)
- `enhanced_validators.dart:51` — `year = 2024` constant declared but never referenced

---

## Flutter

### Critical
See **CRIT-2** above.

### High

**H-1 — God-widgets: `calculator_screen.dart` (1,019 lines) and `modern_calculator.dart` (961 lines)**
Mix UI layout, keyboard-event routing, memory-menu logic, PITI dialogs, and snack-bar display.
Fix: Extract `_KeypadGrid`, `_MemoryMenu`, `_PaymentOptionsSheet`, `_PitiBreakdownSheet` into separate widget classes.

**H-2 — Duplicate lifecycle and keyboard handler code**
`initState`, `didChangeDependencies`, `dispose`, `_syncPresentedValue`, `_handleKeyPress` (75 lines) — byte-for-byte identical between the two calculator files.
Fix: Extract to a `mixin _CalculatorStateMixin` or abstract `State` base class.

**H-3 — ~30 raw `Color(0xFF...)` literals bypass `CalculatorPalette`**
`calculator_screen.dart:175-934` — `modern_calculator.dart` already uses `CalculatorPalette` correctly; classic layout never does.
Fix: Replace with `CalculatorPalette.colorsForVariant(...)` lookups.

**H-4 — Deprecated `Theme.of(context).primaryColor` under Material 3**
`voice_waveform.dart:40`, `nlp_dialog.dart:366`, `info_dialog.dart:66`
Fix: Replace with `Theme.of(context).colorScheme.primary`.

**H-5 — `TextEditingController`s in inline dialogs never disposed on rotation**
`qualification_screen.dart:534,665` — 4 controllers allocated on stack in `_showRatioEditor`; not disposed if device rotates while dialog is open.
Fix: Promote ratio editor and ratio list into their own `StatefulWidget` classes.

### Medium

- `qualification_screen.dart:79`, `analysis_screen.dart:35` — `context.read` at top of `build()` body
- `animated_display.dart:21` — `StatelessWidget` with hidden `Provider.of` subscription creating a second rebuild path
- `amortization_chart.dart:44` — Fixed `height: 300` with no `LayoutBuilder` adaptation
- `voice_waveform.dart:17` — Fixed `width: 200` inside `AlertDialog` content
- `closing_costs_sheet.dart:40` — `context.read` called inside `initState` (should be `didChangeDependencies`)
- `calculator_screen.dart:821-823,957` — `findRenderObject() as RenderBox` with no null guard
- `nlp_dialog.dart:41` — `speechToText.stop()` future discarded in `dispose()`
- `comparison_screen.dart:22-24` — Slider `setState` rebuilds entire screen including `DataTable` computation

### Low

- `amortization_chart.dart:119-143` — Full 360-item list mapped per build (see Performance C-1)
- `app_theme.dart:71-113` — Hard-coded colors in `TextTheme` block downstream `copyWith` overrides
- Both calculator files — 75-line keyboard handler duplicated verbatim
- `nlp_dialog.dart:250`, `qualification_screen.dart:870,916`, `comparison_screen.dart:401` — Raw `Colors.red/orange/green` not from `ColorScheme`
- `calculator_button.dart:51-77` — 3 `AnimationController`s per button even when `animationType == none` (28 buttons = 84 idle controllers)
- No `ValueKey` on dynamically-built `Wrap`/`ListView` children in `workspace_dashboard_screen.dart:38` and `comparison_screen.dart:95`

---

## Dart

### Critical
See **CRIT-3** above.

### High

**H-1 — Financial precision: `double` arithmetic without per-step rounding in two calculators**
`AdvancedCalculations` (all ARM/APR/FV loops) and `RentVsBuyCalculator._calculateFutureEquity` do not call `DecimalUtils.roundToCents` on intermediate values, unlike `AmortizationService` which does.
Fix: Apply `roundToCents` discipline to all per-step accumulations; extend to `calculateFutureEquity` lines 285-289.

**H-2 — `Map<String, dynamic>` for `CalculationEntry.inputs/results` with unsafe casts**
`calculation_history.dart:13-14` — downstream accessors do `inputs['loanAmount'] as double?`; JSON-decoded integers will `TypeError`.
Fix: Define typed `CalculationInputs` value class, or apply `(v as num?)?.toDouble()` to all accessors.

**H-3 — `NLPCalculatorService` — bang operator on regex match result**
`nlp_calculator_service.dart:130` — `match.group(0)!` is inconsistent with the null-check on `match` at line 126.
Fix: Use `match.group(0) ?? ''` and handle the empty case.

**H-4 — `LoanQuoteState.copyWith` sentinel pattern with unchecked cast**
`loan_quote_state.dart:43-103` — All params typed `Object?`, cast back to typed values. Wrong type passed at runtime = `TypeError` with no compile-time warning. Same pattern in `AmortizationState` and `QualificationState`.
Fix: Migrate to Dart 3 `@immutable` + typed `copyWith` with explicit `clearXxx()` companion methods.

### Medium

- `loan_quote_controller.dart:539` — `dynamic Function(double)` callback type defeats static analysis; use `ValidationResult Function(double?)`
- `_toDouble(dynamic value)` duplicated at `loan_quote_controller.dart:746`, `qualification_controller.dart:173`, `nlp_calculator_service.dart:206` — extract to `DecimalUtils` or an extension
- `CalculationResult<T>` can represent contradictory states; should be a `sealed class CalcResult<T>` with `CalcSuccess` / `CalcFailure` subtypes
- `AdvancedCalculations.calculateARM:98-99` — per-month interest not rounded, unlike canonical `AmortizationService`
- `RentVsBuyCalculator._calculateMonthlyPayment` param `years` typed `int` while `LoanMath` uses `double termYears` — silently truncates fractional terms
- `AnalyticsEvent` — `metadata` is `Map<String, dynamic>?` (mutable); make `@immutable` with `Map<String, Object?>?`

### Low

- `pow()` return type `.toDouble()` casting inconsistent across `loan_math.dart` and `advanced_calculations.dart`
- `CalculationHistory` is mutable with no `copyWith` — reference passed through `HistoryController` could be mutated externally
- `ConnectivityService._init()` — `_isInitialized = true` set after `notifyListeners()` fires in `_updateStatus`, so listeners checking `isInitialized` see `false`
- `_xxxUnset` sentinel `const Object()` declared in 3 separate state files — extract to shared `kUnset` constant
- `NLPCalculatorService._model` not reset to `null` on initialization error — stale reference risk on retry
- `CalculationEntry.id` uses `millisecondsSinceEpoch.toString()` — collision-possible on rapid successive calculations; use `uuid` (already in `pubspec.yaml`)

---

## Recommended Action Plan

### Immediate (before next commit)
1. **Revoke the exposed API key** in `zen-mcp-server/.env` and add `.env` to `.gitignore`
2. **Fix unawaited constructors** — wrap 5 `_init()`/`_load()` calls with `unawaited()` across service/provider files
3. **Add `mounted` guard** in `analysis_screen.dart:374` after async gaps

### Short-term (next sprint)
4. **Move financial session data to `flutter_secure_storage`** — `persistence_service.dart` (dependency already present)
5. **Write direct unit tests for `LoanMath`, `CoreCalculationService`, `QualificationService`** — start with known reference values
6. **Fix broken golden** — run `flutter test --update-goldens test/golden/` after investigating the text reflow in `ComparisonScreen`

### Medium-term (refactoring)
7. **Introduce centralized router** — eliminate scattered `Navigator.push` calls
8. **Break up god-widgets** — `calculator_screen.dart` and `modern_calculator.dart` both exceed 900 lines
9. **Cache `FlSpot` lists** in `AmortizationChart` and `RentVsBuyScreen` to eliminate per-build allocation
10. **Add `RentVsBuyCalculator` tests** — PMI boundary, break-even month, zero-rate path

### Long-term
11. **Replace `CalculationResult<T>` with sealed type** — eliminates all `result.value!` call sites
12. **Replace `copyWith` sentinel pattern** with Dart 3 typed `copyWith` in `LoanQuoteState`, `AmortizationState`, `QualificationState`
13. **Update 2024 conforming loan limits** to current FHFA values and set up annual update process
