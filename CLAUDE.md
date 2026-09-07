# Sense&Safe — project context

This file is read automatically by Claude Code at the start of each session.
It captures architecture, conventions, and current build status — keep it
updated as work progresses so future sessions don't have to re-derive state.

> 📌 **For the full product vision** (hardware BOM, 6-layer AI architecture,
> target users, competitors) see **`report/PROJECT_BRIEF.md`** — a
> quick-reference digest of the official report (`report/SenseSafe-Report.pdf`).
> Most of THIS file covers the **Flutter app** in `app/`: what is actually
> built, versus the full vision described there.

## Repo layout (restructured 2026-09-07)

This repository is the whole project, not just the app. One root, six folders:

```
Sense&Safe/            ← git root = github.com/witthayut/Sense-Safe
  app/                  Flutter app (phone)      — was the old haptic_drive/
  firmware/             Arduino (ESP32-C3 wristbands)
  report/               the report submitted to the advisor + PROJECT_BRIEF
  research/             evidence from real users (interviews, findings)
  planning/             tech plan, QA checklist, reviews/
  media/                images
```

Before this, the outer folder was NOT a repo and only the app was versioned,
so the report and research had no backup at all. If you ever see a path
containing `haptic_drive/`, it is stale — that folder no longer exists.

## What this project is

A Flutter app that delivers turn-by-turn driving navigation as **wrist
vibration** instead of (or alongside) on-screen text and voice. Two BLE
wristbands — left + right — buzz the correct wrist for each turn. It's designed
for people with learning differences (dyslexia, ADHD, dyscalculia, dyspraxia);
a 6-question onboarding assessment builds a personal "vibration profile" that
tunes buzz intensity, lead time, and rhythm.

The app you're working in is a **prototype/scaffold** of a much larger vision
(dashcam object detection, stress-adaptive haptics, voice control — see
`report/PROJECT_BRIEF.md`); only the pieces below are actually built so far.

## Stack

- **Language / framework:** Dart + Flutter (cross-platform iOS + Android + web)
- **State management:** Riverpod 2.6 (Notifier / NotifierProvider API)
- **Routing:** go_router (auth-aware redirect)
- **Backend:** Firebase (Auth email/password + Cloud Firestore)
- **Maps/nav:** Google Maps (`google_maps_flutter`, Directions + Places APIs) + geolocator
- **AI assistant:** Gemini 2.0 Flash REST API (merged, not yet activated)
- **Local persistence:** shared_preferences (present; profile currently lives in Firestore instead)
- **BLE (later):** flutter_blue_plus — note: flutter_reactive_ble is unmaintained, do not use

## Current status (what's DONE)

- ✅ Phase 0–1 scaffold + all screens, theme/type-scale unified, accessibility pass.
- ✅ **Phase 1.5 — Firebase**: real email/password auth (replaced mock); profile
  (fullName, email, learningDifferences, vibrationProfile) saved to
  `users/{uid}` and reloaded on login. Profile can also be **derived from the
  chosen LD** (skip the survey).
- ✅ **Phase 4 (maps part)**: Routes tab with Google Maps — Places autocomplete,
  From/To with current-location origin, alternative routes classified
  **LD-friendly / fastest / fewest-turns**, fullscreen map, hr+min durations.
- ✅ Home search + favourites now open the Routes tab and route there.
- ✅ Committed to `main` (private repo `github.com/witthayut/Sense-Safe`).
- ✅ **Forgot password (#5)**: real Firebase reset email; `user-not-found` is
  deliberately shown as success (anti account-enumeration), network errors
  shown honestly.
- ✅ **Real favourites (#6)**: created ONLY via the ⭐ on the Routes results
  header (destination guaranteed routable), stored at `users/{uid}.favourites`,
  Home mirrors them; long-press removes.
- ✅ **Settings screen (#7)**: Profile → "Adjust haptics" → sliders for
  intensity/lead-time + rhythm picker + live preview via HapticCuePlayer;
  saves through `AssessmentController.updateTuning()`; `copyWith` protects
  assessment scores from user tuning.
- ✅ **Hardening (#8, data half)**: per-user Firestore rules deployed
  2026-07-15; key work deferred → issue #8 = launch-blocker checklist.
- ✅ **Home redesign "1a Readiness Hero" (2026-07-17)**: user-supplied design
  handoff implemented — sage-gradient hero status card with L/R battery
  chips, one-tap **Resume last route**, **Recent trips** (REAL data: new
  `RecentTrip` model + `recent_trips_controller`, last 5 drives stored at
  `users/{uid}.recentTrips`, recorded on both Start-drive paths), favourites
  as 3-column tiles. New tokens: `AppColors.sageDeep`, `AppColors.onSage`.
- ✅ **Device phase opened on GitHub**: label `device` + milestone
  "Phase: Device (wristband)" + issues **#9 protocol contract → #10 firmware
  skeleton → #11 AH024 motor → #12 real BLE in app → #13 sensors (stretch)**.
- ✅ **Results screen redesign "v3" (2026-07-21)**: second user-supplied HTML
  handoff implemented (same pattern as the Home "1a" one) — hero card with an
  overall-confidence ring (CustomPainter), trait tags fed by the live profile,
  5 dimension cards with Needs-support/Confident chips, reassurance callout,
  two-line Done + outlined Retake. Behavior untouched (null guard, viewOnly
  branching, retake reset); "What this means?" pill opens an explainer sheet.
  New token: `AppColors.warnSoft`.
- ✅ **HAPU EMA + Quick Survey (2026-07-21, = AI proposal ④)**: ending any
  drive shows the report's §3.3 five-question survey (big chips, skippable,
  friendly defaults). Q2/Q3 answers run the §3.4 EMA (α=0.3, `HapuEma` pure
  class) nudging intensity ±0.09 / lead-time ≈±0.9s per trip, clamped to the
  Settings slider ranges; "just right" returns the EXACT value (no FP drift).
  Full survey records append to `users/{uid}.tripSurveys` for future
  K-Means/history work. Route paths also fixed the same day to per-step
  geometry (overview polyline cut across blocks).
- ⏸️ **Gemini AI assistant** (teammate `Tam`'s feature) — merged into `main`,
  lint-clean, tested. Floating chat button on every tab
  (`ai_assistant_overlay.dart` + `assistant_controller.dart`), backed by
  `gemini_service.dart` (Gemini 2.0 Flash REST). **Not activated** — see
  "Gemini API" below.
- ✅ **Haptic Engine (Phase 4 core, simulated)** — "Start drive" on the Routes
  tab opens `/drive`: a simulated car follows the chosen route (40 km/h ×
  1/2/4 demo control) and **buzzes the correct wrist ahead of each turn** via
  mock BLE. Cue ladder per turn: PREP (300 m, half intensity) → ALERT
  (speed × profile lead-time, clamped 60–250 m, pattern from rhythm) → NOW
  (30 m, strongest). Arrival = gentle pulse on BOTH wrists (never used for
  turns). Start requires both bands connected ("Connect & start" dialog);
  mid-drive disconnect suppresses cues + shows a banner. GitHub issue #4.

## NEXT (in priority order)

1. **Device #9 — BLE protocol contract** (`firmware/PROTOCOL.md`: UUIDs +
   7-byte packet). Needs NO hardware; unblocks the whole device track
   (#10–#12). Design it grilling-style with the user.
2. **AI decision** — 5 proposals await the user (see Pending decisions).
3. **Real GPS drive mode** — swap the simulated position for a geolocator
   stream projected onto the route via `RoutePath.project` (engine already
   built for this); plus off-route re-routing (state exists, no detection UI).
4. **Device #12 — real BLE in the app** (`flutter_blue_plus`) behind the same
   `BleController` API; `pulse()` becomes the 7-byte packet write. Hardware:
   ESP32-C3 Super Mini ×2 + AH024 PWM motor etc. (PROJECT_BRIEF ★★ table).

See `planning/Tech-Plan.md` and `report/PROJECT_BRIEF.md` for the full
long-term plan beyond this app scaffold.

## Working mode — BUILD + EXPLAIN (updated 2026-07-15)

The user (beginner developer, Thai — ตอบไทยได้เสมอ) first asked to be taught
hands-on (2026-07-10), then refined it (2026-07-15): "ไม่ต้องสอนผมเขียน
แต่อธิบายว่าคุณทำอะไรก็พอ เน้นความเข้าใจของทั้งโครงการ" — **implement directly,
then explain at the project/architecture level** (what was added, where it
sits in the 3-layer model, how data flows, why this design). No more
fill-in-the-blank typing exercises. Product decisions (trade-offs, money,
scope) still go to the user — recommend and let them pick; if they defer,
decide and proceed.

Lessons completed so far:
1. The 3-layer mental model (models = what things ARE, services = what the
   app DOES, features = what the user SEES; Riverpod is the glue; the real
   backend is Firebase/Google servers, `services/` is the on-phone logic layer).
2. `models/wristband.dart` line by line (enum, final, `int?`, copyWith —
   "state is never modified, it's replaced").
3. `devices_screen.dart` (ref.watch vs ref.read — "watch what you display,
   read what you call"; screens are mirrors of state; WaitingScreen is
   swapped in-place, not navigated to).
4. Finding definitions: imports + Ctrl+Click / F12 / Shift+F12.
5. SE thinking: the 6-activity loop, the 5 questions, the "finding format"
   (behavior + evidence file:line + verdict + proposal), defense in depth.
   Passed exercise: Test button disabled when disconnected (band_tile.dart:68).
6. `ble_controller.dart` anatomy: Notifier skeleton, `state = ...` announces
   changes, async/await, and the `_generation` race-condition guard.

Former open exercises (retired 2026-07-15 when the mode changed to
build+explain — free to answer/discuss openly if the user ever asks):
Ticket #2 (mid-calibration disconnect trace) and the 3 ble_controller
check questions.

## Pending decisions — waiting on the user (do NOT start these)

- **Report corrections**: the AI-architecture slide was FIXED by the user
  2026-07-17 (all audit items pass — see PROJECT_BRIEF ★★ audit section).
  Remaining: the **hardware erratum** (report p.2.8 still says DRV2605L+LRA;
  real set is AH024 PWM) — offered to draft it, user hasn't said yes.
- **AI enhancements** (proposed 2026-07-10): ④ HAPU EMA **DONE 2026-07-21**
  (user approved it via the Quick Survey request; K-Means clustering +
  Collaborative Filtering cold-start remain future work needing more
  users/trips). Still awaiting user confirmation: ① activate the existing
  Gemini assistant (needs billing), ② AI route explanations in LD-friendly
  wording, ③ landmark hints ("turn at the 7-Eleven", cache by route hash),
  ⑤ LD Score formula upgraded to the report spec. Recommended order: ① → ②.
- **Firmware (Arduino/ESP32)**: plan is now tracked as GitHub issues
  **#9–#13** (label `device`, milestone "Phase: Device (wristband)") —
  protocol contract FIRST (#9, `firmware/PROTOCOL.md` at the repo root,
  beside `app/`. App + firmware share the 7-byte packet, so they live in ONE
  repo and change in one commit; firmware never goes inside `app/lib/`).
  Hardware set confirmed
  2026-07-14 (PROJECT_BRIEF ★★ table): ESP32-C3 Super Mini ×2, MPU-6050,
  GY-MAX30102, **AH024 PWM motor** (intensity = PWM duty 0-255), AA477 +
  LiPo. App impact: none — `pulse(intensity, durationMs)` maps to (duty, ms).
  Still unknown: whether parts are physically in hand yet. Waiting for the
  user to say "start #9".

## Still mock / stubbed (don't mistake for done)

- **BLE** is fully simulated (`ble_controller.dart`) — battery %s on Home's
  hero card are the mock's 92/88.
- **Drive position is simulated** (ticker along the polyline) — real GPS is a
  future position source; dashcam/YOLO/stress features are out of scope here.
- **Gemini AI assistant** is merged but has no working API key wired in yet
  (waits on a billing decision — see "Gemini API" below). Without a key it
  fails gracefully: shows "API key not configured" in the chat.

## External services / accounts

- **Firebase project**: `senseandsafe-8a030` (display "SenseAndSafe"). Auth =
  Email/Password. Firestore region **asia-southeast1**. Config in
  `app/lib/firebase_options.dart` (+ `app/android/app/google-services.json`)
  — safe to commit (Google config keys).
- **Firestore security: per-user rules DEPLOYED 2026-07-15** (test mode is
  gone). Rules live in `app/firestore.rules` (deployed via
  `firebase deploy --only firestore:rules`); verified by an unauthenticated
  REST probe: 404/allowed before → 403 PERMISSION_DENIED after. Each signed-in
  user can only read/write their own `users/{uid}` doc.
- **Google Maps key** (ends `…mhLsvg`) is in `app/web/index.html`,
  `app/android/app/src/main/AndroidManifest.xml`, and `app/lib/app/maps_config.dart`.
  It IS **API-restricted** to 4 APIs (Maps JS, Maps SDK Android, Directions,
  Places). On **free trial** (no auto-charge; ฿10 budget alert set). Repo is
  **private**, so committing it is acceptable for now.
  - **Decision 2026-07-17 (user chose)**: key-splitting/restrictions stay
    deferred until there's a public domain — referrer locks are meaningless
    on localhost, Android is unused, and web-service endpoints need a proxy
    anyway (do together with the Gemini proxy). Tracked as issue **#8** with
    the red `launch-blocker` label = the pre-launch checklist.
- **Gemini API** (for the AI assistant, `gemini_service.dart`): key is passed
  via `--dart-define=GEMINI_API_KEY=...`, never committed to source — good
  practice, but not yet wired into `/start-system` because there's no working
  key. **Confirmed the free tier is unavailable on this Google account** (two
  separate keys, including a fresh non-default project, both returned
  `429 RESOURCE_EXHAUSTED — limit: 0` on `generateContent`; likely a
  region/eligibility restriction, not a key or project misconfiguration).
  CORS itself is **not** a blocker — verified Google's endpoint sends proper
  `Access-Control-Allow-Origin` headers on both preflight and the real
  response, so a browser call would work fine once quota exists. **Decision
  (2026-07-02): hold off** rather than enable billing — revisit later if the
  assistant becomes a priority. Before activating: enable billing on the
  Gemini project + set a small budget alert (same pattern as the Maps key),
  then wire the key into `/start-system` and re-test end-to-end on web.
  Before public launch, also consider proxying calls through a Firebase
  Cloud Function so the key never ships in the compiled web JS (same
  exposure risk as the Maps key, but Gemini keys can't be domain/API
  restricted the same way, so it's a bigger blank check if leaked).

## How to run

Preferred: the **`/start-system`** skill → serves Flutter **web** on **port 8090**
(`flutter run -d web-server --web-port=8090`). Always reuse 8090; the skill
frees the port first to avoid orphaned `dart.exe`.

Manual:
```bash
flutter pub get
flutter run -d chrome      # or omit -d for a device/emulator
```

- The dev server **stops when a chat session ends** → re-run `/start-system` each
  new session. After code changes, **restart** (web-server doesn't hot-reload)
  and **hard-refresh** the browser (`Ctrl+Shift+R`).
- Installed skills: `start-system`, `grilling`/`grill-me`, `check-project`,
  `check-architecture`.
- **Reading PDFs** (e.g. `report/SenseSafe-Report.pdf`): Poppler is installed via winget
  but NOT on PATH — use the binaries directly at
  `%LOCALAPPDATA%\Microsoft\WinGet\Packages\oschwartz10612.Poppler_*\poppler-25.07.0\Library\bin`
  (`pdftotext -layout` works well; extracted text of the report is Thai).

## Architecture (app/lib/)

```
app/lib/
  main.dart              app entry (ProviderScope + MaterialApp.router)
  firebase_options.dart  generated by flutterfire — never hand-edit
  app/                    router.dart, theme.dart (AppColors + TextTheme),
                           maps_config.dart, app_navigation.dart
                           (home tab + pending-destination providers)
  models/                 app_user, learning_difference, survey,
                           vibration_profile, route_option, route_maneuver,
                           place_prediction, wristband, favourite, recent_trip
  services/                ALL Riverpod controllers + IO services + pure logic:
                           auth/assessment/ble/calibration/drive/assistant/
                           favourites/recent_trips controllers;
                           profile/location/gemini services;
                           directions_service + places_service (each with
                           _fetch/_fetch_io/_fetch_web platform split);
                           cue_scheduler, route_progress, haptic_cue_player
  features/
    auth/                 login, register, forgot password (real reset email)
    onboarding/            welcome + connect wristbands
    assessment/            6-question survey + results
    calibration/           test vibration (left/right calibration pages)
    devices/               pairing + connect/waiting
    routes/                Google Maps route picker + ⭐ save favourite
      widgets/              route_search, predictions_list, map_preview,
                             full_route_map, route_card, hints
    drive/                 guided-drive screen (Haptic Engine UI)
    settings/              haptic fine-tuning (sliders + preview)
    home/                  bottom-nav shell, home ("1a Readiness Hero"
                           design: hero status card, resume, recents,
                           favourite tiles), profile
    assistant/              floating Gemini AI chat overlay
  widgets/                 pill_button, section_label, band_tile
```
`app/` also holds `firestore.rules` + `firebase.json` (run
`firebase deploy --only firestore:rules` from inside `app/`).

- One folder per feature under `app/lib/features/`.
- **Screens are dumb** — they read/watch Riverpod providers. Business logic
  and state live in `app/lib/services/` as `Notifier`s.
- **ALL Riverpod controllers live in `app/lib/services/`** (decided 2026-07-06;
  `assistant_controller` was moved there for consistency) — don't put
  controllers inside feature folders.
- When a screen file grows past ~300 lines, split its private widgets into
  `features/<name>/widgets/` (see `routes/widgets/` as the template).
- Theme colours come from `AppColors` in `app/lib/app/theme.dart` (sage-green
  palette, rounded "pill" buttons) — don't hard-code colours in screens.

## Key gotchas / decisions (don't re-discover these)

- **Web CORS**: the Directions & Places *web services* are CORS-blocked in the
  browser. Web uses **JS interop** to the in-page `google.maps` services
  (`*_fetch_web.dart`); mobile uses HTTP (`*_fetch_io.dart`); chosen via
  conditional `export` in `*_fetch.dart`. Don't "simplify" web back to HTTP.
  (Gemini's REST API is *not* CORS-blocked — verified directly.)
- **Router redirect**: only `/login` (not all auth routes) bounces signed-in
  users to `/home` — otherwise registration's navigate-to-survey gets killed by
  a redirect that disposes the Register screen mid-`await`.
- **BLE resets per user**: `BleController` clears connection when the signed-in
  user changes, so each account starts onboarding disconnected.
- **Results view-only**: Profile → "View full results" opens `/results?view=true`
  (Done button, no device-connect); survey flow keeps "Use this profile".
- **Map controller**: camera moves are wrapped (best-effort) + the preview map has
  a stable key, to avoid "controller used after dispose" when lists rebuild.
- **Web Directions errors**: a rejected `DirectionsService.route()` promise is
  a `MapsRequestError` whose status (e.g. ZERO_RESULTS) lives in its
  `code`/`message` properties — `toString()` alone loses it. `_describe()` in
  `directions_fetch_web.dart` reads them via JS interop; keep it. (Found via a
  real user attempt to route Surat *India* → Chiang Mai: no drivable route.)
- Widget tests run without Firebase init → `AuthController.build()` is guarded in
  try/catch so tests don't crash.
- **SAFETY INVARIANT — left/right cues**: the wrist side comes ONLY from
  Google's maneuver string via `wristForManeuver()` in
  `app/lib/models/route_maneuver.dart` (exhaustively tested). NEVER derive a side
  from bearing/geometry math, and never add a second mapping point.
  Ambiguous maneuvers (merge/straight/ferry) get NO haptic cue by design.
- The cue logic is a pure class (`CueScheduler`) precisely so it's testable
  without timers/BLE — keep it that way; the `DriveController` is thin glue.

## Tests / quality

- `flutter analyze` clean; **42 tests** passing. Files: `profile_service_test`
  (scoring), `route_maneuver_test` (SAFETY: exhaustive maneuver→wrist),
  `route_progress_test` (geometry), `cue_scheduler_test` (cue order/dedupe),
  `hapu_ema_test` (EMA math: exact deltas, convergence, clamps, no-FP-drift),
  `favourite_test` + `recent_trip_test` + `vibration_profile_test`
  (model round-trips), `widget_test` (boot smoke). Run `flutter test`.

## Git / GitHub

- Repo: `github.com/witthayut/Sense-Safe` (**private**). Default branch **main**
  has all current work, including teammate `Tam`'s frontend redesign (ported
  earlier) and Gemini assistant feature (merged 2026-07-02). Feature branches
  are merged via fast-forward/merge into main.
- **Issue board**: #4 Haptic Engine (OPEN — awaiting the user's manual verify,
  then THEY close it); #5/#6/#7 closed; #8 hardening (OPEN, `launch-blocker`
  label = pre-launch checklist); #9–#13 device track (label `device`,
  milestone "Phase: Device (wristband)", #9 first). Convention: commits that
  finish an issue say `Closes #N`; ideas not yet approved stay in this file,
  not on the board.
