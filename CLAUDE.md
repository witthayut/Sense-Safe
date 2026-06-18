# Haptic Drive — project context

This file is read automatically by Claude Code at the start of each session.
It captures the decisions and current state so you don't have to re-explain.

## What this project is

A Flutter app that delivers turn-by-turn driving navigation as **wrist
vibration** instead of (or alongside) on-screen text and voice. Two BLE
wristbands — left + right — buzz the correct wrist for each turn. It's designed
for people with learning differences (dyslexia, ADHD, dyscalculia, dyspraxia);
a 6-question onboarding assessment builds a personal "vibration profile" that
tunes buzz intensity, lead time, and rhythm.

## Stack

- **Language / framework:** Dart + Flutter (cross-platform iOS + Android)
- **State management:** Riverpod 2.6 (Notifier / NotifierProvider API)
- **Routing:** go_router (auth-aware redirect)
- **Local persistence:** shared_preferences (planned)
- **BLE (later):** flutter_blue_plus — note: flutter_reactive_ble is unmaintained, do not use
- **Maps/nav (later):** Mapbox (`mapbox_maps_flutter` + Directions API) + geolocator
- **Backend (later):** Firebase (Auth + Cloud Firestore)

## Current status — IMPORTANT

This is the **Phase 0 + Phase 1 scaffold**. The whole app runs end-to-end on
**mock, in-memory services** so it works with no backend, no API keys, and no
hardware. Specifically:

- `auth_controller.dart` — mock auth; any non-empty username/password "works".
- `ble_controller.dart` — simulated scan/connect/vibrate; no real Bluetooth.
- `assessment_controller.dart` + `profile_service.dart` — real scoring logic,
  in-memory only (not persisted yet).

The UI only ever talks to these controllers, so swapping in real
implementations should not require changing the screens.

## Project structure

```
lib/
  main.dart              app entry (ProviderScope + MaterialApp.router)
  app/                   theme.dart, router.dart
  models/                AppUser, LearningDifference, survey, VibrationProfile, Wristband
  services/              mock auth, mock BLE, assessment + profile scoring (Riverpod)
  features/
    auth/                login, register, forgot password
    onboarding/          welcome + connect wristbands
    assessment/          6-question survey + results
    home/                bottom-nav shell, home, profile, placeholders
    devices/             pairing + test vibration
  widgets/               shared PillButton
```

## Conventions

- One folder per feature under `lib/features/`.
- Business logic and state live in `lib/services/` as Riverpod `Notifier`s;
  widgets stay dumb and read/watch providers.
- Theme colours come from `AppColors` in `lib/app/theme.dart` (sage-green
  palette, rounded "pill" buttons) — don't hard-code colours in screens.

## How to run

```bash
flutter pub get
flutter run -d chrome      # fastest; or omit -d for a device/emulator
```

## Roadmap / next steps

- **Phase 1.5:** replace mock `AuthController` with Firebase Auth + Firestore;
  persist the vibration profile.
- **Phase 2:** Settings screen to fine-tune intensity / lead time / rhythm;
  persist profile locally with shared_preferences.
- **Phase 3:** real BLE in `BleController` against the wristband firmware's
  service/characteristic UUIDs (this UUID spec is the biggest open dependency).
- **Phase 4:** Mapbox map + Directions, route picker, and the **Haptic Engine**
  that fires the correct wrist ahead of each maneuver.

See `HapticDrive_Tech_Plan.md` (one level up) for the full plan.
