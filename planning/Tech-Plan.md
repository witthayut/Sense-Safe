# Haptic Drive — Stack Recommendation & Build Plan

*Planning document. No code yet — this is for you to approve direction first.*
*Prepared June 16, 2026.*

---

## 1. What you're building (so the stack makes sense)

Haptic Drive is a **mobile app + paired hardware** product. The phone runs navigation and decides *when* to fire a cue; two BLE wristbands (left + right) deliver the cue as vibration. The whole point is that a turn is felt on the correct wrist instead of read or heard, which is why the app is built around learning-difference profiles (dyslexia, ADHD, dyscalculia, dyspraxia).

Three technical realities shape every tool choice:

1. **Bluetooth Low Energy (BLE)** to talk to two wristbands at once, with reliable reconnection and a "test vibration" command.
2. **Turn-by-turn routing** — you need each maneuver (turn direction, distance to it, street name) as *data*, because you convert it into vibration timing/intensity rather than just showing a map.
3. **A backend** to store accounts, the personalization survey results, the vibration profile, and per-user preferences.

Everything below serves those three.

---

## 2. Recommended stack

| Layer | Recommendation | Why |
|---|---|---|
| **Language / framework** | **Dart + Flutter** | Your chosen cross-platform path. One codebase → iOS + Android. Best-in-class for the smooth, animated, high-feedback UI these mockups need. |
| **State management** | **Riverpod 3** | 2026 default for new Flutter apps. Less boilerplate than BLoC, compile-time safety, easy to test. Good fit because "connection state + loading + error" is everywhere in a BLE app. |
| **BLE / wristbands** | **flutter_blue_plus** | The actively-maintained standard. (Note: `flutter_reactive_ble` is now unmaintained — avoid it.) Handles scanning, connecting to two devices, writing the vibration characteristic, auto-reconnect. |
| **Maps + navigation** | **Mapbox** (`mapbox_maps_flutter` + Directions API) | Gives you the *maneuver data* you need to drive haptics, plus the dark/light driving map UI in your mockups. Better turn-by-turn data access than Google Maps' Flutter plugin. Google Maps is the fallback if you'd rather stay in the Google ecosystem. |
| **Location/GPS** | **geolocator** | Live position + heading for "Head north" and re-routing. |
| **Backend (auth + data)** | **Firebase** (Auth + Cloud Firestore) | Fastest path for someone with some coding experience. Handles login/register, password reset, and stores the user's profile, survey answers, favorites, and preferences with almost no server code to maintain. |
| **Local storage** | **shared_preferences** (settings) + **Hive/Isar** (offline route + profile cache) | Keep last paired devices, calibration, and preferences on-device so the app works the moment it opens. |
| **Navigation/routing in-app** | **go_router** | Clean handling of the many screens (auth → onboarding → survey → home → drive). |
| **Local notifications** | **flutter_local_notifications** | "Drive complete," survey prompts, low-battery wristband alerts. |

### Supporting tools
- **IDE:** VS Code or Android Studio (Android Studio bundles the Android SDK + emulator — easier if you're newer).
- **Design handoff:** Figma (your mockups look like Figma) → export colors/spacing into a Flutter theme.
- **Version control:** Git + GitHub.
- **Testing:** built-in `flutter_test` for widget tests; `mocktail` to fake the BLE layer so you can test without hardware.
- **CI/CD (later):** Codemagic or GitHub Actions (Flutter-friendly build/sign/release).

> **One thing to decide early:** the wristband firmware's **BLE protocol** — what service/characteristic UUIDs it exposes and what bytes mean "vibrate left, intensity 6, pattern double-pulse." The app design depends on this contract. If the hardware isn't final, define a mock BLE device now and build against it.

---

## 3. How the pieces fit together

```
┌─────────────────────────────────────────────┐
│                 FLUTTER APP                   │
│                                               │
│  UI (screens)  ── Riverpod ──  Services       │
│                                  │            │
│        ┌─────────────────────────┼─────────┐  │
│        │            │            │         │  │
│     Haptic      Navigation     Auth/      Local │
│     Engine       Service       Data       Cache │
│        │            │          (Firebase)        │
│        ▼            ▼                             │
│   flutter_blue   Mapbox/                          │
│     _plus        geolocator                       │
└────────┼─────────────────────────────────────────┘
         │ BLE
   ┌─────┴─────┐
   │ L + R     │  wristbands
   │ wristbands│
   └───────────┘
```

The **Haptic Engine** is the heart of the product and worth isolating as its own service: it takes a maneuver from the Navigation Service ("turn right in 200 m") plus the user's vibration profile and decides exactly what BLE command to send to which wrist, when, and how strongly. Keeping it separate means you can tune it and unit-test it without GPS or hardware.

---

## 4. Suggested project structure

```
lib/
  main.dart
  app/                 # theme, router (go_router), constants
  core/                # shared utils, error handling, BLE protocol constants
  features/
    auth/              # login, register, forgot password
    onboarding/        # welcome, connect wristbands, cold-start calibration
    assessment/        # learning-difference pick + 6-question survey + results
    home/              # "Where to today?", favorites, search destination
    devices/           # pairing, left/right status, test vibration
    routing/           # pick-your-route, route options + ETA
    drive/             # live map, turn cues, re-center, exit
    feedback/          # post-drive quick survey ("improve my model")
    settings/          # account, haptic preferences, driving style
  services/
    ble_service.dart       # flutter_blue_plus wrapper
    haptic_engine.dart     # maneuver + profile -> vibration command
    navigation_service.dart# Mapbox directions + geolocator
    profile_service.dart   # survey scoring -> vibration profile
    auth_service.dart      # Firebase Auth
    data_repository.dart   # Firestore + local cache
  models/              # User, VibrationProfile, Route, Maneuver, Device
```

This maps one folder per screen-group in your mockups, so the plan and the code line up.

---

## 5. Build roadmap (phased)

Each phase is shippable/testable on its own. Rough effort assumes part-time solo work.

**Phase 0 — Foundations (setup)**
Install Flutter, create the project, set up Git, theme from the mockups (colors, the rounded "pill" buttons, the green accent), go_router skeleton with placeholder screens, Firebase project connected. *Outcome: app runs, you can tap between empty screens.*

**Phase 1 — Auth & accounts**
Login, Register (full name / username / password), forgot password, learning-difference picker. Firebase Auth + a user document in Firestore. *Outcome: a real account you can log into.*

**Phase 2 — Assessment & profile (the differentiator)**
The 6-question survey, the scoring logic that turns answers into the "Spatial Type" results screen (the confidence bars: left/right certainty, distance comfort, sign reading, attention, hearing), and saving the resulting **vibration profile**. *Outcome: a personalized profile object the haptic engine can later read.*

**Phase 3 — Device pairing (BLE)**
"Connecting devices" scan screen, pair left + right wristbands, show connection/battery status, **Test Vibration** button, cold-start calibration. Build against a **mock BLE device** first if hardware isn't ready. *Outcome: you can connect and buzz a wristband.*

**Phase 4 — Maps, routing & the Haptic Engine**
Home destination search + favorites, "Pick your route" with route options/ETA, live map with current position and "Head north." Then the core loop: as you approach a maneuver, the Haptic Engine fires the correct wrist at the profile's intensity/lead-time. *Outcome: a real (or simulated) drive that buzzes you through turns.*

**Phase 5 — Settings, feedback & polish**
Account & settings (vibration intensity, lead-warning time, haptic rhythm, turn-confirm styles), the post-drive "Quick Survey" that nudges the profile, notifications, error/edge handling (lost BLE connection mid-drive, GPS loss, rerouting). *Outcome: a coherent end-to-end product.*

**Phase 6 — Test & release prep**
Widget tests, mocked BLE/nav tests for the Haptic Engine, real-device testing, app store assets, CI build. *Outcome: ready for TestFlight / Play internal testing.*

---

## 6. Things to nail down before/while coding

- **Wristband BLE spec** — UUIDs and command format (the single biggest dependency).
- **Maps provider + API keys** — Mapbox vs Google decides cost and the navigation API you code against; both need a billing account.
- **Safety & legal** — a driving app that interacts with the user mid-drive needs a clear "for guidance, eyes on road" disclaimer and minimal-interaction-while-moving design.
- **Accessibility** — since the audience has learning differences, lean on large text, dyslexia-friendly fonts (e.g. a toggle for OpenDyslexic), high contrast, and minimal on-screen reading — your survey already measures exactly these needs, so feed them back into the UI.
- **Data privacy** — survey answers touch on learning differences (sensitive data); plan your privacy policy and storage accordingly.

---

## 7. Quick answer to "which languages and tools"

**Language:** Dart. **Framework:** Flutter. **Core tools:** Riverpod (state), flutter_blue_plus (wristbands), Mapbox + geolocator (navigation), Firebase (accounts + data), go_router (screens). **Build with:** Android Studio or VS Code + Git/GitHub.

If you approve this, the natural next step is **Phase 0 + Phase 1**: I scaffold the runnable Flutter project with the theme and the auth/onboarding screens wired up, using a mock BLE device so you don't need hardware to see it working.
