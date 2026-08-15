# V2E · SiteVoice.AI — Demo Prototype (v1.1)

A voice-first construction site management app. This version adds
role-aware login, a capture-to-task reflection flow, a continuous daily
standup record, and a cleaned-up procurement UI on top of the original 6
modules.

## What's new in this version

1. **Login with real validation** — pick a role, then sign in with a
   username/password checked against a small local demo account list.
   Wrong username, wrong password, or credentials for the wrong role each
   show a specific inline error. After signing in, a confirmation banner
   identifies who you're logged in as and in which role.

   **Demo credentials** (also viewable via "Show demo credentials" on the
   login screen itself):
   | Role | Username | Password |
   |---|---|---|
   | Supervisor | `supervisor` | `site123` |
   | Site Engineer | `engineer` | `site123` |
   | Project Manager | `manager` | `site123` |

2. **Capture → Reflect → Task** — voice/photo captures no longer turn
   into a task automatically. They land in a "Captured Updates" log first.
   Tap any pending capture to open the reflection step, where you set
   **Owner, Priority (Low/Medium/High/Urgent), Due Date, and Status**
   before it becomes an actual task.

3. **Daily standup reflection layer** — "Start Standup" opens a form to log
   Planned / Completed / Blocked / Key Learnings for the day. Each
   submission is saved to a **Standup History** list (tap any past entry to
   expand it) instead of disappearing after the meeting.

4. **Procurement UI fixes** (per your screenshot):
   - Every material card's bottom row now always shows a clear action or a
     "Completed" marker — no more empty dead space (previously the
     "Delayed" card had nothing where others had a "Mark …" button).
   - The **tab selector indicator now fills the entire tab segment**
     (`TabBarIndicatorSize.tab`) instead of just wrapping the label text, so
     both tabs look and feel consistent when switching.
   - The whole tab segment (not just the text) is tappable/touchable, and
     this "full tappable area" pattern was also applied to captured-update
     cards and standup history rows — you can tap anywhere on those cards,
     not just a small link/icon.

5. **Manager dashboard restricted** — the Control Tower is only reachable
   by the **Project Manager** role; Supervisors and Site Engineers never
   see it in their navigation.

6. **Role-based navigation** — each role now gets a different set of tabs:
   - **Supervisor**: Capture, Tasks, Daily
   - **Site Engineer**: Capture, Tasks, Sprint, Procurement & QA
   - **Project Manager**: Sprint, Procurement & QA, Control Tower

   A "Demo: switch role" shortcut (tap the role pill, top-right) is still
   available so you can show all three views quickly in a single demo
   without re-logging in each time — clearly labeled as a presenter
   convenience, not a security bypass.

## Assumptions made (flag these if you want changes)

- No 4th "Management/Leadership" role was added — the Project Manager's
  Control Tower is treated as the top-level/portfolio view mentioned in
  your notes. Say the word if you want a separate Management role with its
  own even-higher-level view.
- Login credentials are a small hardcoded local list (no backend) — keeps
  the app 100% offline-safe for the demo. A real deployment would need a
  proper auth service.
- "Priority" was added as a new field distinct from "Severity" (severity =
  how bad the issue is; priority = how urgently to act) since the reflection
  step specifically asked for a priority setting.
- Site Engineers were given both Capture and Procurement & QA access (their
  original description mentioned QA/procurement/sprint, but they likely
  still submit field updates too) — easy to trim if you'd rather they not
  have Capture.

## Getting the APK (unchanged process)

There is still **no `android/` folder** in this package — GitHub Actions
generates it fresh at build time. See the workflow file at
`.github/workflows/build-apk.yml`.

### ⚠️ Upload reminder
`.github` is a hidden folder. If dragging-and-dropping into GitHub's
uploader, make sure your file browser shows hidden files first (macOS:
`Cmd+Shift+.`; Windows: View → Show → Hidden items), or simplest — use
GitHub's **"Add file → Create new file"** and type the path
`.github/workflows/build-apk.yml` directly (this auto-creates the folders).

1. Push/upload this package's contents to a GitHub repo's `main` branch.
2. Check the **Actions** tab for the "Build V2E Demo APK" run.
3. Download the `v2e-sitevoice-apk` artifact once the run is green.
4. Transfer `app-release.apk` to your Android device and install it.

## Suggested demo flow (updated, ~7–9 minutes)

1. **Login screen** — show a wrong password first (error message), then
   sign in correctly as `supervisor` / `site123`. Point out the "Logged in
   as Supervisor" confirmation banner.
2. **Capture** — pick a scenario chip, record, let it transcribe & structure,
   tap **Save Capture**. Point out it's now sitting in "Captured Updates"
   as "Needs Reflection" — not yet a task.
3. Tap that captured update card → the **Reflect & Convert to Task** sheet
   opens → set Owner/Priority/Due Date/Status → **Convert to Task** → show
   it now appears in **Tasks**.
4. **Daily** tab → **Start Standup** → fill in a couple of planned/completed
   items and a key learning → **Save Standup** → scroll down to show it now
   appears in **Standup History** alongside yesterday's entry.
5. **Switch role** (role pill, top-right) to **Project Manager** — note the
   nav bar changes to Sprint / Procurement & QA / Control Tower only (no
   Capture/Tasks/Daily — those are field-role screens).
6. **Procurement & QA** → point out every card now has a consistent action
   in the bottom-right (including the Delayed one, which previously had
   none) → tap between the two tabs and note the full-width blue indicator.
7. **Control Tower** → KPI grid, AI Risk & Escalation, Weekly Review Pack —
   note this is only visible to Project Manager, never to Supervisor.

## Why this architecture (unchanged)

- Pure Flutter, minimal dependencies (`provider`, `image_picker`, `intl`,
  `fl_chart`), no backend, no API keys — fully offline-safe for a live demo.
- GitHub Actions builds the release APK in the cloud — no local Flutter or
  Android Studio install needed.
