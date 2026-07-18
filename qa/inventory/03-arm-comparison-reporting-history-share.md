# QA Inventory 03 — ARM Wizard, Comparison, Reporting/PDF, History, Share

Scope: `lib/src/features/arm/**`, `lib/src/features/comparison/**`, `lib/src/features/reporting/domain/services/report_service.dart` (+ PDF route in `lib/src/core/navigation/app_router.dart`), History (`lib/src/features/history/**` + supporting calculator persistence), `lib/src/features/share/**`.

All line numbers verified against the working tree at the time of writing.

---

## 1. ARM Wizard

### 1.1 Entry point
- `AppRouter.openArmWizard()` pushes `ArmWizardScreen` via `MaterialPageRoute` — `lib/src/core/navigation/app_router.dart:77-84`.
- Only reachable call site: Analysis screen → "Advanced Tools" card → `onLaunchArm` → `_openArmWizard(context)` — `lib/src/features/analysis/presentation/screens/analysis_screen.dart:116,388-390`.
- `ArmWizardScreen` builds a fresh `ArmWizardProvider` in `initState` and fires `unawaited(_provider.loadPreset())` — `lib/src/features/arm/presentation/screens/arm_wizard_screen.dart:35-39`.

### 1.2 Steps / Inputs
Material `Stepper` with 3 steps, all built from the single `ArmScenario` (`lib/src/features/arm/presentation/screens/arm_wizard_screen.dart:173-273`). Every field is a free-text `_NumberField` (numeric keyboard, `double.tryParse`, silently ignores unparsable/empty input — `arm_wizard_screen.dart:350-356`). **No min/max/range validation anywhere** — negative loan amounts, 0-year terms, negative caps, etc. are all accepted by the UI.

| Step | Field | Units | Scenario prop |
|---|---|---|---|
| 0 Loan Basics | Loan Amount | $ | `loanAmount` |
| 0 | Term (years) | yrs | `termYears` |
| 0 | Initial Rate (%) | % | `initialRate` |
| 1 Adjustment Settings | Initial Fixed Period (years) | yrs | `initialFixedYears` |
| 1 | Adjustment Frequency (years) | yrs | `adjustmentFrequencyYears` |
| 1 | Rate Change Per Adjustment (%) | % | `rateChangePerAdjustment` |
| 2 Caps | Periodic Cap (%) | % | `periodicCap` |
| 2 | Lifetime Cap (%) | % | `lifetimeCap` |
| 2 | Lifetime Floor (%) | % | `lifetimeFloor` |

Default scenario values are hardcoded in the provider (`arm_wizard_provider.dart:17-27`): loan 450000, term 30, rate 5.25, fixed 5yr, adj freq 1yr, +1%/adj, periodic cap 2%, lifetime cap 9%, floor 2.5%.

### 1.3 Buttons / actions
- AppBar save icon (`Icons.save_outlined`) → `provider.savePreset()` then a SnackBar "ARM preset saved" — `arm_wizard_screen.dart:75-84`. Fire-and-forget; no error surfaced if the write fails.
- Stepper "Next"/"Done" and "Back" — local `_currentStep` only, step 2 has no "Done" wiring beyond changing label text (last step's Next button does nothing useful since `_currentStep < steps.length -1` is false) — `arm_wizard_screen.dart:106-136`.
- "Generate schedule" `FilledButton.tonalIcon` → `provider.calculate()`, shows a spinner while `isLoading` — `arm_wizard_screen.dart:146-160`.
- Result card lists每 period's months/rate/payment/balance — `arm_wizard_screen.dart:362-418`.

### 1.4 Persistence
`ArmPresetStorage` reads/writes a single preset under key `armScenario` in `SecureStore` (`lib/src/features/arm/domain/services/arm_preset_service.dart:5-27`). `load()` swallows any decode exception and returns `null` (`arm_preset_service.dart:21-25`), so a corrupt stored value silently falls back to defaults with **no user-visible warning**.

### 1.5 Behavior rules (ARM math) — `lib/src/features/arm/domain/services/arm_calculator_service.dart`
- Months: `totalMonths = termYears*12` (rounded, min 1), `fixedMonths`, `adjustmentMonths` likewise (`:14-19`).
- First period length = fixed period; subsequent periods = adjustment frequency, each clipped to `monthsRemaining` (`:33-36`).
- Payment per period is recalculated as a fresh amortizing payment over the *remaining* balance/months at the *current* rate (re-amortization, not just interest swap) — `:38-44,116-131`.
- Zero-rate periods pay balance evenly (`:122-124`).
- Final month of a period/loan forces `principalPaid = balance` to zero out rounding drift (`:60-66`).
- Rate adjustment (`_nextRate`, `:133-161`):
  1. `delta = adjustment`; clamp to `±periodicCap` **only if `periodicCap > 0`** (`:142-144`) — a periodic cap of exactly `0` is treated as "unset"/unlimited, not "no adjustment allowed."
  2. `nextRate = current + delta`.
  3. Clamp to `lifetimeCap` **only if `lifetimeCap > 0`** (`:148-150`) — same "0 means unset" trap.
  4. Clamp to `lifetimeFloor` unconditionally, `nextRate < lifetimeFloor → lifetimeFloor` (`:152-154`) — this runs *after* the lifetime-cap clamp, so a misconfigured `lifetimeFloor > lifetimeCap` will push the rate back **above** the cap.
  5. Final floor at 0 (`:156-158`).
- Loop terminates on `monthsRemaining<=0` or balance effectively zero (`DecimalUtils.isEffectivelyZero`, `lib/src/core/utils/decimal_utils.dart:67`); rounding via `roundToCents`/`roundToDecimal` (`decimal_utils.dart:19-26`).

### 1.6 States
- Loading: spinner replaces the "Generate schedule" icon while `isLoading` (`arm_wizard_screen.dart:147-153`).
- Empty: no result card until first `calculate()` call.
- Populated: `_ArmResultCard` with Total Paid / Total Interest / Adjustment count chips + per-period list.
- Error: **none handled** — `calculateSchedule` is synchronous and any exception (e.g. from `LoanMath.calculatePayment`) is unhandled inside `provider.calculate()` (`arm_wizard_provider.dart:41-47`), which would crash the async gap and leave `isLoading` stuck `true` (no `finally`/try-catch).

### 1.7 Acceptance criteria
1. Given the wizard opens with no saved preset, when it loads, then all 3 steps show the hardcoded defaults (450000/30/5.25/…).
2. Given a saved preset exists, when the wizard opens, then fields update to the stored values once `loadPreset()` resolves (may visibly "pop" after initial default render).
3. Given valid inputs, when "Generate schedule" is tapped, then a result card appears with period count, total paid, and total interest consistent with the ARM math rules above.
4. Given the periodic cap is left at 0, when the rate adjusts, then the full `rateChangePerAdjustment` is applied uncapped (documenting current, possibly unintended, behavior).
5. Given "Save preset" is tapped, then a "ARM preset saved" SnackBar appears and reopening the wizard later restores those values.
6. Given the user is on step 3 (Caps) and taps "Back" repeatedly, then step index decrements to 0 without any field values being lost.
7. Given `initialFixedYears` + remaining term causes `monthsRemaining` to hit 0 mid-period, then the schedule stops without producing a period beyond the loan term.

### 1.8 Risk-based edge cases
1. Periodic cap = 0 → interpreted as unlimited, not zero-tolerance (`arm_calculator_service.dart:142`).
2. Lifetime cap = 0 → interpreted as unlimited (`:148`).
3. Lifetime floor set above lifetime cap → floor clamp (applied after cap clamp) can push the rate above the configured cap (`:148-154`).
4. Corrupt/garbled `armScenario` secure-store JSON → silently discarged, wizard resets to hardcoded defaults with no user notice (`arm_preset_service.dart:21-25`).
5. User types into fields during the async `loadPreset()` window → preset load overwrites in-progress input via `notifyListeners()` replacing the whole `ArmScenario` (`arm_wizard_provider.dart:53-59`, race with `arm_wizard_screen.dart:39`).
6. Negative or zero `termYears`/`loanAmount` accepted by `_NumberField` with no validation — verify calculator doesn't divide-by-zero or produce NaN/negative schedules.
7. Extremely large `termYears` (e.g. 999) → very large `totalMonths` loop; verify no ANR/perf cliff and that `Adjustments` chip count stays sane.
8. `adjustmentFrequencyYears` = 0 → `adjustmentMonths = max(1, 0) = 1` (min 1 enforced, `:16-19`), producing monthly adjustments — confirm this doesn't stack error against `periodicCap` unexpectedly fast.
9. Save preset while `SecureStore.write` fails (e.g., platform channel error) — no error surfaced to user, "saved" toast still fires optimistically before awaiting completion is confirmed only by `await` but no try/catch (`arm_wizard_screen.dart:78-83`).

---

## 2. Comparison

### 2.1 Entry point
- History screen selection mode: select 2-3 entries → tap compare icon → `_startComparison` builds `ComparisonData` and calls `AppRouter.openComparison(data)` — `lib/src/features/history/presentation/screens/history_screen.dart:39-54,150-153`; pushed via `MaterialPageRoute` (`app_router.dart:94-96`).
- Selection is capped at `ComparisonProvider.maxSelections = 3` and requires `>= 2` to enable Compare (`lib/src/features/comparison/application/providers/comparison_provider.dart:10,15,18-23`).

### 2.2 Inputs (Sensitivity sliders) — `lib/src/features/comparison/presentation/screens/comparison_screen.dart:199-227`
| Slider | Range | Divisions | Effect |
|---|---|---|---|
| Interest Rate Δ | -2% .. +2% | 40 | added to each view's base rate, clamped `[0.01, 20]` (`:316`) |
| Term Δ | -5 .. +5 yrs | 40 | added to base term, clamped `[5, 40]` (`:317`) |
| Down Payment Δ | -10 .. +10 pts | 40 | added to derived down-payment %, clamped `[0, 90]` (`:321-324`) |

Projection cache keyed by `entry.id|rateDelta|termDelta|dpDelta` (3-decimal strings), capped at 200 entries with FIFO eviction (`:294-306`).

### 2.3 Buttons / actions
- AppBar share icon → bottom sheet listing each scenario → on tap, opens `ShareQuoteDialog` seeded from that entry via `QuoteShareData.fromCalculationEntry` (`comparison_screen.dart:30-71`).
- AppBar "Export CSV" icon → builds CSV via `ComparisonExporter.buildCsv` and opens a preview bottom sheet with `SelectableText` (`:73-79,110-153`). **No actual file save/share of the CSV** — user must manually copy the selectable text; there's no "Share"/"Save to file" button despite the icon being `Icons.file_download`.

### 2.4 Behavior rules
- Baseline selection = lowest `totalCost` among comparable entries, or first entry if none comparable (`lib/src/features/comparison/domain/models/comparison_data.dart:17-28`).
- Break-even months = `|totalCostDelta| / |monthlyPaymentDelta|`, `null` if payment delta ~0, clamped to `[0,1000]` (`comparison_data.dart:170-188`).
- MI drop month = first month simulated balance ≤ 80% of price; loop bails early if `principalPaid <= 0` (payment doesn't cover interest) (`comparison_data.dart:190-224`).
- CSV export replaces commas in the summary text with semicolons but does **not** quote/escape values — a summary containing a newline or double-quote will corrupt the CSV structure (`comparison_exporter.dart:14`).

### 2.5 States
- Empty history → Compare button disabled (History toolbar, `<2` entries) so Comparison screen itself is unreachable with 0/1 entries.
- Non-comparable entries (missing loan/rate/term/payment) render `—` placeholders in cards, sensitivity table, and CSV (multiple `?? '—'` sites, e.g. `comparison_screen.dart:259-288`).

### 2.6 Acceptance criteria
1. Given 2 history entries selected, when Compare is tapped, then the Comparison screen shows one card per entry with baseline highlighted.
2. Given the Interest Rate Δ slider is moved, when the sensitivity table recalculates, then Adj Rate reflects `base + delta` clamped to `[0.01, 20]`.
3. Given "Export CSV" is tapped, then a bottom sheet shows a CSV header row plus one row per scenario, commas inside summaries replaced with semicolons.
4. Given "Share scenario" is tapped and a scenario chosen, then `ShareQuoteDialog` opens pre-filled from that scenario's `CalculationEntry`.
5. Given an entry lacks `monthlyPayment`/`loanAmount`, when displayed, then all dependent fields show `—` rather than crashing.
6. Given 3 entries are selected (max), then a 4th selection attempt is a no-op (`comparison_provider.dart:18-23`).

### 2.7 Risk-based edge cases
1. Summary text containing a comma, double quote, or newline breaks CSV column alignment (only comma is escaped, and via replacement, not quoting) — `comparison_exporter.dart:14`.
2. All 3 selected entries have `totalCost == null` → baseline falls back to `views.first`, so "cheapest" framing is misleading (`comparison_data.dart:27-28`).
3. `monthlyPayment` present but `interestRate`/`price` missing → sensitivity table shows a computed adjusted payment using rate `0` fallback (`? 0` at `comparison_screen.dart:316`), i.e. potentially nonsensical projections silently rendered instead of `—`.
4. Rapid slider dragging could grow the projection cache to the 200-item cap and start evicting arbitrary (insertion-order) entries mid-interaction (`comparison_screen.dart:304-306`).
5. CSV export bottom sheet has no scroll/size guard for a very long scenario summary — verify layout doesn't clip silently for long "notes".
6. Break-even computation can return exactly `1000` (clamp ceiling) for near-zero payment deltas, which reads as a real value rather than "not meaningful."

---

## 3. Reporting / PDF

### 3.1 Entry points (two independent, divergent paths)
- **Reachable path**: Analysis screen → Advanced Tools → "Generate Report" → `_generateReport` (`lib/src/features/analysis/presentation/screens/analysis_screen.dart:370-386`). Guards on `provider.loanAmount == null` with a SnackBar ("Calculate a loan first…") before generating (`:374-381`). On success calls `Printing.sharePdf(...)` — this hands off to the OS share sheet; **there is no in-app preview for this path**.
- **Unreachable/dead path**: `AppRouter.openReportPreview(provider)` generates the PDF then pushes `_PdfPreviewRoute`, an in-app `PdfPreview` widget (`app_router.dart:102-133`). Grep across `lib/` finds **no call site** for `openReportPreview` — this route appears to be dead code / not wired to any UI trigger.

### 3.2 Report contents — `lib/src/features/reporting/domain/services/report_service.dart`
- Header: title + today's date (`DateFormat.yMMMd()`), optional "Prepared for: {clientName}" (`:44-67`) — `clientName` is never passed by the only live caller (`analysis_screen.dart:383` omits it), so this section never appears in practice.
- Loan Details block: Loan Amount, Interest Rate (3 decimals), Term, Purchase Price, Down Payment, LTV (`:70-135`). LTV shows `'0%'` if `price` is `null`/`0` or `loanAmount` is `null` (`:126-129`).
- Monthly Payment Breakdown table: P&I + conditionally-included Tax/Insurance/PMI/HOA rows (only if non-null) + Total row (`:153-186`).
- Closing Costs & Cash to Close table (`:221-257`).
- Amortization Summary: **totals only** (sum of principal/interest across the full schedule), not a full month-by-month table — only rendered `if (provider.amortizationData.isNotEmpty)` (`:33-34,259-295`). This caps PDF size regardless of loan term length.
- Fixed disclaimer footer (`:297-305`).
- Font: `PdfGoogleFonts.nunitoExtraLight()` fetched at generation time (`:18`) — **implies a network dependency for font loading**; offline/first-run failure is not caught.

### 3.3 States
- Precondition failure: no loan amount → SnackBar, no PDF generated (`analysis_screen.dart:374-381`).
- Generation failure: `generateLoanReport` / font fetch / `doc.save()` throwing is **not try/caught** anywhere in the call chain (`analysis_screen.dart:383`, `app_router.dart:102-104`) — an exception surfaces as an unhandled Future error.
- Share failure: `Printing.sharePdf` failures (e.g., user cancels, no share target) are likewise unhandled.

### 3.4 Acceptance criteria
1. Given no loan amount is set, when "Generate Report" is tapped, then a SnackBar reads "Calculate a loan first to generate a report." and no share sheet opens.
2. Given a valid loan calculation, when "Generate Report" is tapped, then the OS share sheet opens with a file named `loan-estimate.pdf`.
3. Given `propertyTax`/`homeInsurance`/`mortgageInsurance`/`monthlyExpenses` are null, then their respective rows are omitted from the Monthly Payment Breakdown table (not shown as $0).
4. Given `price` is 0 or null, then LTV renders as `0%` rather than throwing a divide-by-zero.
5. Given amortization data has been generated in-session, then the PDF includes a Total Principal/Interest/Cost summary block; otherwise that section is omitted entirely.
6. Given font retrieval fails (e.g., no network on first launch), then the app should not silently hang — flag current lack of error handling as a defect to confirm/reproduce.

### 3.5 Risk-based edge cases
1. No network on first PDF generation (Google Fonts fetch) → unhandled exception path, no user-facing error (`report_service.dart:18`).
2. `openReportPreview`/`_PdfPreviewRoute` in-app preview is dead code — confirm product intent (should it be wired up, or removed?).
3. `clientName` parameter is plumbed through the service but never supplied by the live UI — header personalization is effectively unused.
4. Extremely long loan term with large `amortizationData` — only totals are rendered, so PDF size should stay bounded; verify the *summation* itself doesn't overflow/lag for very large schedules (e.g., 40yr biweekly-adjusted entries).
5. Negative or zero `pitiPayment`/`cashToClose` (bad upstream state) rendered as raw currency with no sanity clamp (`report_service.dart:165-183,221-257`).
6. Concurrent/rapid taps on "Generate Report" — no debounce/disable-while-loading guard visible in `_generateReport` (`analysis_screen.dart:370-386`), so a slow font fetch could allow duplicate share sheets to be queued.

---

## 4. History

### 4.1 Entry point
Always-mounted primary tab (`FeatureCatalog.historyId`, pinned) — `lib/src/core/navigation/feature_catalog.dart:105-115`. Not a pushed route; lives in the bottom nav / rail alongside Calculator/Amortization/Qualification/Analysis.

### 4.2 Inputs — `lib/src/features/history/presentation/screens/history_screen.dart`
| Control | Type | Notes |
|---|---|---|
| Search field | text | filters on `summary`/`notes` (case-insensitive substring), trimmed (`:119-137,236-249`) |
| Type filter chips | choice chips: All/Payment/Loan Amount/Term/Rate/Qualification | single-select, filters by `entry.type.storageName` (`:202-234`) |
| Long-press on a card | gesture | enters selection mode + selects that entry (`:92-99`) |
| Tap on a card (selection mode) | gesture | toggles selection via `ComparisonProvider.toggleSelection` (`:78-91`) |

### 4.3 Buttons / actions
- Compare icon (toolbar): disabled until ≥2 entries exist; toggles selection mode. In selection mode shows a badge with selection count and triggers `_startComparison` once ≥2 selected (`:141-165`).
- "Clear all history" icon: disabled when empty; confirmation `AlertDialog` ("This will permanently remove all saved calculations.") before `historyController.clear()` (`:167-196`).
- Per-card "Apply to calculator" icon → `calculatorProvider.applyHistoryEntry(entry)` (`:83-84,336-340`).
- Per-card "Delete" icon → confirmation dialog showing `entry.summary`, then `historyController.remove(id)` (`:341-364`).
- Exiting selection mode (toggling compare icon off) clears `ComparisonProvider` selections (`:29-37`).

### 4.4 Data model — `lib/src/core/models/calculation_history.dart`
- `CalculationEntry` types: `payment | loanAmount | term | interestRate | qualification`, mapped to/from storage strings via `fromJsonValue`/`storageName` (`:11-71`); unrecognized/garbage `type` values silently default to `payment` (`:37-38`).
- `CalculationHistory` in-memory list, `maxEntries = 100`, newest-first insert with truncation of anything beyond index 100 (`:556-566`).
- `toJsonString()`/`fromJsonString()` round-trip the whole list as JSON (`:594-612`). **`fromJsonString` catches all exceptions and does nothing on failure** (`:602-611`) — critically, `_entries.clear()` runs *before* the per-item parse loop, so if entry N (N>0) throws (e.g. bad `timestamp` via `DateTime.parse`, or `id` missing), entries `0..N-1` remain added but the rest of the list — including anything that would have followed — is silently lost, with no error surfaced and no rollback to the prior in-memory state.

### 4.5 Persistence / autosave flow
- `HistoryController` wraps `CalculationHistory`, exposes `addQuoteEntry`/`addQualificationEntry`/`remove`/`clear`/`replaceFromJson`/`toJsonString`, all firing `notifyListeners()` (`lib/src/features/calculator/application/controllers/history_controller.dart:1-86`).
- `CalculatorProvider` wires `_historyController.addListener(_handleChildChanged)` (`calculator_provider.dart:85`), so **any** history mutation triggers the app's debounced autosave (750ms `Timer`, `calculator_provider.dart:366-379`) which persists the *entire* session snapshot — including `historyController.toJsonString()` — via `CalculatorSessionRepository.save` → `CalculatorPersistenceService.save` → `SecureStore.write('scenarioSession', …)` (`calculator_session_repository.dart:19-76`, `persistence_service.dart:69-72`).
- On load, `CalculatorPersistenceService.load()` tries the secure `scenarioSession` key first; on `FormatException`/`TypeError` it falls back to a legacy flat key-by-key store, migrates it into the new snapshot shape, saves it, then deletes all legacy keys (`persistence_service.dart:35-67,74-79`). If both the secure session **and** the legacy fallback are unusable/empty, defaults (all null / empty history) are used silently.
- `CalculatorProvider._loadState()` wraps the whole hydrate step in try/catch that swallows all errors (`calculator_provider.dart:351-364`) — a persistence failure leaves the app on defaults with no user-facing indication.

### 4.6 States
- Empty: “No history yet / Perform a calculation to see it here.” with a history icon (`:252-271`).
- Populated: card list with type icon, timestamp (`YYYY-MM-DD HH:MM`), 2-line summary, Apply/Delete actions.
- Selection mode: checkboxes replace leading icons, trailing actions hidden (`:311-332`).
- Filtered-to-empty (search/chip yields 0 results): falls into the same `_empty()` view as true-empty — no distinct "no results match your filter" messaging (`:71-73`).

### 4.7 Acceptance criteria
1. Given no calculations have been performed, when History is opened, then the empty state is shown.
2. Given a search query matching no entries but history is non-empty, when applied, then the same empty-state graphic/text is shown (verify this doesn't mislead users into thinking history was cleared).
3. Given "Clear all history" is tapped and confirmed, then all entries are removed and the toolbar's Compare/Clear icons become disabled.
4. Given "Apply to calculator" is tapped on an entry, then the Calculator screen's fields are populated from that entry's inputs/results.
5. Given "Delete" is confirmed on a single entry, then only that entry is removed; others remain in original order.
6. Given a history mutation occurs, then within ~750ms the full session (including history JSON) is persisted to secure storage without blocking the UI.
7. Given the persisted `scenarioSession` value is corrupt JSON, when the app relaunches, then it falls back to the legacy flat store (or defaults) rather than crashing.

### 4.8 Risk-based edge cases
1. Corrupt/partial JSON in the persisted history array — one bad entry silently truncates everything after it with zero user notification (`calculation_history.dart:602-611`).
2. History at exactly 100 entries, add one more → oldest entries beyond `maxEntries` are dropped (`calculation_history.dart:562-565`); confirm this is exactly 100, not 99/101 (off-by-one).
3. Unknown/garbage `type` string in stored JSON silently becomes `payment` (`calculation_history.dart:37-38`) — a restored entry could display under the wrong filter chip.
4. Rapid add/remove/clear actions within the 750ms debounce window — only the latest state is saved (`calculator_provider.dart:366-369`); verify no torn/partial write if the app is killed mid-timer.
5. Selecting entries for comparison, then deleting one of the selected entries from history before tapping Compare — check `ComparisonProvider._selectedIds` doesn't reference a now-missing entry (`comparison_provider.dart:39-49` filters by id so it degrades gracefully, but UI badge count may be stale).
6. Both the secure session key and all legacy keys missing/corrupt on first run — confirm graceful default (no loan data, empty history) rather than a crash.
7. Search query containing regex-special characters — code uses plain `contains`, not regex, so this should be safe, but worth a quick check given `.trim()`/`.toLowerCase()` only (`history_screen.dart:136,241-249`).

---

## 5. Share

### 5.1 Entry point
`ShareQuoteDialog.show(context, data, borrowerName?, scenarioName?, title?)` — a modal `AlertDialog` (`lib/src/features/share/presentation/dialogs/share_quote_dialog.dart:29-49`). Reached today from the Comparison screen's per-scenario share bottom sheet (`comparison_screen.dart:64-70`); `QuoteShareData` can be built from either a `CalculationEntry` (`quote_share_data.dart:60-82`) or a live `LoanParametersReadModel` (`:34-58`).

### 5.2 Inputs
| Field | Type | Notes |
|---|---|---|
| Borrower (optional) | text | seeds `{{borrower_name}}` token, re-renders template live via `_reapplyIfSafe` (`:96-100,118-143,485-506`) |
| Scenario (optional) | text | seeds `{{scenario_name}}` token, same live-reapply behavior |
| Share via | segmented control (compact: dropdown) | `ShareChannel`: Share / Copy / Text / Email / Image (`:675-793`) |
| Template | dropdown | from `ShareTemplatesProvider.allTemplates` (defaults + custom), selecting re-renders body/subject (`:545-573`) |
| Subject | text | only shown for Email/Share/Screenshot channels (`:592-602`) |
| Message (body) | multiline text | freely editable after template render (`:607-615`) |

### 5.3 Buttons / actions
- "Edit template" → dialog to edit name/subject/body of the *current* template; saving upserts a new custom template (id `custom_{slug(name)}`) and switches the channel to it (`:145-256`).
- "Reapply template" → re-renders body/subject from the template, but **only overwrites fields the user hasn't manually diverged from** (compares current text to `_lastRenderedBody`/`_lastRenderedSubject`) (`:118-143`).
- "Save as template" → prompts for a name (+ optional subject), saves current body as a new custom template (`:265-338`).
- Placeholder chips ("tap to copy") → copies a placeholder token to clipboard with a confirmation SnackBar (`:836-855, 885-902`).
- Cancel → closes dialog.
- Send/Copy/Text/Email/Share Image (primary button, label varies by channel via `_buttonLabel`, `:666-672`) → `_send()` (`:348-440`).

### 5.4 Behavior rules — send flow (`_send`, `:348-440`)
- `copy`: writes body to clipboard.
- `shareSheet`: `SharePlus.instance.share(text: body, subject: subject, sharePositionOrigin: ...)`.
- `sms`: builds `sms:?body=...` URI, throws `Exception('Unable to open SMS app')` if `launchUrl` returns false.
- `email`: builds `mailto:?subject=...&body=...` URI, same failure handling.
- `screenshot`: captures the `RepaintBoundary` preview card to PNG via `boundary.toImage` + `toByteData`, shares as a file alongside the text body.
- All branches funnel into a single try/catch; on success the dialog pops and shows a SnackBar ("Copied to clipboard" or "Ready to send"); on failure `_error` is set and shown inline, dialog stays open (`:420-439`).

### 5.5 Template rendering — `lib/src/features/share/domain/services/share_template_renderer.dart`
- Token substitution is literal `{{key}}` (double braces) replace-all per token (`:2-6`).
- Any leftover `{{...}}` (unknown token) is stripped via regex (`:8`).
- Trailing whitespace before newlines collapsed, 3+ consecutive newlines collapsed to 2, final trim (`:9-12`).

### 5.6 Tokens — `lib/src/features/share/domain/models/quote_share_data.dart:84-147`
Includes `borrower_name`, `scenario_name`, `loan_amount`, `interest_rate`, `term_years`, `pi_payment`, `piti_payment`, `monthly_tax/insurance/mi/hoa`, `cash_to_close`, `price`, `down_payment`, plus MLO identity tokens `mlo_name/nmls/company/phone/email` and `disclaimer`, sourced from `MloProfileProvider.toTokenMap()` (`lib/src/features/settings/domain/providers/mlo_profile_provider.dart:143-152`). Any unset field yields an **empty string token**, not a stripped placeholder — since the key exists in the map, the "unknown token" cleanup regex never fires for it.

### 5.7 Modals/sheets
- Edit-template `AlertDialog` (`:160-234`).
- Save-as-template `AlertDialog` (`:273-314`).
- Screenshot preview `RepaintBoundary` only rendered when `_channel == ShareChannel.screenshot` (`:624-638`).

### 5.8 States
- Busy (`_busy`): all interactive controls disabled, primary button shows a spinner (`:471-663` various `enabled: !_busy` / `onPressed: _busy ? null : …`).
- Error: inline red text below the message field, dialog remains open for retry (`:619-623`).
- No-data / missing MLO profile: all MLO tokens render as empty strings (not omitted) — see edge cases below.

### 5.9 Acceptance criteria
1. Given the dialog opens for a scenario, then the body/subject are pre-rendered from the channel-appropriate default template (SMS→`default_sms_short`, Email→`default_email_full`, others→`default_share_full`) — `share_templates_provider.dart:39-48`.
2. Given the user edits the Borrower field, then the body re-renders live only if the user had not already diverged from the previously-rendered text.
3. Given "Copy" channel is selected and Send is tapped, then the body text is copied to the clipboard and a confirmation SnackBar appears.
4. Given "Text"/"Email" is selected and no SMS/mail app is available, then an inline error message appears and the dialog stays open.
5. Given "Share as Image" is selected, then a screenshot preview renders below the form and, on Send, a PNG + text body is handed to the OS share sheet.
6. Given "Save as template" is used with a name, then a new custom template appears in the Template dropdown and becomes selected for the current channel.
7. Given an MLO profile field (e.g. NMLS) is unset, then the corresponding token renders as an empty string in the message, not literal `{{mlo_nmls}}`.

### 5.10 Risk-based edge cases
1. **Placeholder-hint bug**: `_PlaceholdersHelp` chips display tokens as triple-brace `{{{key}}}` (`share_quote_dialog.dart:837,886`), but the renderer and every default template use double-brace `{{key}}` (`share_template_renderer.dart:5`, `share_templates_provider.dart:164-190`). If a user copies the on-screen hint into a custom template body, the token will **not** be substituted, and the cleanup regex leaves a stray trailing `}` in the rendered output (regex `\{\{[^}]+\}\}` greedily consumes the inner `{` as content). Reproduce: tap a placeholder chip, paste into "Edit template" body, save, then re-render.
2. Empty MLO profile (no NMLS/company/phone/email set) → templates like `default_sms_short` render awkward artifacts, e.g. a trailing "— " with nothing after it, or blank lines collapsing but still visible in Email template's identity block (`share_templates_provider.dart:164,180`).
3. `_QuoteCardPreview` (screenshot channel) calls `data.toTokenMap(scenarioName: ...)` **without** `mloTokens` (`share_quote_dialog.dart:925`), so the shared **image** never includes MLO name/NMLS/contact info even when the text body does — inconsistent branding between image and text shares.
4. Very long custom template body/name — no length limit enforced on `TextField`s in Edit/Save-as-template dialogs; verify slug collisions (`_makeCustomId`/`_slug` both strip to `[a-z0-9_]`, `:340-346`/`share_templates_provider.dart:111-118`) don't silently overwrite an existing differently-named template that slugifies to the same id.
5. `launchUrl` for `sms:`/`mailto:` returning `false` on a device with no matching app → surfaced as a generic `Exception` string in `_error`, not a user-friendly message.
6. Screenshot capture when `_screenshotKey` hasn't laid out yet (channel switched and Send tapped before a frame renders) → `boundary == null` throws "Screenshot not ready" (`:442-449`), caught by outer try/catch but worth confirming timing doesn't ever false-trigger this on slower devices.
7. Deleting a custom template that is currently selected for a channel via Settings-level `deleteCustomTemplate` (not exercised from this dialog) — confirm the dialog's `_selectedTemplate` doesn't dangle if `ShareTemplatesProvider` externally removes the in-use template while the dialog is open.

---

## Cross-cutting notes for the QA pass
- **Dead code**: `AppRouter.openReportPreview` / `_PdfPreviewRoute` (in-app PDF viewer) has no reachable call site; only the share-sheet PDF path (`analysis_screen.dart:370-386`) is live. Worth confirming with product whether the in-app preview should be wired up or removed.
- **Silent failure pattern repeats across all 5 areas**: ARM preset load/save, calculator session load/save, and history JSON parsing all wrap failures in empty/near-empty catch blocks with no user-facing error surface (`arm_preset_service.dart:21-25`, `calculator_provider.dart:351-364,375-377`, `calculation_history.dart:602-611`). QA should treat "silent data loss on corrupt storage" as a cross-cutting theme, not five isolated bugs.
