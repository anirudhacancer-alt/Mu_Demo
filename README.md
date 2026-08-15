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
> the app. This is the same approach production tools like it use for early
> investor/leadership demos.

---

## 1. What's in this package

```
sitevoice_v2e/
├── lib/                      → all Dart source code (screens, models, state)
├── pubspec.yaml              → dependencies (image_picker, provider, fl_chart, intl)
├── .github/workflows/
│   └── build-apk.yml         → builds the release APK in the cloud automatically
├── analysis_options.yaml
└── .gitignore
```

There is **no `android/` folder** in this package on purpose — the GitHub
Actions workflow generates it automatically at build time using the exact
Flutter version running on the cloud runner, which avoids any local
Flutter/Android-SDK version mismatches. You never need Android Studio or a
local Flutter install for this.

## 2. Get the APK — step by step (~10–15 minutes, no local installs)

1. **Create a new GitHub repo** (e.g. `v2e-sitevoice-demo`), public or private.
2. **Upload this package's contents** to the repo root — easiest way:
   - On the repo page, select **Add file → Upload files**, then drag in
     everything from the extracted folder (`lib/`, `pubspec.yaml`,
     `.github/`, `.gitignore`, `analysis_options.yaml`, `README.md`).
   - Make sure the `.github/workflows/build-apk.yml` file actually lands at
     `.github/workflows/build-apk.yml` in the repo (GitHub sometimes needs
     the folder uploaded as a drag-drop of the whole `.github` folder).
3. **Commit** the upload directly to the `main` branch.
4. Go to the **Actions** tab of your repo. You should see a run named
   **"Build V2E Demo APK"** start automatically (triggered by the push).
   If it doesn't start, open the workflow and click **Run workflow**.
5. Wait for the run to go green (typically 4–7 minutes).
6. Open the completed run → scroll to **Artifacts** → download
   **`v2e-sitevoice-apk`**. Unzip it to get `app-release.apk`.
7. **Transfer the APK to your Android phone/tablet** (email it to yourself,
   use a USB cable, or upload to Google Drive) and tap it to install.
   - You'll need to allow "Install unknown apps" for the app you use to open
     the file (Files app, Chrome, Drive, etc.) — a one-time Android prompt.
8. Open the app — you're ready to demo.

### If the Actions run fails
- Click into the failed step's logs — the most common cause is the
  `.github/workflows/build-apk.yml` file not being in the exact
  `.github/workflows/` path (GitHub requires this exact structure to detect
  workflows). Re-upload that file specifically if needed.
- Re-running the job (`Re-run all jobs` button) resolves most transient
  Gradle-download hiccups.

## 3. Suggested demo flow (5–7 minutes)

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
5. Go to **Sprint** → show the sprint goal, progress ring equivalent, at-risk
   tasks, and AI recovery recommendations.
6. Go to **Procurement & QA** → switch tabs between Material Tracker and
   Snag Management → advance a procurement item's status → close a snag.
7. **Switch role** (tap the role pill top-right) to **Project Manager** →
   land on **Control Tower** → walk through the KPI grid, AI Risk &
   Escalation cards (note the "Steel delivery delay…" alert matching the
   spec example), and open the full **Weekly Review Pack**.

## 4. Customizing before the demo (optional, all safe/low-risk)

- **App name on the phone / home screen icon**: after the first successful
  Actions build, you can rename via `flutter_launcher_icons` or by editing
  the generated `android/app/src/main/AndroidManifest.xml`'s `android:label`
  — ask me and I'll add this for you if you'd like a custom icon.
- **Add your company logo / colors**: the theme lives in
  `lib/theme/app_theme.dart` — colors, gradients and text styles are all in
  one place.
- **Add more voice demo scenarios**: edit `demoTranscripts` in
  `lib/data/mock_data.dart`.

## 5. Why this architecture

- **Pure Flutter, minimal dependencies** (`provider`, `image_picker`,
  `intl`, `fl_chart`) — all mature, widely-used packages, chosen specifically
  to minimize the risk of a CI build failure the night before your demo.
- **No backend, no API keys, no network calls** — the entire app runs on
  in-memory mock data via a single `AppState` (ChangeNotifier), so it works
  completely offline during the live presentation (airplane mode safe).
- **GitHub Actions builds the APK**, matching the cloud-first workflow you've
  used for previous projects (e.g. RideCompare India) — no local Flutter/
  Android Studio installation needed on your machine.
