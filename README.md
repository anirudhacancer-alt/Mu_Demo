# V2E · SiteVoice.AI — Demo Prototype

A voice-first construction site management app, built as a working Flutter
prototype covering the **6 core V2E modules**:

1. **Capture** — Voice update (simulated STT + AI structuring) + Photo Proof + Checklist
2. **Tasks & Blockers** — full task/blocker lifecycle, aging, filters
3. **Daily Execution** — role-aware home dashboard, quick actions, standup, AI summary
4. **Sprint** — goal, backlog, current sprint, at-risk tasks, AI recovery tips, retro
5. **Procurement & QA** — material tracker + snag/punch-list management
6. **Control Tower** — manager KPIs, AI risk & escalation, weekly review pack

Role-based login (Supervisor / Site Engineer / Project Manager) changes the
landing tab and dashboard content.

> **Note on the "AI":** to guarantee a 100%-reliable, offline demo on any
> device (no API keys, no internet dependency, no risk of a live mic/STT
> failure on stage), the voice → transcript → structured-task journey uses a
> small set of realistic, presenter-selectable demo scripts (see the chips in
> the Capture screen) instead of live cloud transcription. The AI risk
> alerts, standup summaries, and weekly review pack are generated from the
> live mock data using rule-based logic, so they update as you interact with
> the app.

---

## ⚠️ IMPORTANT — Read this before uploading to GitHub

This package includes a **hidden folder**: `.github/workflows/build-apk.yml`.
This is the file that tells GitHub to automatically build your APK — **if
it's missing, no Action will ever run.**

The problem: **macOS Finder and Windows Explorer hide folders that start
with a dot by default.** If you unzip this package and then drag the folder
into GitHub's "Upload files" page, your file browser may silently leave
`.github` out of the drag.

### ✅ Method A (most reliable): Create the workflow file directly on GitHub
1. Create a new repo on GitHub (e.g. `v2e-sitevoice-demo`).
2. Upload everything **except** the `.github` folder via **Add file →
   Upload files** (drag in `lib/`, `pubspec.yaml`, `.gitignore`,
   `analysis_options.yaml`, `README.md`). Commit to `main`.
3. Click **Add file → Create new file**. In the filename box, type exactly:
   `.github/workflows/build-apk.yml` (the `/` characters auto-create the
   folders). Paste in the contents from **Section 2** below, then **Commit
   directly to the `main` branch**.
4. Go to the **Actions** tab — **"Build V2E Demo APK"** should now run (or
   click **Run workflow** if it doesn't auto-start).

### Method B: Upload via drag-and-drop (only if your OS shows hidden files)
1. **macOS Finder**: press `Cmd + Shift + .` to reveal hidden folders.
   **Windows Explorer**: View → Show → Hidden items.
2. Confirm `.github` is visible inside the extracted `v2e_app` folder.
3. Drag the entire contents (not the parent folder) into GitHub's upload
   page, including `.github`, then commit and check **Actions**.

---

## 1. What's in this package

```
v2e_app/
├── lib/                      → all Dart source code (screens, models, state)
├── pubspec.yaml               → dependencies (image_picker, provider, fl_chart, intl)
├── .github/workflows/
│   └── build-apk.yml          → builds the release APK in the cloud automatically
├── analysis_options.yaml
└── .gitignore
```

There is **no `android/` folder** in this package on purpose — the GitHub
Actions workflow generates it automatically at build time using the exact
Flutter version running on the cloud runner, avoiding local Flutter/Android
SDK version mismatches. No Android Studio or local Flutter install needed.

## 2. Full contents of `build-apk.yml` (for Method A copy-paste)

```yaml
name: Build V2E Demo APK

on:
  push:
    branches: [ main ]
  workflow_dispatch: {}

jobs:
  build:
    name: Build release APK
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Flutter doctor
        run: flutter doctor -v

      - name: Generate Android platform folder
        run: flutter create . --platforms=android --org com.v2e.demo --project-name sitevoice_v2e

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze (non-blocking, for visibility in logs)
        run: flutter analyze || true

      - name: Build release APK
        run: flutter build apk --release

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: v2e-sitevoice-apk
          path: build/app/outputs/flutter-apk/app-release.apk
          if-no-files-found: error
```

## 3. After the build succeeds

1. Go to the **Actions** tab → open the completed (green) run.
2. Scroll to **Artifacts** → download **`v2e-sitevoice-apk`**.
3. Unzip it to get `app-release.apk`.
4. Transfer it to your Android phone/tablet (email, USB, or Drive) and tap
   to install — allow "Install unknown apps" for whichever app opens the
   file (a one-time Android prompt).
5. Open the app — you're ready to demo.

### If the Actions run fails again
- Open the failed step's log and read the exact error message near the
  bottom — Dart compile errors point to a specific file and line number.
- Check that `build-apk.yml` exists at exactly `.github/workflows/build-apk.yml`.
- Re-running (`Re-run all jobs`) resolves most transient Gradle-download
  hiccups.

## 4. Suggested demo flow (5–7 minutes)

1. **Login** as **Supervisor** → land on **Daily Execution** → point out the
   today snapshot (planned vs done, open blockers, QA issues, material
   delays) and the 4 quick actions.
2. Go to **Capture** → pick the **"Material Delay"** scenario chip → tap the
   mic → let it "listen" → watch the transcript type itself out → AI
   structures it into category/trade/tower/floor/vendor/severity/owner →
   tap **Create Task**. Point out the task now appears in **Tasks**.
3. Optionally tap **Take Photo / From Gallery** and tick a couple of
   checklist items to show Photo Proof & Checklist.
4. Go to **Tasks & Blockers** → filter by **Blocked** → open a task → change
   its status to show the lifecycle.
5. Go to **Sprint** → show the sprint goal, progress, at-risk tasks, and AI
   recovery recommendations.
6. Go to **Procurement & QA** → switch tabs between Material Tracker and
   Snag Management → advance a procurement item's status → close a snag.
7. **Switch role** (tap the role pill top-right) to **Project Manager** →
   land on **Control Tower** → walk through the KPI grid, AI Risk &
   Escalation cards, and open the full **Weekly Review Pack**.

## 5. Customizing before the demo (optional)

- **Colors/branding**: all in `lib/theme/app_theme.dart`.
- **More voice demo scenarios**: edit `demoTranscripts` in
  `lib/data/mock_data.dart`.
- **App icon / custom name**: ask me and I'll add `flutter_launcher_icons`
  config for you.

## 6. Why this architecture

- **Pure Flutter, minimal dependencies** (`provider`, `image_picker`,
  `intl`, `fl_chart`) — mature, widely-used packages chosen to minimize the
  risk of a CI build failure the night before your demo.
- **No backend, no API keys, no network calls** — runs entirely on
  in-memory mock data via a single `AppState` (ChangeNotifier), so it works
  completely offline during the live presentation (airplane mode safe).
- **GitHub Actions builds the APK** — no local Flutter/Android Studio
  installation needed on your machine.
