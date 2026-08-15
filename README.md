# V2E · SiteVoice.AI — Demo Prototype (v1.2)

A voice-first construction site management app. This version adds real
camera photo/video capture, real microphone recording, a "closed tasks
visible on the dashboard" fix, and an optional Firebase backend on top of
everything built so far.

## What's new in this version

### 1. Photo / Video Report → Task (Capture tab)
A new card lets you **Take Photo** and/or **Record Video** with the real
device camera, type a required **"Describe the issue"** text field (plus
optional Tower/Floor and a Severity selector), then **Save Capture**. Like
voice captures, it lands in "Captured Updates" — tap it to reflect (set
Owner/Priority/Due Date/Status) and it becomes a real task that shows up in
**Tasks** and, if it's a blocker or critical, in the **Control Tower**
dashboard automatically (all screens read from the same shared task list).

### 2. Closed/Resolved tasks now visible on the dashboard
Control Tower has a new **"All Tasks"** section listing every task —
Open, In Progress, Blocked, **and Resolved** — with filter chips, so
completed work stays visible on the manager dashboard instead of only
appearing in the Tasks tab's filters.

### 3. Real microphone recording → Task (Capture tab)
A new **"Record Real Voice"** card actually records your microphone to an
audio file (using the device's mic, not a simulation). Since genuine
offline speech-to-text isn't feasible to add reliably in this timeframe,
after you stop recording you type a short caption of what you said — the
audio file travels with the capture (and uploads to Firebase Storage if
configured) so the original recording is preserved alongside the caption.
This sits **alongside**, not instead of, the original reliable demo-scenario
voice card — use whichever fits the moment on stage.

### 4. Firebase backend (optional, off by default)
Firebase is wired in to store credentials (mirrored), captured updates,
tasks, and uploaded photo/video/audio files — **but it only activates once
you provide your own project's config values** (see setup below). Until
then, the app runs exactly as it did before: 100% local, offline-safe,
zero risk to your demo.

- Every capture/task shows a small cloud badge (Synced / Syncing… / Sync
  failed) once Firebase is configured and a sync has been attempted.
- Task status changes (including marking something **Resolved/closed**)
  are pushed to Firestore too, so the cloud record stays current.
- Demo login credentials are mirrored into a Firestore `demo_accounts`
  collection once Firebase connects — but **login itself still validates
  locally/instantly**, never depending on network access. This keeps the
  login screen 100% reliable during a live demo even if Firebase or WiFi
  is having a bad day.

---

## Setting up Firebase (optional, ~5 minutes, no CLI or local installs)

Firebase is **not required** for the app to work — skip this section
entirely if you just want the local-only demo. If you want real cloud
storage of photos/videos/audio and task/credential records:

1. Go to **https://console.firebase.google.com** → **Add project** → give
   it a name (Google Analytics can be left off). Click **Create**.
2. In the new project, click the **Android icon** ("Add app").
3. For the Android package name, enter **exactly**:
   ```
   com.v2e.demo.sitevoice_v2e
   ```
   (this must match the CI workflow's `--org com.v2e.demo --project-name sitevoice_v2e`)
4. App nickname is optional. Click **Register app**.
5. You do **not** need to download `google-services.json` — click through
   past that step (our setup uses pure-Dart initialization instead).
6. Go to **Project settings** (gear icon, top-left) → **General** tab →
   scroll to "Your apps" → click your Android app. You'll see 5 config
   values: `apiKey`, `appId`, `messagingSenderId`, `projectId`,
   `storageBucket`.
7. Open `lib/firebase_options.dart` in this package and paste those 5
   values into the matching fields (replacing the `'YOUR_...'` placeholders).
8. Back in the Firebase console, enable the two services used:
   - **Build → Firestore Database → Create database → Start in test mode**
   - **Build → Storage → Get started → Start in test mode**

   ⚠️ Test mode rules are intentionally open (no auth required) and expire
   after 30 days — perfect for a demo, but flag this before using in
   production; you'd want proper security rules + Firebase Auth at that
   point.
9. Commit your updated `firebase_options.dart`, push to `main`, and let the
   GitHub Action rebuild the APK. Once installed, the Capture screen will
   show "Firebase connected — captures sync automatically" and cloud badges
   will start appearing on captures/tasks.

If you skip all of this, the app detects the placeholder values, silently
skips Firebase initialization, and runs in local-only mode — nothing
breaks.

---

## Getting the APK (same process as before)

No `android/` folder is shipped — GitHub Actions generates it fresh at
build time (see `.github/workflows/build-apk.yml`, which now also patches
`minSdkVersion` to 23, required by the real audio-recording package).

1. Push/upload this package's contents to your GitHub repo's `main` branch.
   (`.github` is a hidden folder — if drag-and-drop misses it, use GitHub's
   **"Add file → Create new file"** and type the path
   `.github/workflows/build-apk.yml` directly.)
2. Check the **Actions** tab for the "Build V2E Demo APK" run.
3. Download the `v2e-sitevoice-apk` artifact once green.
4. Install `app-release.apk` on your Android device (allow "install unknown
   apps" for whichever app opens the file — one-time prompt).

On first launch, the app will ask for **Camera** and **Microphone**
permissions the first time you use those specific capture cards — this is
standard Android runtime permission handling, not something you need to
configure.

## Updated demo flow (~9–11 minutes)

1. **Login** as `supervisor` / `site123` → confirmation banner shows your role.
2. **Capture** → try all three cards:
   - Demo voice scenario (reliable, presenter-controlled) → Save Capture.
   - **Record Real Voice** → speak, stop, type a caption → Save Capture.
   - **Photo / Video Report** → take a photo (or record a short video),
     describe the issue, pick a severity → Save Capture.
3. Tap any "Needs Reflection" card → set Owner/Priority/Due Date/Status →
   **Convert to Task** → confirm it now appears in **Tasks**.
4. Open that task's detail sheet → change its status to **Resolved**.
5. **Switch role** to **Project Manager** → **Control Tower** → scroll to
   **All Tasks** → filter by **Resolved** → point out the task you just
   closed is right there on the dashboard, not hidden away.
6. If Firebase is configured: point out the cloud sync badges on captures/
   tasks, and mention photos/videos/audio are now durably stored in
   Firebase Storage, with metadata in Firestore — survivable even if the
   phone is lost or the app is reinstalled.
7. **Procurement & QA** → note the full-width tab indicator and consistent
   per-card actions (carried over from the previous round of fixes).

## Notes on what's simulated vs. real

- **Photo capture**: 100% real — actual device camera via `image_picker`.
- **Video capture**: 100% real — actual device camera recording via
  `image_picker` (`pickVideo`, max 60s).
- **Real voice recording**: 100% real audio file recorded from the
  microphone via the `record` package. What's **not** included is
  automatic speech-to-text on that recording — you type a caption instead.
  (True on-device STT could be added later via the `speech_to_text`
  package if wanted — flagged here as a possible follow-up, not implemented
  now, to avoid the reliability risk of running two microphone-access
  packages simultaneously.)
- **Demo voice scenarios**: intentionally simulated (presenter-selected
  scripts), kept exactly as before, for a guaranteed-reliable stage demo.
- **Firebase sync**: 100% real when configured — uploads actual files to
  Storage and writes real Firestore documents. Entirely optional and fails
  silently/gracefully if not set up.

## Why this architecture

- Firebase init and every Firebase call are wrapped so failures **never**
  crash or block the UI — the local `AppState` remains the single source
  of truth for what's rendered on screen at all times.
- `record` and `image_picker` both handle their own runtime permission
  prompts internally — no extra permission-handling package was needed.
- GitHub Actions still builds the release APK — no local Flutter/Android
  Studio install needed on your machine.
