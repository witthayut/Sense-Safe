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

## NEXT (in priority order)

1. **Haptic Engine** (Phase 4 core) ⭐ — "Start drive" follows the chosen route
   and **buzzes the correct wrist ahead of each turn**, using the vibration
   profile + BLE controller. Runs on the **mock BLE** (demoable now). It is
   **SAFETY-CRITICAL — left/right must be exact.** Design with `/grill-me` first
   (turn detection, profile→buzz mapping, drive screen, off-route/arrival).
2. **Phase 2 — Settings screen**: sliders to fine-tune intensity/lead-time/
   rhythm; save to Firestore.
3. **Real saved favourites** in Firestore (Home favourites are currently mock).
4. **Phase 3 — real BLE** (`flutter_blue_plus`). Biggest open dependency =
   the wristband firmware's **service/characteristic UUIDs** (see
   `PROJECT_BRIEF.md` for the confirmed hardware: ESP32 + DRV2605L + LRA motor).

See `HapticDrive_Tech_Plan.md` and `PROJECT_BRIEF.md` (one level up) for the
full long-term plan beyond this app scaffold.

## Still mock / stubbed (don't mistake for done)

- **BLE** is fully simulated (`ble_controller.dart`).
- Home **favourites** are hardcoded labels; tapping routes by the label name.
- **"Start drive & Dashcam"** button = stub (waits for the Haptic Engine).
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
  app/                    router.dart, theme.dart (AppColors + TextTheme),
                           maps_config.dart, app_navigation.dart
                           (home tab + pending-destination providers),
                           firebase_options.dart
  models/                 app_user, learning_difference, survey,
                           vibration_profile, route_option, place_prediction
  services/                Riverpod controllers + platform fetchers:
                           auth_controller, assessment_controller,
                           profile_service, ble_controller, location_service,
                           directions_service (+ _common/_fetch/_fetch_io/_fetch_web),
                           places_service (+ fetchers), gemini_service
  features/
    auth/                 login, register, forgot password
    onboarding/            welcome + connect wristbands
    assessment/            6-question survey + results
    calibration/           test vibration (left/right calibration pages)
    devices/               pairing + connect/waiting
    routes/                Google Maps route picker
    home/                  bottom-nav shell, home, profile
    assistant/              floating Gemini AI chat overlay
  widgets/                 pill_button, section_label, band_tile
```

- One folder per feature under `lib/features/`.
- **Screens are dumb** — they read/watch Riverpod providers. Business logic
  and state live in `lib/services/` as `Notifier`s.
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
- Widget tests run without Firebase init → `AuthController.build()` is guarded in
  try/catch so tests don't crash.

## Tests / quality

- `flutter analyze` clean. Tests: `profile_service_test.dart` (scoring),
  `widget_test.dart` (boot smoke). Run `flutter test`.

## Git

- Repo: `github.com/witthayut/Sense-Safe` (**private**). Default branch **main**
  has all current work, including teammate `Tam`'s frontend redesign (ported
  earlier) and Gemini assistant feature (merged 2026-07-02). Feature branches
  are merged via fast-forward/merge into main.
