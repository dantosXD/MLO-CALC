# MLO-Calc

Flutter mortgage calculator for loan officers (package `loan_ranger`, Dart ^3.9). Targets Android + web (CanvasKit).

## Commands

```bash
flutter pub get
dart format lib test                      # CI fails on unformatted code
flutter analyze
flutter test --exclude-tags=golden        # main suite
flutter test --tags=golden                # goldens in test/goldens/
dart run tool/benchmarks/amortization_benchmark.dart
flutter build web --release               # live smoke: tool/browser_smoke/README.md
```

**Merging to `main` ships:** `.github/workflows/ci.yaml` builds a release APK and publishes a GitHub release `vMAJOR.MINOR.<run_number>` on every green push to main.

## Architecture

- `lib/main.dart` — entry + adaptive nav (rail ≥900px, extended rail ≥1200, compact app bar <700).
- `lib/src/core/` — `di/service_locator.dart` (get_it), `math/`, `models/`, `validators/`, `persistence/` (`preference_store` = SharedPreferences, `secure_store` = flutter_secure_storage).
- `lib/src/features/<feature>/{application,domain,presentation}` — Provider-based state.
- `test/{unit,widget,regression,golden}` — regression tests are named after QA bug IDs (`b22_…`) tracked in `qa/bugs/`; QA plan + feature inventory in `qa/`.

## Gotchas

- Calculator input: type digits, then tap a field label (Price, L/A, DnPmt, Int, Term) to assign. Down payment <100 = percent, ≥100 = dollars.
- Calculator session + history persist in secure storage key `scenarioSession` (`persistence_service.dart`).
- Web: the PWA service worker serves the stale bundle after a rebuild — serve on a fresh port. DOM-reading browser tools can't see the CanvasKit canvas; use real Chrome screenshots.
- Root-level `feature_*`, `get_feature*`, `query_feature*`, `tmpclaude-*` files are stale agent artifacts, not current docs. `bin/` scripts are dev tooling only. `GEMINI.md` is a generic Firebase Studio prompt.
