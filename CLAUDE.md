# Haptic Drive — project context

This file is read automatically by Claude Code at the start of each session.
It captures architecture, conventions, and current build status — keep it
updated as work progresses so future sessions don't have to re-derive state.

> 📌 **For the full product vision** (hardware BOM, 6-layer AI architecture,
> target users, competitors) see **`../PROJECT_BRIEF.md`** one level up —
> a quick-reference summary of the official project report (`Sense&Safe.pdf`).
> This file covers the **Flutter app** specifically: what's actually built,
> vs. the full vision described there.

## What this project is

A Flutter app that delivers turn-by-turn driving navigation as **wrist
vibration** instead of (or alongside) on-screen text and voice. Two BLE
wristbands — left + right — buzz the correct wrist for each turn. It's designed
for people with learning differences (dyslexia, ADHD, dyscalculia, dyspraxia);
a 6-question onboarding assessment builds a personal "vibration profile" that
tunes buzz intensity, lead time, and rhythm.

The app you're working in is a **prototype/scaffold** of a much larger vision
(dashcam object detection, stress-adaptive haptics, voice control — see
`PROJECT_BRIEF.md`); only the pieces below are actually built so far.

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

1. **Phase 2 — Settings screen**: sliders to fine-tune intensity/lead-time/
   rhythm; save to Firestore.
2. **Real saved favourites** in Firestore (Home favourites are currently mock).
3. **Real GPS drive mode** — swap the simulated position for a geolocator
   stream projected onto the route via `RoutePath.project` (engine already
   built for this); plus off-route re-routing (state exists, no detection UI).
4. **Phase 3 — real BLE** (`flutter_blue_plus`). Biggest open dependency =
   the wristband firmware's **service/characteristic UUIDs** (see
   `PROJECT_BRIEF.md` §3 for the theoretical hardware: ESP32 + DRV2605L +
   LRA motor; see §3b for the **prototype BOM swap** as of 2026-07-10 —
   ESP32-C3 Super Mini, GY-MAX30102, MPU6050, AH024 vibration module
   instead of DRV2605L+LRA). `BleController.pulse()` becomes the 7-byte
   packet write regardless of which board.

See `HapticDrive_Tech_Plan.md` and `PROJECT_BRIEF.md` (one level up) for the
full long-term plan beyond this app scaffold.

## Working mode — TEACH, don't just build (since 2026-07-10)

The user (beginner developer, Thai — ตอบไทยได้เสมอ) asked to LEARN from this
project rather than have features built for them ("I feel so stupid since you
did all of this"). New rule: **explain → user tries → review.** Go slower,
guide instead of doing, give small check-questions each lesson, and wait for
their answers before moving on.

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

OPEN exercises — do NOT spoil the answers:
- **Ticket #2**: what happens if a band disconnects MID-calibration?
  (trace test_vibration_screen → calibration_controller; report in finding
  format.)
- 3 check questions on ble_controller: (a) how many rebuilds per Connect tap,
  (b) why the app doesn't freeze during `await`, (c) walk the generation
  guard for cancel-at-0.5s.

## Pending decisions — waiting on the user (do NOT start these)

- **AI enhancements** (proposed 2026-07-10; user explicitly said to wait for
  confirmation): ① activate the existing Gemini assistant (needs billing),
  ② AI route explanations in LD-friendly wording, ③ landmark hints ("turn at
  the 7-Eleven", cache by route hash), ④ HAPU EMA personalisation from
  post-trip surveys (no API cost, no hardware), ⑤ LD Score formula upgraded
  to the report spec. Recommended order if approved: ① → ② → ④.
- **Firmware (Arduino/ESP32)**: agreed plan = a `Sense&Safe/firmware/`
  sibling folder (monorepo — firmware never goes inside `lib/`), and write
  the BLE **protocol contract first** (`firmware/PROTOCOL.md`: service/
  characteristic UUIDs + the 7-byte packet layout) before any sketch.
  **Hardware set confirmed 2026-07-14** (sourced replacements, see
  PROJECT_BRIEF.md ★★ update): ESP32-C3 Super Mini ×2, MPU-6050,
  GY-MAX30102, **AH024 PWM motor module** (NOT the planned DRV2605L+LRA —
  intensity = raw PWM duty 0-255, coarser but fine for the prototype),
  AA477 Type-C charger + 3.7V 500mAh LiPo. App impact: none —
  `BleController.pulse(intensity, durationMs)` maps straight to
  (duty, ms). Still unknown: whether parts are physically in hand yet.

## Still mock / stubbed (don't mistake for done)

- **BLE** is fully simulated (`ble_controller.dart`).
- Home **favourites** are hardcoded labels; tapping routes by the label name.
- **Drive position is simulated** (ticker along the polyline) — real GPS is a
  future position source; dashcam/YOLO/stress features are out of scope here.
- Forgot-password = stub.
- **Gemini AI assistant** is merged but has no working API key wired in yet
  (waits on a billing decision — see "Gemini API" below). Without a key it
  fails gracefully: shows "API key not configured" in the chat.

## External services / accounts

- **Firebase project**: `senseandsafe-8a030` (display "SenseAndSafe"). Auth =
  Email/Password. Firestore region **asia-southeast1**, currently **Test mode**.
  Config in `lib/firebase_options.dart` (+ `android/app/google-services.json`)
  — safe to commit (Google config keys).
- **Per-user Firestore rules** (apply before any real launch — replaces test mode):
  ```
  rules_version = '2';
  service cloud.firestore { match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
  }}}
  ```
- **Google Maps key** (ends `…mhLsvg`) is in `web/index.html`,
  `android/app/src/main/AndroidManifest.xml`, and `lib/app/maps_config.dart`.
  It IS **API-restricted** to 4 APIs (Maps JS, Maps SDK Android, Directions,
  Places). On **free trial** (no auto-charge; ฿10 budget alert set). Repo is
  **private**, so committing it is acceptable for now.
  - TODO before public launch: split into per-platform keys with
    HTTP-referrer (web) + Android-app/SHA-1 restrictions. (One key can only have
    ONE application-restriction type, which is why we left it as None for now.)
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

## Architecture (lib/)

```
lib/
  main.dart              app entry (ProviderScope + MaterialApp.router)
  firebase_options.dart  generated by flutterfire — never hand-edit
  app/                    router.dart, theme.dart (AppColors + TextTheme),
                           maps_config.dart, app_navigation.dart
                           (home tab + pending-destination providers)
  models/                 app_user, learning_difference, survey,
                           vibration_profile, route_option, route_maneuver,
                           place_prediction, wristband
  services/                ALL Riverpod controllers + IO services + pure logic:
                           auth/assessment/ble/calibration/drive/assistant
                           controllers; profile/location/gemini services;
                           directions_service + places_service (each with
                           _fetch/_fetch_io/_fetch_web platform split);
                           cue_scheduler, route_progress, haptic_cue_player
  features/
    auth/                 login, register, forgot password
    onboarding/            welcome + connect wristbands
    assessment/            6-question survey + results
    calibration/           test vibration (left/right calibration pages)
    devices/               pairing + connect/waiting
    routes/                Google Maps route picker
      widgets/              route_search, predictions_list, map_preview,
                             full_route_map, route_card, hints
    drive/                 guided-drive screen (Haptic Engine UI)
    home/                  bottom-nav shell, home, profile
    assistant/              floating Gemini AI chat overlay
  widgets/                 pill_button, section_label, band_tile
```

- One folder per feature under `lib/features/`.
- **Screens are dumb** — they read/watch Riverpod providers. Business logic
  and state live in `lib/services/` as `Notifier`s.
- **ALL Riverpod controllers live in `lib/services/`** (decided 2026-07-06;
  `assistant_controller` was moved there for consistency) — don't put
  controllers inside feature folders.
- When a screen file grows past ~300 lines, split its private widgets into
  `features/<name>/widgets/` (see `routes/widgets/` as the template).
- Theme colours come from `AppColors` in `lib/app/theme.dart` (sage-green
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
  `models/route_maneuver.dart` (exhaustively tested). NEVER derive a side
  from bearing/geometry math, and never add a second mapping point.
  Ambiguous maneuvers (merge/straight/ferry) get NO haptic cue by design.
- The cue logic is a pure class (`CueScheduler`) precisely so it's testable
  without timers/BLE — keep it that way; the `DriveController` is thin glue.

## Tests / quality

- `flutter analyze` clean. Tests: `profile_service_test.dart` (scoring),
  `route_maneuver_test.dart` (SAFETY: exhaustive maneuver→wrist mapping),
  `route_progress_test.dart` (polyline geometry), `cue_scheduler_test.dart`
  (cue order/dedupe/thresholds), `widget_test.dart` (boot smoke).
  Run `flutter test`.

## Git

- Repo: `github.com/witthayut/Sense-Safe` (**private**). Default branch **main**
  has all current work, including teammate `Tam`'s frontend redesign (ported
  earlier) and Gemini assistant feature (merged 2026-07-02). Feature branches
  are merged via fast-forward/merge into main.
