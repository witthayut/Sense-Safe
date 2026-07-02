# Haptic Drive — working context

> Living status/handoff doc. Read this first in a new chat. Pairs with
> `CLAUDE.md` (decisions/architecture) — this file tracks **current state,
> what's done, what's next, and gotchas**. Keep it updated as work progresses.

## What the app is
"Sense & Safe / Haptic Drive" — a Flutter app giving **felt turn-by-turn
navigation via two BLE wrist­bands** (left + right buzz the correct wrist for a
turn). Aimed at people with learning differences (dyslexia, ADHD, dyscalculia,
dyspraxia). A 6-question assessment builds a personal **vibration profile**
(intensity, lead-time, rhythm) that tunes the cues.

## Stack
- Flutter + Dart, **Riverpod** (Notifier API), **go_router** (auth-aware).
- **Firebase**: Auth (email/password) + Cloud Firestore (profile storage).
- **Google Maps**: `google_maps_flutter`, `http`, `geolocator` (routing).
- `shared_preferences` (present; profile now lives in Firestore instead).

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
   the wristband firmware's **service/characteristic UUIDs**.

## Still mock / stubbed (don't mistake for done)
- **BLE** is fully simulated (`ble_controller.dart`).
- Home **favourites** are hardcoded labels; tapping routes by the label name.
- **"Start drive & Dashcam"** button = stub (waits for the Haptic Engine).
- Forgot-password = stub.

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

## Dev workflow
- Run with the **`/start-system`** skill → serves Flutter **web** on **port 8090**
  (`flutter run -d web-server --web-port=8090`). Always reuse 8090; the skill
  frees the port first to avoid orphaned `dart.exe`.
- The dev server **stops when a chat session ends** → re-run `/start-system` each
  new session. After code changes, **restart** (web-server doesn't hot-reload)
  and **hard-refresh** the browser (`Ctrl+Shift+R`).
- Installed skills: `start-system`, `grilling`/`grill-me`, `check-project`,
  `check-architecture`.

## Architecture (lib/)
- `app/` — `router.dart`, `theme.dart` (AppColors + TextTheme), `maps_config.dart`,
  `app_navigation.dart` (home tab + pending-destination providers), `firebase_options.dart`.
- `models/` — app_user, learning_difference, survey, vibration_profile,
  route_option, place_prediction.
- `services/` — Riverpod controllers + platform fetchers: auth_controller,
  assessment_controller, profile_service, ble_controller, location_service,
  directions_service (+ `_common`/`_fetch`/`_fetch_io`/`_fetch_web`),
  places_service (+ fetchers).
- `features/` — auth, onboarding, assessment, calibration, devices, routes, home.
- `widgets/` — pill_button, section_label, band_tile.
- Pattern: **screens are dumb**, read/watch providers; logic lives in services.

## Key gotchas / decisions (don't re-discover these)
- **Web CORS**: the Directions & Places *web services* are CORS-blocked in the
  browser. Web uses **JS interop** to the in-page `google.maps` services
  (`*_fetch_web.dart`); mobile uses HTTP (`*_fetch_io.dart`); chosen via
  conditional `export` in `*_fetch.dart`. Don't "simplify" web back to HTTP.
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
  has all current work. Teammate branch `Tam` exists (frontend, already ported).
  Feature branches are merged via fast-forward into main.
