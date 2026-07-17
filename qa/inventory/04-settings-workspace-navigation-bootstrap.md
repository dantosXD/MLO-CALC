# QA Inventory 04 — Settings, Workspace Dashboard, Navigation & Bootstrap

Scope: Settings screen + all settings-related providers, Workspace Dashboard, MainNavigator/AppRouter/Theme, and app bootstrap. Read-only inventory for QA test-case authoring.

---

## 1. Settings Screen

**File**: `lib/src/features/settings/presentation/screens/settings_screen.dart`

### Route / entry point
- App bar "More" popup menu (`⋮`/gear icon) → **Settings** → `AppRouter.openSettings()` pushes `SettingsScreen` via `MaterialPageRoute`.
  - Entry point: `lib/main.dart:337-338` (`case 'settings': context.read<AppRouter>().openSettings();`)
  - Router: `lib/src/core/navigation/app_router.dart:69-71`
- Single scrollable `ListView` with 6 sections separated by `Divider(height: 32)`: MLO Profile, Disclaimer, Calculator Defaults, Appearance, Calculator Layout, AI/Voice (`settings_screen.dart:17-30`).
- **Note**: Share-template management and Qualifying-Ratio selection are NOT on this screen despite being settings-like. Share templates are managed inline inside `ShareQuoteDialog` (`lib/src/features/share/presentation/dialogs/share_quote_dialog.dart`), reached from the app-bar share icon, not from Settings. Qualifying ratio selection/CRUD lives in `qualification_screen.dart`, not Settings. Flag this as a possible IA/discoverability gap for QA (testers may expect these under Settings).

### 1.1 MLO Profile section
Provider: `MloProfileProvider` (`lib/src/features/settings/domain/providers/mlo_profile_provider.dart`)

**Inputs** (all `TextField` via `_SettingsTextField`, `settings_screen.dart:146-187`):
| Field | Label | Keyboard type | Validation | Persist target |
|---|---|---|---|---|
| Full Name | "Full Name" | text | none (any string, trimmed on save) | SecureStore key `mlo_name` |
| NMLS # | "NMLS #" | `TextInputType.number` | **none enforced** — no min length, no numeric-only regex, no required check | SecureStore key `mlo_nmls` |
| Company/Brokerage | "Company / Brokerage" | text | none | **PreferenceStore** (shared prefs) key `mlo_company` — NOT secure store, despite being business PII |
| Phone | "Phone" | `TextInputType.phone` | none | SecureStore key `mlo_phone` |
| Email | "Email" | `TextInputType.emailAddress` | none (no email-format validation) | SecureStore key `mlo_email` |

Behavior rules:
- Fields are pre-filled once via `didChangeDependencies` guarded by `_initialized` flag (`settings_screen.dart:86-97`); provider is read once via `context.read` — no live external-update reflection while screen open.
- `_dirty` flag flips true on any `onChanged`; "Save Profile" button disabled until dirty (`settings_screen.dart:109-111, 192`).
- Save calls `MloProfileProvider.saveProfile()` which trims all 5 fields before persisting (`mlo_profile_provider.dart:80-100`, trimming happens in `_save()` at `settings_screen.dart:113-120`).
- PII split: name/NMLS/phone/email → `SecureStore.write()`; company → `PreferenceStore.setString()` (`mlo_profile_provider.dart:93-99`). **NMLS number, arguably the most regulator-sensitive field, is treated as PII (secure store) while Company is not** — inconsistent but intentional per code comments.
- Subtitle text asserts "NMLS# is required by federal law" (`settings_screen.dart:140`) but there is **no enforcement** — field can be saved blank.

**Buttons**: "Save Profile" (`FilledButton.icon`, disabled when `!_dirty`) → shows `SnackBar` "Profile saved" for 2s (`settings_screen.dart:123-129`).

**States**: first-run = all fields empty string (provider defaults `''`, `mlo_profile_provider.dart:16-20`); no loading spinner shown while `MloProfileProvider.load()` runs during bootstrap (see §4) — screen isn't reachable until bootstrap completes anyway.

### 1.2 Disclaimer section
- Multi-line `TextField`, `maxLines: 5`, `maxLength: 600` (`settings_screen.dart:260-268`) — Flutter's default counter/truncation applies at 600 chars.
- Default value: `'Estimates only. Not a loan offer. Taxes/insurance/MI may vary.'` (`mlo_profile_provider.dart:23-24`).
- Persists to **PreferenceStore** key `mlo_disclaimer` (not secure store) via `saveDisclaimer()` (`mlo_profile_provider.dart:102-106`).
- "Save Disclaimer" button, same dirty-gating pattern; snackbar "Disclaimer saved".
- This text is injected into share templates via `{{disclaimer}}` token (`mlo_profile_provider.dart:143-152`, consumed by `share_template_renderer.dart`).

### 1.3 Calculator Defaults section
Fields (all optional numeric, `TextInputType.number` or `numberWithOptions(decimal:true)`, no min/max/format validation — parsed with `double.tryParse`, silently becomes `null` on invalid input, `settings_screen.dart:335-339`):
| Field | Hint | Persist key |
|---|---|---|
| Interest Rate % | 6.875 | `mlo_default_rate` |
| Term (years) | 30 | `mlo_default_term` |
| Down Payment % | 20 | `mlo_default_down_pct` |
| Prop. Tax Rate % | 1.2 | `mlo_default_tax_rate` |
| Insurance Rate % | 0.5 | `mlo_default_ins_rate` |

- All persist to **PreferenceStore** (`_saveOptionalDouble`, `mlo_profile_provider.dart:135-141`) — clearing a field (`double.tryParse('')` → null) calls `_preferences.remove(key)`.
- **Behavior rule**: These defaults are applied only once, at bootstrap, "if empty" — `AppBootstrapGate._bootstrap()` calls `calculator.applyDefaultsIfEmpty(interestRate:, termYears:)` (`app_bootstrap_gate.dart:63-66`). Only **interest rate and term years** are actually wired into the calculator; down payment %, tax rate, and insurance rate are saved/loaded but **never consumed anywhere** (no call sites found for `defaultDownPaymentPct`, `defaultPropertyTaxRate`, `defaultInsuranceRate` outside the provider itself) — likely dead/unfinished feature. QA should verify these 3 fields have any observable effect (expected: none currently).
- Snackbar: "Defaults saved — applied to new sessions" — may mislead the user for the 3 unused fields.

### 1.4 Appearance section
Provider: `ThemeProvider` (`lib/src/core/theme/theme_provider.dart`) + `MloProfileProvider.accentColorValue`.

- **Dark Mode toggle**: `SwitchListTile`, bound to `theme.themeMode == ThemeMode.dark`, `onChanged` calls `theme.toggleTheme()` (`settings_screen.dart:488-497`).
  - `ThemeProvider.toggleTheme()` only flips `light ⇄ dark` (`theme_provider.dart:8-13`) — **no `ThemeMode.system` option anywhere in the app.**
  - **Critical**: `ThemeProvider` has **no persistence at all** — no `PreferenceStore`, no `load()`. `_themeMode` always initializes to `ThemeMode.light` (`theme_provider.dart:4`). Dark mode selection **does not survive app restart**. This looks like a genuine bug/gap given every other setting in this screen persists.
- **Accent Color**: 8 fixed swatches (Teal/Navy/Indigo/Violet/Emerald/Amber/Rose/Slate — `settings_screen.dart:468-477`) rendered as tappable circles in a `Wrap`. Tap → `MloProfileProvider.setAccentColor(int)` (`settings_screen.dart:518-520`).
  - Persists as `.toString()` of the ARGB int to PreferenceStore key `mlo_accent_color` (`mlo_profile_provider.dart:129-133`); reloaded via `int.tryParse(...) ?? 0xFF0891B2` fallback (`mlo_profile_provider.dart:68-71`).
  - Selected swatch shown via `onSurface`-colored 3px border + check icon + glow shadow (`settings_screen.dart:529-554`).
  - Applied globally: `LoanRangerApp` builds `MaterialApp.theme`/`darkTheme` from `Color(mloProfile.accentColorValue)` fed to `AppTheme.lightTheme(accent:)`/`darkTheme(accent:)`, which switch to `ColorScheme.fromSeed(seedColor: accent, ...)` when `accent != null` (`main.dart:124-129`, `app_theme.dart:32-45,150-163`). Default (never customized) accent renders via the hard-coded palette branch instead of the seed algorithm — i.e. default look and "explicitly picked Teal" (same hex) can render subtly differently since one path is `ColorScheme.light(primary: primaryTeal, ...)` and the other is `ColorScheme.fromSeed(seedColor: primaryTeal)`.

### 1.5 Calculator Layout section
Provider: `LayoutPreferenceProvider` (persists via `PreferenceStore`, not read in this task's scope but referenced at `settings_screen.dart:3,570-609`).
- Two `RadioListTile<CalculatorLayout>` — Classic vs Modern (both marked `// ignore: deprecated_member_use`, meaning `RadioListTile.groupValue`/`onChanged` are already deprecated Flutter APIs — future SDK upgrade risk).
- `onChanged` calls `pref.setLayout(v!)`.

### 1.6 AI / Voice (NLP) section
Provider: `NlpSettingsProvider` (`lib/src/features/nlp/application/providers/nlp_settings_provider.dart`)

**Input/entry**: `ListTile` "Gemini API Key", subtitle shows "Configured" (green) if `apiKey != null`, else "Not set" (`settings_screen.dart:626-634`). Tapping opens a **modal bottom sheet** (`showModalBottomSheet`, `isScrollControlled: true`, `settings_screen.dart:643-712`).

**Modal contents**:
- `TextField` "API Key", `obscureText: true`, prefilled with current key (`settings_screen.dart:665-674`).
- "Save" button (`ElevatedButton.icon`) → `settings.setApiKey(controller.text)` → pop + snackbar "API key saved".
- "Clear" button (`TextButton`) → clears controller, `settings.setApiKey(null)` → pop + snackbar "API key cleared".
- Static caption: "Stored locally using secure storage." (`settings_screen.dart:704-707`).

**Behavior rules / persistence**:
- `NlpSettingsProvider.setApiKey()` trims input; if null/empty, deletes from `SecureStore` (`nlp_settings_provider.dart:83-96`); otherwise writes to `SecureStore` key `geminiApiKey`.
- **No validation of API key format/length before saving** — any string, including empty-after-trim, whitespace-only, or garbage, is accepted and marked "Configured" as long as it's non-empty after trim.
- **Legacy migration**: on `load()`, if SecureStore has no key, falls back to reading the same key name (`geminiApiKey`) from the old `PreferenceStore` (unencrypted shared prefs), migrates it into SecureStore, then deletes the legacy value (`nlp_settings_provider.dart:58-67`). On every `setApiKey` call it also proactively removes the legacy key (`nlp_settings_provider.dart:90,95`) — so a stale plaintext key cannot linger once any settings action is taken, but **could still linger from a previous app version until the user opens Settings or otherwise triggers `load()`**.
- `load()` errors are swallowed (`catch (e) { ... _apiKey = null; }`, `nlp_settings_provider.dart:68-72`) — a SecureStore failure silently presents as "Not set" rather than surfacing an error to the user.
- No key format validation happens against the real Gemini API until actually used for a query elsewhere.

### Acceptance criteria — Settings screen
1. Given a first-run profile, When Settings opens, Then all MLO Profile fields are empty and "Save Profile" is disabled.
2. Given the user edits any single MLO Profile field, When they tab away without saving, Then "Save Profile" is enabled and the value is NOT yet persisted (verify via app restart before save).
3. Given the user saves a profile with a non-numeric NMLS (e.g. "abc"), When saved, Then it persists as-is with no validation error (documenting current permissive behavior).
4. Given the user taps a different accent swatch, When selection changes, Then app-wide `MaterialApp` theme (light and dark) updates immediately and the choice survives app restart (PreferenceStore-backed).
5. Given the user toggles Dark Mode, When the app is fully restarted (not hot-reloaded), Then the app reverts to Light mode (current no-persistence behavior — document as expected-per-code, likely unintended).
6. Given the user enters an API key and taps Save, When Settings is reopened, Then the ListTile shows "Configured" and the bottom sheet prefills the same key.
7. Given the user taps Clear on the API key sheet, When confirmed, Then the ListTile reverts to "Not set" and `SecureStore` no longer contains `geminiApiKey`.
8. Given Calculator Defaults has Interest Rate and Term set, When a brand-new calculator session starts (no prior session state), Then those two fields prefill; Down Payment/Tax/Insurance defaults do NOT prefill anything (current dead-code behavior).

### Risk-based edge cases — Settings screen
1. Blank/whitespace-only NMLS saved and used in share templates — `{{mlo_nmls}}` token renders as `''` (empty) since `mlo_profile_provider.dart:146` only prefixes "NMLS# " when non-empty; downstream share text may look broken (e.g., "— Jane Smith " with trailing space, no NMLS).
2. Very long strings (Company, Disclaimer past 600 chars enforced by `maxLength`, but Name/Phone/Email have no length cap) — potential secure-storage entry size or UI overflow.
3. Invalid/garbage Gemini API key accepted silently; first NLP query will fail downstream, not at save time — confirm the resulting error UX is not confusing (mismatched "Configured" status vs actual failure).
4. Secure storage unavailable/denied (web platform, or Android Keystore reset, or locked device) — `SecureStore.write/read` could throw; `MloProfileProvider.load()` swallows errors (`mlo_profile_provider.dart:73-77`) leaving name/NMLS/phone/email blank with no user-facing warning; `NlpSettingsProvider` behaves the same way (silently `_apiKey = null`).
5. Accent color persisted as a raw int string; a corrupted/edited-by-hand pref value falls back via `int.tryParse(...) ?? 0xFF0891B2` (`mlo_profile_provider.dart:70`) — verify no crash on malformed values.
6. Rapid toggling of Dark Mode / accent color while `MaterialApp` rebuilds — verify no theme flash/jank, and re-confirm no persistence regression for accent (persisted) vs theme (not persisted).
7. Calculator Defaults: user sets Down Payment/Tax/Insurance expecting them to prefill new calculator sessions — they never do (dead binding) — likely to be reported as a bug by testers unaware of the gap.
8. `_MloProfileSectionState`/`_DisclaimerSectionState`/`_CalculatorDefaultsSectionState` all read the provider **once** via `context.read` in `didChangeDependencies`; if the provider's underlying values change from elsewhere (e.g., a future "reset profile" action) while Settings is already mounted, the text fields will NOT reflect the update.

---

## 2. Unit Conversion (`lib/src/core/utils/unit_conversion.dart`)

Not surfaced on the Settings screen itself (no UI in `settings_screen.dart` binds to `UnitConversionProvider`) — toggle widgets (`UnitToggleButton`, `UnitSegmentedButton`) are presumably consumed inline within calculator/qualification screens (outside this file's scope). Documenting the provider contract since QA will encounter it elsewhere:

- Three independent unit axes, each persisted as a **string enum tag** to PreferenceStore:
  - Tax/Insurance: `TimeUnit.annual|monthly` → key `unit_tax_insurance`, values `'monthly'|'annual'` (default annual) (`unit_conversion.dart:13,22,63-69,137-138`).
  - Down Payment: `AmountUnit.percentage|dollar` → key `unit_down_payment` (default percentage) (`unit_conversion.dart:14,23,71-77,140-141`).
  - Term: `TermUnit.years|months` → key `unit_term` (default years) (`unit_conversion.dart:15,24,79-85,143-144`).
- Conversion math:
  - `toAnnual(value)` = `value * 12` if monthly else `value` (`:89-91`); `fromAnnual(annual)` = `annual / 12` if monthly else `annual` (`:94-96`).
  - `toDownPaymentDollars(value, homePrice)` = `homePrice * (value/100)` if percentage else `value` (`:99-104`).
  - `toDownPaymentPercent(value, homePrice)` = `(value/homePrice)*100` if dollar **and `homePrice > 0`**, else returns `value` unchanged (`:107-112`) — division-by-zero guarded, but silently returns the raw dollar value mislabeled as a percent when `homePrice == 0`; potential display bug worth a targeted test.
  - `toYears(value)` = `value/12` if months else `value` (`:115-117`); `fromYears(years)` = `years*12` if months else `years` (`:120-122`).
- `load()`/`_save()` wrap all PreferenceStore calls in try/catch and only `debugPrint` on failure — silent failure mode consistent with other providers in this app.
- Note: `_save()` calls `_preferences.load()` again before writing every toggle (`:154`) — redundant but harmless since `PreferenceStore.load()` is idempotent (`_preferences ??= ...`).

### Risk-based edge cases — Unit conversion
- Toggling Down Payment unit while `homePrice == 0` (e.g., before purchase price entered) — verify `toDownPaymentPercent` doesn't display a dollar figure mislabeled as `%`.

---

## 3. Workspace Dashboard

**File**: `lib/src/features/workspace/presentation/screens/workspace_dashboard_screen.dart`

### Route / entry point
- App bar "More" menu → **Workspace Dashboard** (`main.dart:343-344,371-378`) → `AppRouter.openWorkspaceDashboard()` pushes the screen and **awaits a `String?` result** (`app_router.dart:65-67`).
- Any card's "Open"/arrow action calls `Navigator.of(context).pop(feature.id)` (or `pop(featureId)` for history rows) — i.e. the screen is a **selector**, not a standalone destination; selecting a tool pops the route and returns control to `MainNavigator._openWorkspaceDashboard()` (`main.dart:255-264`), which then either switches the bottom-nav/rail tab (if the id matches a primary feature) or pushes the feature screen via `AppRouter.openFeatureById` (`main.dart:266-283`).

### Contents / states
- **Hero card** (`_WorkspaceHero`, `:181-246`): gradient container showing 3 `_MetricChip`s — Templates (`ScenarioCatalog.defaults.length`), Recent items (`totalCount`), Pinned tools (`FeatureCatalog.primaryFeatures.length` = 5, all 5 primary features have `pinned: true` per `feature_catalog.dart:70,81,92,103,114`).
- **Pinned Tools** section: `Wrap` of compact `_FeatureCard`s (width 240) for all 5 pinned features; tapping "Open" pops with that feature's id.
- **Scenario Templates** section: static `Chip` list from `ScenarioCatalog.defaults`, non-interactive (no `onTap`) — informational only.
- **Recent Activity** section — data-driven via `Selector<HistoryController, ...>` on the **top 3** history entries plus a running total count (`:20-38`):
  - Empty state: `_EmptyStateCard` "No recent scenarios yet" / "Run a quote or qualification flow and it will start surfacing here." (`:98-104`).
  - Populated: up to 3 `Card`/`ListTile` rows, each with a "→" `IconButton` that pops with `_featureIdForEntry(entry)` — maps `CalculationEntryType.qualification` → `qualification` id, everything else → `calculator` id (`:162-167`). **Note**: this mapping is coarse — any non-qualification history entry (amortization, comparison, etc., if such types exist) routes back to the plain Calculator tab, not the tool that actually produced it. Worth confirming `CalculationEntryType` only has these two values today, or flag as a routing gap.
  - `shouldRebuild` only compares `totalCount`, `recent.length`, and each visible entry's `id` (`:25-32`) — an update that changes an entry's title/summary without changing its id (if that's possible) would not trigger a rebuild; low risk but worth a spot check.
- **Tool Catalog** section: full `FeatureCatalog.workspaceFeatures` (primary + Loan Programs + Rent vs Buy) grouped by `category` via `_groupByCategory` (preserves first-seen insertion order per category, not alphabetical) (`:169-178`), each rendered full-width with "Open".

### Acceptance criteria — Workspace Dashboard
1. Given no calculation history exists, When the dashboard opens, Then "Recent Activity" shows the empty-state card and the hero's "Recent items" chip reads 0.
2. Given more than 3 history entries exist, When the dashboard opens, Then only the 3 most recent are listed but the hero chip shows the full count.
3. Given the user taps "Open" on a pinned tool card, When the dashboard closes, Then `MainNavigator` switches to that tool's tab (bottom nav or rail) without pushing a new route.
4. Given the user taps "Open" on Loan Programs or Rent vs Buy (non-primary), When the dashboard closes, Then a new screen is pushed via `AppRouter.openFeatureById` (these aren't tabs).
5. Given a qualification-type history entry, When its arrow is tapped, Then the app returns to the Qualification tab; given any other entry type, Then it returns to the Calculator tab.
6. Given the window is resized narrower than the card's 240px compact width while pinned cards are in a `Wrap`, Then cards reflow to fewer per row without overflow.

### Risk-based edge cases — Workspace Dashboard
1. History with exactly 3, 4, and 0 entries (boundary around the `take(3)` slice).
2. Rapid double-tap on a card's "Open" button — since it's a plain `pop(id)`, verify no double-pop/duplicate-navigation exception if tapped twice before the route finishes closing.
3. `AppRouter.openWorkspaceDashboard()`'s `_push` returns `Future<void>.value()` (null) if `navigatorKey.currentState` is null (`app_router.dart:107-113`) — verify no crash if dashboard is invoked before the navigator is attached (very early app lifecycle).

---

## 4. Navigation & Adaptive Layout

**Files**: `lib/main.dart` (`MainNavigator`), `lib/src/core/navigation/app_router.dart`, `lib/src/core/theme/theme_provider.dart`, `lib/src/theme/app_theme.dart`, `lib/src/core/navigation/feature_catalog.dart`

### Adaptive breakpoints (`main.dart:171-176`)
Computed once per `LayoutBuilder` rebuild from `constraints.maxWidth`:
| Flag | Condition | Effect |
|---|---|---|
| `useRail` | `maxWidth >= 900` | Show `NavigationRail` instead of bottom `NavigationBar` |
| `extendRail` | `maxWidth >= 1200` | Rail becomes extended (labels always visible vs. `selected`-only) |
| `compactAppBar` | `maxWidth < 700` | App-bar "More" menu icon switches from gear (`settings_outlined`) to `more_vert`, and is otherwise the only visual compacting done |
| `bootstrapLayout` | `maxWidth < 50` | Suppresses **all** app-bar actions (`appBarActions = []`) |

Behavior detail:
- `useRail` false (< 900): `NavigationRail` + `VerticalDivider` are omitted; `NavigationBar` bottom bar is shown instead (`main.dart:203-219,237-249`).
- `useRail` true (≥ 900) but `< 1200`: rail shown collapsed (`extended: false`), `labelType: NavigationRailLabelType.selected` (label only on the active item).
- `≥ 1200`: rail `extended: true`, `labelType: NavigationRailLabelType.none` (labels always shown next to icons, per Flutter's extended-rail convention).
- `bootstrapLayout` (`maxWidth < 50`) is **effectively unreachable in normal use** — `MainNavigator` is only built as `AppBootstrapGate`'s `child`, and `AppBootstrapGate` doesn't render `child` until the `FutureBuilder` reaches `ConnectionState.done` (`app_bootstrap_gate.dart:80-90`), by which point the widget tree already has real window constraints (rarely < 50 logical px). It DOES become reachable in the **test environment** short-circuit, where `_isTestEnvironment` returns `widget.child` immediately without awaiting bootstrap (`app_bootstrap_gate.dart:71-73`) — so widget tests using a default (often 0-sized or unconstrained) test surface could hit this path. Flag as an intentional-but-obscure guard, primarily a test-harness safety net rather than a real responsive breakpoint.

### App bar (`main.dart:194-199`, `_AppBarActions` at `:286-401`)
- Title: "MLO-Calc", `centerTitle: false`.
- Actions row (hidden entirely when `bootstrapLayout`):
  1. **Share** (`Icons.ios_share`) — enabled only when the active tab is Calculator (`isCalculatorTab`); opens `ShareQuoteDialog.show(...)` with `QuoteShareData.fromCalculatorProvider(provider)` (`main.dart:301-308,322-326`). Disabled (greyed, `onPressed: null`) on all other tabs.
  2. **Voice/Text (mic)** (`Icons.mic_outlined`) — always enabled, opens `NlpDialog` as a `showDialog` with a **fresh** `stt.SpeechToText()` instance created inline every tap (`main.dart:310-317,327-330`) — no reuse/disposal tracking of prior instances across dialog opens; potential resource-churn risk if user reopens repeatedly, though each is scoped to the dialog's lifetime.
  3. **More** (`PopupMenuButton<String>`) — icon toggles gear vs. kebab per `compactAppBar`; 5 items: Settings, How to Use (`InfoDialog.show`), Workspace Dashboard, Loan Programs, Rent vs Buy (`main.dart:332-396`).
- `_trackScreenView` fires `AnalyticsService.trackScreenView` on every tab switch (both rail and bottom-nav paths, `main.dart:161-167,210-215,241-246`).

### `AppRouter` (`app_router.dart`)
- Pure `ChangeNotifier` holding `navigatorKey` + `_primaryFeatureId` (drives tab-highlight state independent of `MainNavigator`'s own `_selectedIndex`, though in practice `MainNavigator` manages its own index locally and doesn't consume `AppRouter.primaryFeatureId` for the bottom-nav/rail — worth confirming these two states can't drift, e.g. after `openFeatureById` selects a primary feature via `selectPrimaryFeature` but `MainNavigator._selectedIndex` is only updated by its own local `setState` calls in `_openFeatureById`).
- `_push<T>()` returns `Future<T?>.value()` silently (no error) if `navigatorKey.currentState` is null — no crash but also no navigation; a caller awaiting a meaningful `T` gets `null` indistinguishable from "user cancelled."
- Report preview route (`openReportPreview`) generates a PDF via `ReportService.generateLoanReport` then opens a **non-dismissible-by-default `PdfPreview`** widget (`_PdfPreviewRoute`, `:116-133`) with `allowPrinting`/`allowSharing` true, `canDebug`/`canChangePageFormat` false.

### Theme (`theme_provider.dart`, `app_theme.dart`)
- See §1.4 above — `ThemeProvider` is entirely in-memory, no persistence, defaults to `ThemeMode.light`, only supports light/dark (no system mode).
- `AppTheme.lightTheme`/`darkTheme` branch on `accent == null` (hard-coded palette) vs non-null (`ColorScheme.fromSeed`) — since `MloProfileProvider.accentColorValue` always defaults to `0xFF0891B2` (never null) and `main.dart:124` always passes `Color(mloProfile.accentColorValue)`, **the app always takes the `ColorScheme.fromSeed` branch in practice**; the `accent == null` / hard-coded-palette branch in `app_theme.dart:34-45,152-163` is effectively dead code reachable only if `AppTheme.lightTheme()`/`darkTheme()` were called directly with no argument (e.g., from a test) — confirm no other call site does that.

### Acceptance criteria — Navigation
1. Given window width ≥ 1200px, When the app renders, Then the extended `NavigationRail` shows icon+label for every destination and no bottom `NavigationBar` exists.
2. Given window width between 900–1199px, When the app renders, Then the rail shows only the selected item's label; other items show icon only.
3. Given window width < 900px, When the app renders, Then a bottom `NavigationBar` is shown instead of the rail.
4. Given window width < 700px, When the app renders, Then the app-bar "More" icon is a kebab (`more_vert`) instead of a gear.
5. Given the active tab is not Calculator, When the app bar renders, Then the Share icon is visibly disabled (not just no-op).
6. Given the user resizes the window live across the 700/900/1200 breakpoints, Then the layout transitions without exceptions or dropped frames (drag-resize test on desktop/web).
7. Given the user opens Voice/Text input twice in a row, Then each dialog gets a working microphone session with no leftover state from the previous instance.

### Risk-based edge cases — Navigation
1. Resize window across all three breakpoints in one continuous drag (700, 900, 1200) — verify rail/bottom-nav swap doesn't lose `_selectedIndex` or duplicate tabs.
2. Extremely narrow width (< 50px) is only reachable via the test-environment bypass — confirm no production code path can hit `bootstrapLayout=true` unexpectedly (e.g. embedded/split-screen Android at minimum width).
3. Rapid tab switching (bottom nav or rail) — confirm `AnimatedSwitcher` fade (250ms) doesn't stack/overlap on fast repeated taps, and `AnalyticsService.trackScreenView` isn't double-counted.
4. Share icon tapped while disabled (should be impossible via UI, but confirm `onPressed: null` truly blocks it, not just visually).

---

## 5. Bootstrap

**Files**: `lib/src/core/bootstrap/app_bootstrap_gate.dart`, `lib/src/core/di/service_locator.dart`

### Startup sequence
1. `main()` (`main.dart:40-46`): `WidgetsFlutterBinding.ensureInitialized()` → `await configureDependencies()` (GetIt registration, synchronous-ish, throws only if double-registered — guarded by `if (serviceLocator.isRegistered<LoanMath>()) return;`, `service_locator.dart:97-100`) → `runApp(MultiProvider(...))`.
2. `MultiProvider` (`main.dart:48-115`) wires ~15 providers, most via `serviceLocator<T>()` lookups — if any registration in `configureDependencies()` were missing/misordered, this would throw synchronously at app start (`GetIt` throws on unregistered type), producing a red-screen crash before any UI renders. Registration order in `service_locator.dart:105-151` looks correctly dependency-ordered (`LoanMath` → `PreferenceStore`/`SecureStore` → services depending on those → `AppRouter` last, depending on `ArmCalculatorService`/`ArmPresetStorage`).
3. `AppBootstrapGate` wraps `MainNavigator` (`main.dart:131`). On first `didChangeDependencies`, kicks off `_bootstrap()` exactly once (`_bootstrapFuture ??= ...`, `app_bootstrap_gate.dart:34`).
4. `_bootstrap()` (`:37-67`) sequence:
   - `await connectivity.initialize()` then `await analytics.initialize()` — **sequential**, not parallel.
   - Then **8 provider loads in parallel** via `Future.wait([...])`: `calculator.initialize()`, `layout.load()`, `units.load()`, `ratios.load()`, `programs.load()`, `templates.load()`, `nlp.load()`, `mloProfile.load()`.
   - Finally applies calculator defaults from `mloProfile` (interest rate + term only — see §1.3).
   - **`Future.wait` with no error handling** — if ANY of the 8 loads throws (uncaught, not just logged), the whole bootstrap future rejects, `FutureBuilder` never reaches `ConnectionState.done` with data, and per Flutter's `FutureBuilder` semantics with no explicit error branch in the `builder` (`:82-88` only checks `connectionState`, doesn't check `snapshot.hasError`), **the UI would render `widget.child` anyway once `connectionState == done`, even though the future completed with an error** — meaning a failed load could silently proceed to `MainNavigator` with partially-initialized providers rather than showing an error screen. Each provider's own `load()` methods do catch and swallow their internal errors (per the various providers reviewed above), which is likely why this hasn't surfaced as a crash — but it means bootstrap has no top-level error UI at all; a genuinely unrecoverable failure (e.g., `calculator.initialize()` throwing synchronously, uncaught) would leave the spinner forever or crash, not show a retry.
5. Loading state: full-screen `Scaffold` with centered `CircularProgressIndicator`, no timeout, no cancel (`:83-86`).
6. Test bypass: `_isTestEnvironment` sniffs `WidgetsBinding.instance.runtimeType.toString().contains('Test')` (`:27-29`) — a string-based heuristic on the binding's runtime type name, not a documented Flutter API; if a future Flutter version renames test bindings to not contain "Test", widget tests would start awaiting real bootstrap (which depends on plugins like `shared_preferences`/`flutter_secure_storage` that may not be mocked) — fragile but currently functional.

### What could fail at startup
- `SecureStore` is **unconditionally** `FlutterSecureStoreBackend()` (`service_locator.dart:109`) — no platform branching to `InMemorySecureStore` (which exists in the codebase, `secure_store.dart:48-70`, but is never wired in production). On **web**, `flutter_secure_storage` backs onto browser storage (IndexedDB/localStorage + WebCrypto wrapping) which can fail or behave unexpectedly in private/incognito browsing, when third-party storage is blocked, or in older browsers lacking WebCrypto — since all read/write calls in `MloProfileProvider`/`NlpSettingsProvider` are wrapped in try/catch that silently null out, a web user could have **all "secure" fields (name/NMLS/phone/email/API key) silently fail to persist** with zero error surfaced, just always reverting to blank — this is the single highest-value web-specific regression to test explicitly.
- `SharedPreferences.getInstance()` (via `PreferenceStore.load()`) similarly could fail on web if storage is disabled/blocked; same silent-catch pattern throughout.
- `ConnectivityService.initialize()` / `AnalyticsService.initialize()` run before the parallel batch and are **not** wrapped in a try/catch inside `_bootstrap()` itself — if either throws synchronously (not just returns a failed Future that's awaited and unhandled), the whole `_bootstrapFuture` becomes an error future with the failure-mode described above.
- `NLPCalculatorService`/voice dialog: `speech_to_text` package added without any `kIsWeb`-specific guard in this codebase (only 3 unrelated files reference `kIsWeb`, none in `nlp` or `secure_store`); Web Speech API support in `speech_to_text` is browser-dependent (works in Chromium-based browsers, historically unreliable/absent in Safari/Firefox) and requires HTTPS + explicit mic permission — first-use permission prompts and unsupported-browser failure paths are untested territory per this review.

### Acceptance criteria — Bootstrap
1. Given a cold app start with no prior data, When bootstrap runs, Then the spinner shows briefly and then `MainNavigator` renders with all providers reporting first-run/empty defaults.
2. Given `SecureStore` throws on read (simulate via platform channel failure or web without storage permissions), When bootstrap completes, Then the app still renders (does not hang or crash) with MLO profile fields blank and API key "Not set" — no visible error banner (per current silent-catch design, worth confirming testers agree this is acceptable UX).
3. Given the 8 parallel loads all succeed, When bootstrap finishes, Then calculator interest rate/term prefill from MLO defaults if the calculator had no prior session.
4. Given the app is run under `flutter test`, When `AppBootstrapGate` builds, Then it skips the spinner/future entirely and renders children immediately (verify this doesn't mask real bootstrap bugs in CI).
5. Given `configureDependencies()` is called twice (e.g., hot restart edge case), Then it no-ops on the second call without re-registering or throwing (guarded by `isRegistered<LoanMath>()` check).

### Risk-based edge cases — Bootstrap
1. **Secure storage unavailable on web** (private browsing / IndexedDB blocked) — highest priority: confirm whether fields silently blank out (current expectation) vs. crash.
2. Bootstrap load failure surfaced only as an endless spinner if a provider's `load()` rejects without internal catch (audit each of the 8 for any uncaught path — most reviewed here do catch, but this is worth a fuzz/error-injection pass).
3. First-run (no `SharedPreferences`/`SecureStore` entries at all) — every provider must fall back to documented defaults without throwing (Name/NMLS empty, disclaimer default text, accent teal, theme light, units annual/percent/years, ratios "first built-in", templates "defaults only").
4. Killing/backgrounding the app mid-bootstrap (before `Future.wait` resolves) — confirm no partial-state crash on resume.
5. `_isTestEnvironment` heuristic breaking on a future Flutter SDK bump — not directly QA-testable via black-box, but flag for the dev team as a fragile string-based platform check worth a regression watch after Flutter upgrades.

---

## Summary of persistence key inventory (for cross-cutting QA / data-migration testing)

| Key | Store | Field |
|---|---|---|
| `mlo_name`, `mlo_nmls`, `mlo_phone`, `mlo_email` | SecureStore | MLO PII |
| `mlo_company` | PreferenceStore | Company name |
| `mlo_disclaimer` | PreferenceStore | Disclaimer text |
| `mlo_default_rate`, `mlo_default_term`, `mlo_default_down_pct`, `mlo_default_tax_rate`, `mlo_default_ins_rate` | PreferenceStore | Calculator defaults (only rate+term are consumed) |
| `mlo_accent_color` | PreferenceStore | Accent color (int as string) |
| `geminiApiKey` | SecureStore (migrated from PreferenceStore legacy) | NLP API key |
| `unit_tax_insurance`, `unit_down_payment`, `unit_term` | PreferenceStore | Unit conversion toggles |
| `qualifying_ratios_custom`, `qualifying_ratio_selected` | PreferenceStore | Qualifying ratios (out of scope screen, referenced for completeness) |
| `shareCustomTemplates`, `shareSelectedTemplate_<channel>` | PreferenceStore | Share templates (out of scope screen, referenced for completeness) |
| *(none)* | **not persisted** | Theme mode (dark/light) — resets to light every launch |
| `layout_preference` (see `layout_preference_provider.dart`) | PreferenceStore | Calculator layout (Classic/Modern) — persists normally, unlike theme mode |
