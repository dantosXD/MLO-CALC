# Browser Smoke

Release build first:

```powershell
flutter build web --release
```

Serve the release bundle:

```powershell
.\tool\browser_smoke\serve_release_web.ps1
```

Run the browser smoke script from another terminal:

```powershell
node tool/browser_smoke/release_smoke.cjs
```

Environment overrides:

- `SMOKE_BASE_URL` changes the release URL.
- `SMOKE_BROWSER_EXECUTABLE_PATH` overrides the default Edge executable path.
- `SMOKE_HEADLESS=false` runs the browser headed.
