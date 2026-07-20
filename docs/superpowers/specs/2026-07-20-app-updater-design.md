# App Updater Design

**Date:** 2026-07-20
**Status:** Approved

## Overview

An in-app updater for MLO-Calc (Flutter) that checks GitHub Releases for new builds, notifies the user, and guides them through installation. Targets Android (APK download + OS installer handoff) and Web (redirect to release page). No external backend required beyond the public GitHub Releases API.

---

## Architecture

A single `UpdateService` (registered in the existing `get_it` DI graph) owns all update logic. It is triggered in two ways:

1. **On startup** — called from `main.dart` after the DI graph is built
2. **Manual** — invoked by a "Check for Updates" button in the Settings screen

The service is platform-aware, branching on `kIsWeb` to select the correct install strategy.

A `UpdateNotifier` (ChangeNotifier, provided via the existing Provider tree) bridges the service to the UI. Two UI components consume it: `UpdateDialog` (startup modal) and `UpdateBanner` (dismissible scaffold banner shown after the dialog is dismissed).

---

## Components

### New Files

| File | Responsibility |
|---|---|
| `lib/services/update_service.dart` | GitHub API fetch, version comparison, APK download, OS handoff |
| `lib/providers/update_notifier.dart` | `ChangeNotifier` holding `UpdateState` and release metadata |
| `lib/widgets/update_dialog.dart` | Modal shown on startup when update is available |
| `lib/widgets/update_banner.dart` | Dismissible `MaterialBanner` shown after dialog is dismissed |
| `lib/version.dart` | Generated constant file — current app version string baked in at build time |

### Modified Files

| File | Change |
|---|---|
| `pubspec.yaml` | Add `http` and `open_file` dependencies |
| `android/app/src/main/AndroidManifest.xml` | Add `REQUEST_INSTALL_PACKAGES` permission |
| `lib/main.dart` | Call `UpdateService.checkForUpdate()` after DI setup |
| Settings screen | Add "Check for Updates" button wired to `UpdateService.checkForUpdate()` |

### New Packages

- **`http`** — GitHub API calls and APK download
- **`open_file`** — hands downloaded APK to the Android OS installer

---

## Data Flow

### Startup Check

```
main.dart
  └─ UpdateService.checkForUpdate()
       └─ GET https://api.github.com/repos/{owner}/{repo}/releases/latest
            └─ parse tag_name (e.g. "v1.2.0") → strip "v" → compare to version.dart constant
                 ├─ newer → UpdateNotifier: updateAvailable
                 │    └─ root Scaffold shows UpdateDialog
                 │         ├─ "Update Now" tapped
                 │         │    ├─ Android: download APK to temp dir (notifier: downloading → shows progress)
                 │         │    │           → open_file handoff to OS installer
                 │         │    └─ Web: url_launcher opens GitHub release page
                 │         └─ "Later" tapped → notifier: dialogDismissed = true
                 │                           → Scaffold shows UpdateBanner instead
                 └─ same/older → UpdateNotifier: idle (no UI shown)
```

### Manual Check (Settings)

```
Settings screen → "Check for Updates" button
  └─ UpdateService.checkForUpdate()
       ├─ update available → show UpdateDialog
       └─ up to date → show Snackbar: "You're on the latest version"
```

---

## UpdateState

```dart
enum UpdateState { idle, checking, updateAvailable, downloading, error }
```

`UpdateNotifier` holds:
- `UpdateState state`
- `String? latestVersion`
- `String? releaseNotes`
- `String? apkDownloadUrl`
- `double downloadProgress` (0.0–1.0)
- `bool dialogDismissed`

---

## Error Handling

| Failure | Behavior |
|---|---|
| Network failure / GitHub API error | Silently log; notifier stays `idle`; no dialog, no crash |
| APK download failure | Banner shows "Download failed — tap to retry"; notifier resets to `updateAvailable` |
| Malformed version string | Silently log; treat as no update available |

Update checks must never block app launch or throw uncaught exceptions.

---

## Platform Differences

| | Android | Web |
|---|---|---|
| Install method | Download APK → `open_file` | `url_launcher` → GitHub release page |
| Progress indicator | Linear progress bar during download | N/A |
| Permission required | `REQUEST_INSTALL_PACKAGES` | None |
| Silent install | No (OS installer dialog shown) | No |

---

## Testing

### `UpdateService` Unit Tests
- Correct version comparison: newer / equal / older
- Correct APK asset URL selected from release assets list
- Network errors are swallowed (no exception propagates)

### `UpdateNotifier` Unit Tests
- State transitions: `idle → checking → updateAvailable → downloading`
- `dialogDismissed` flag correctly switches UI surface from dialog to banner

### Widget Tests
- `UpdateDialog` renders version string and release notes correctly
- "Later" dismisses dialog and surfaces `UpdateBanner`
- "Update Now" calls `UpdateService` install method
- `UpdateBanner` shows retry action on download failure

---

## Version Constant Generation

`lib/version.dart` is generated at build time using a pre-build script that reads the `version:` field from `pubspec.yaml` and writes:

```dart
const String kAppVersion = '1.0.0';
```

This constant is what `UpdateService` compares against the GitHub release tag.
