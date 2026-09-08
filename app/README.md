# Haptic Drive (Flutter)

Felt turn-by-turn navigation for different learning styles. This is the
**Phase 0 + Phase 1** scaffold: it runs end-to-end on **mock services**, so you
don't need Firebase, Mapbox keys, or wristband hardware to see it working.

## What works right now

- **Login / Register / Forgot password** (mock auth — any non-empty
  username + password logs you in).
- **Learning-difference picker** on Register; choosing "I'm not sure" routes
  you into the assessment.
- **6-question assessment** → scored into a **vibration profile** with
  confidence bars and a friendly "spatial type" (never a diagnosis).
- **Device onboarding + Devices tab** — simulated BLE scan/connect for the
  left & right wristbands, with a working "Test vibration" button.
- **Home** ("Where to today?"), **Profile** (shows your profile + logout),
  and placeholder **Routes** tab.

## Run it

You need the Flutter SDK installed (https://docs.flutter.dev/get-started/install).

```bash
cd haptic_drive
flutter pub get
flutter run            # pick a device/emulator, or use Chrome for a quick look
```

Tip: `flutter run -d chrome` is the fastest way to view the UI without setting
up an Android/iOS emulator.

## Project layout

```
lib/
  main.dart                  app entry (ProviderScope + MaterialApp.router)
  app/
    theme.dart               colours + Material 3 theme from the mockups
    router.dart              go_router with auth redirect
  models/                    AppUser, LearningDifference, survey, VibrationProfile, Wristband
  services/                  mock auth, mock BLE, assessment + profile scoring (Riverpod)
  features/
    auth/                    login, register, forgot password
    onboarding/              welcome + connect wristbands
    assessment/              survey + results
    home/                    bottom-nav shell, home, profile, placeholders
    devices/                 pairing + test vibration
  widgets/                   shared PillButton
```

## How the mock layer maps to real services later

Everything the UI talks to goes through a Riverpod controller, so swapping in
real implementations doesn't touch the screens:

| Mock now | Real later (phase) |
|---|---|
| `AuthController` (in-memory) | Firebase Auth + Firestore (1.5) |
| `BleController` (simulated buzz) | `flutter_blue_plus` against firmware UUIDs (3) |
| `ProfileService` scoring | same logic, tune weights after user testing (2) |
| Home favourites (hard-coded) | Mapbox Directions + saved places (4) |

## Next steps

- **Phase 2:** persist the vibration profile (shared_preferences/Firestore) and
  add the Settings screen to fine-tune intensity / lead time / rhythm.
- **Phase 3:** real BLE — define the wristband's service/characteristic UUIDs
  and replace `BleController`'s body.
- **Phase 4:** Mapbox map + Directions, the route picker, and the **Haptic
  Engine** that fires the correct wrist ahead of each maneuver.

See `../HapticDrive_Tech_Plan.md` for the full roadmap.
