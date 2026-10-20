# Sense&Safe — project context

This file is read automatically by Claude Code at the start of each session.
It captures architecture, conventions, and current build status — keep it
updated as work progresses so future sessions don't have to re-derive state.

> 📌 **For the full product vision** (hardware BOM, 6-layer AI architecture,
> target users, competitors) see **`report/PROJECT_BRIEF.md`** — a
> quick-reference digest of the official report (`report/SenseSafe-Report.pdf`).
> Most of THIS file covers the **Flutter app** in `app/`: what is actually
> built, versus the full vision described there.

## Repo layout (restructured 2026-09-07, folder renamed 2026-09-08)

This repository is the whole project, not just the app. One root, six folders:

```
Sense-Safe/            ← git root = github.com/witthayut/Sense-Safe
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

> **Status 2026-10-10:** this paragraph describes the ORIGINAL driving-first
> framing, which is what the code implements today. A pivot to an everyday
> task-support copilot for Pure LD was proposed 2026-09-13 (next section) and
> is the direction all design discussion since then has followed; the user
> has not yet confirmed it officially, so issues/report are not re-scoped.

The app you're working in is a **prototype/scaffold** of a much larger vision
(dashcam object detection, stress-adaptive haptics, voice control — see
`report/PROJECT_BRIEF.md`); only the pieces below are actually built so far.

## ⚠️ Pivot proposed 2026-09-13 — "Everyday Life & Mobility Copilot for Pure LD"

Feedback (from the validation work started Sept 2026): haptic *driving*
navigation serves a very small group — few adults with LD drive, and the app
is useful only while driving, so usage frequency is low. The user brought a
full spec for a broader product (**status: proposal; not yet confirmed as the
new scope — ask before re-scoping issues or the report**). Spec saved
verbatim at [`planning/Pivot-2026-09-13-Everyday-Copilot.md`](planning/Pivot-2026-09-13-Everyday-Copilot.md).

In one paragraph: target narrows to **Pure LD** (dyslexia/dysgraphia/
dyscalculia, explicitly *no* ADHD/ASD — note the old design's stress-adaptive
haptics targeted ADHD); scope widens to everyday tasks — phone app ("The
Brain": OCR → plain-language summary → one-step-at-a-time checklist,
scheduling, RAG Q&A, filing, error guard, TTS) + wristband ("Physical
Co-pilot": left/right cueing for outdoor walking/transit, **wrist-flick
check-off via the MPU-6050 gyro** (was double tap; changed 2026-09-13), HR
grounding via MAX30102 only when still). Medical-scope boundary
is explicit (task-support tool, never diagnosis; "situational anxiety", never
"panic detection"). MVP happy path: photo of appointment doc → AI checklist →
wrist buzz per step → wrist flick confirms → recorded.

**Decisions already made by the user (all 2026-09-13):**
1. No indoor navigation — mobility is outdoor walking + public transit only.
2. Two bands stay; side = which wrist buzzes; both wrists = never a turn
   (arrival, transit hop-off pre-alert, missed stop).
3. Confirmation gesture = wrist flick/twist (gyro roll axis), not double tap.
4. No caregiver layer — the LD user operates everything alone.
5. Error Guard = One-Tap Clipboard Guard + Uncertainty Alert + Confirmation
   & History; no background clipboard monitoring.

**Still open (user's call):** (a) is the pivot officially confirmed (advisor),
(b) is the wristband the core or an accessory to the AI app, (c) which LLM
provider / billing for "The Brain".

Claude's assessment (2026-09-13, details in that session's reply):
- **Carries over almost everything built**: BLE controller + wrist safety
  invariant + cue ladder + personal floor calibration → "Mobility mode";
  MAX30102 v3 `win` estimator + quality gate = the spec's rule #2; HAPU EMA
  pattern = "personalized baseline"; Firebase per-user model extends to docs.
- **Hard blocker**: "The Brain" needs a multimodal LLM. This Google account
  has **no Gemini quota** (see Gemini API section) → the deferred billing /
  provider decision becomes unavoidable. On-device ML Kit OCR is a free
  fallback for the demo, not for the LLM parts.
- **Indoor navigation is OUT — user decided 2026-09-13** ("ยากมากเรื่องการหา
  API และข้อมูล"). The spec's "เดินในอาคาร" wording is superseded. Mobility =
  outdoor only (Google Directions walking/driving), so the SAFETY INVARIANT
  (side from Google's maneuver string) stays intact. Never promise indoor.
- **Scope risk**: ~12 app features + 3 wearable functions; the spec's own
  MVP path is the right cut. Defer RAG/citation, semantic filing, lead-time
  scheduling, audit trail, confidence scoring past the MVP.
- **Immediate concrete impact**: PROTOCOL.md (#9, not yet written) must
  become **two-way** (band→phone notify: gesture events, HR windows,
  battery, button). Next hardware piece = the confirmation-gesture detector
  as `firmware/test/gesture_test` with a Python bench first (same method
  as v3). **Gesture DECIDED 2026-09-13: wrist flick/twist (gyro roll axis),
  NOT double tap** — the user's basic MPU-6050 sketch already exists at
  `firmware/test/mpu-6050/Test-Mpu.ino` (folder/file name mismatch, fix
  before opening in the IDE). Spec rule #1's tap filters map onto the
  flick: isolate the roll axis instead of Z, require twist-and-return
  within a short window instead of two taps, keep stillness pre-condition,
  listening window, haptic ack and the 3 s button undo. Full revised rule
  (roll-axis isolation, **bi-directional zero-crossing**, out-and-back
  within **150-400 ms**, peak-rate threshold TBD by measurement) = addendum C
  in the planning file. Peak threshold and which gyro axis is "roll" are
  measured, not assumed — same method as the motor floor.
- The 6-question assessment's trait labels ("Dyspraxia-leaning") conflict
  with the new medical boundary → reword as preferences or remove.
- AH024 module already contains its driver transistor (README) — rule #3's
  "never drive the motor from a GPIO" is satisfied; no rewiring needed.

**Round 2 (same day) — Mobility = "Pedestrian & Transit Mode" + "Transit
Hop-off Guard"** (addendum B in the same planning file): outdoor walking
turn-by-turn via Google/Mapbox, and a pre-alert 300-500 m before the target
bus stop / BTS-MRT station, with missed-stop recovery and a time-based
fallback when GPS dies underground (MRT). Claude's flags:
- **Direction-by-pattern conflicts with the SAFETY INVARIANT.** The addendum
  proposes "2 short = left, 1 long = right" on (apparently) one band. Our
  design encodes side as *which wrist buzzes* (no decoding; exactly the
  left/right mapping LD users struggle with) and pulse *count* as urgency
  (v2: PREP 1 / ALERT 2 / NOW 4, wrist-tested). Pattern-coded direction
  reintroduces a code to memorise AND collides with the count vocabulary.
  **DECIDED by the user 2026-09-13: two bands stay; side = which wrist
  buzzes; hop-off and missed-stop get their own patterns on BOTH wrists
  (both wrists = never a turn).** The addendum's "2 short = left / 1 long =
  right" is superseded. The haptic vocabulary (turn stages per wrist +
  arrival + hop-off pre-alert + missed-stop, all on both wrists) must be
  defined once in PROTOCOL.md and blind-tested together (v2 re-test pending).
- **Prefer the geofence approach over NotificationListenerService.** The
  listener scrapes Google Maps' notification text (unofficial, changes with
  app updates/locale, needs the scary "notification access" permission,
  Android-only). Geofence = our own `route_progress` distance math on a
  geolocator stream, portable, and the same engine NEXT #3 (real GPS) needs.
- **Legacy Directions transit mode gives arrival/departure stops, not the
  intermediate stop list** → "alert 1 stop before" needs GTFS data (Thai
  availability unknown). Alert by distance (300-500 m) instead; skip stop
  counting for the MVP.
- **This moves development from Flutter web to a real Android phone build**
  (background GPS, geofence, BLE). Maps SDK Android is already in the key's
  allowed APIs; Android has been unused so far.
- Walking mode = existing Routes/drive code with `mode=walking`; the
  maneuver strings are the same, so the invariant holds unchanged. NEXT #3
  (real GPS position source) becomes the core of the pivot's mobility work.
- Underground dead reckoning: defer until the geofence path works on BTS
  (elevated, GPS fine); MRT stations also have Wi-Fi the fused provider uses.

**Round 4 (same day) — Error Guard = "One-Tap Clipboard Guard"** (addendum
D): no caregiver-permission layer (the LD user operates the app alone); no
screenshot-and-recheck loop (cognitive load). Instead: AI extracts amount /
account number → one-tap **Copy** buttons → user pastes in the bank app, so
digits are never typed (transposition prevented, not detected). Final
wording (same day) = three bullets: One-Tap Clipboard Guard / Conflict &
Uncertainty Alert (blurry or ambiguous field → "check against the photo
before copying") / Human Confirmation & History. **Background clipboard
monitoring was dropped** after Claude flagged it is impossible on Android
10+ / iOS 14+ (only the focused app may read the clipboard). The
Uncertainty Alert needs per-field confidence from the OCR/LLM step — ask
for it in the structured output from day one. Also feasible: copy in
the exact format the bank field expects (digits only vs dashed), show the
number in large grouped digits + TTS read-back on copy, and an optional
in-app "paste here to compare" check. Even lower load for Thai bills: point
the user to the bill's **PromptPay QR** so the bank app scans it and no
number is handled at all.

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
  mock BLE. Cue ladder per turn (**v2, wrist-tested 2026-09-08**): urgency
  is encoded as TAP RATE, not strength — `ProximityPulser` taps every
  4 s / 2 s / 1 s / 0.5 s inside 250 / 150 / 80 / 40 m (intensity 0.54 →
  0.94); PREP is its own constant (0.42), never below the wearer's floor.
  Arrival = gentle pulse on BOTH wrists (never used for turns). Start requires both bands connected ("Connect & start" dialog);
  mid-drive disconnect suppresses cues + shows a banner. GitHub issue #4.

## NEXT (in priority order)

> Updated 2026-10-10. Items 0a-0c follow the proposed pivot and do not need
> the open decisions; the original list continues from 1.

0a. **Commit the work sitting uncommitted since 2026-09-09** on branch
    `restructure/single-repo`: MAX30102 v3 sketch + `firmware/tools/sim_ppg.py`,
    the user's MPU-6050 sketch, `media/simulator.html`, the pivot spec, and
    CLAUDE.md/README edits. (Ask the user before committing — their call.)
0b. **Run MAX30102 v3 on hardware** (fingertip, then inner wrist with
    `WRIST_MODE 1`) and record results in `firmware/MEASUREMENTS.md`.
0c. **Wrist-flick detector** → `firmware/test/gesture_test` (log gyro to find
    the roll axis + peak threshold, Python bench, then on-board detector),
    per addendum C of the pivot spec.

1. **Device #9 — BLE protocol contract** (`firmware/PROTOCOL.md`: UUIDs +
   7-byte packet). Needs NO hardware; unblocks the whole device track
   (#10–#12). Design it grilling-style with the user. Under the pivot it must
   be **two-way** (band → phone: gesture, button, HR window + quality flag,
   battery) and must define the full haptic vocabulary once (per-wrist turn
   stages + both-wrist arrival / hop-off / missed-stop).
2. **AI decision** — 5 proposals await the user (see Pending decisions).
3. **Real GPS drive mode** — swap the simulated position for a geolocator
   stream projected onto the route via `RoutePath.project` (engine already
   built for this); plus off-route re-routing (state exists, no detection UI).
   Under the pivot this becomes walking mode + the Transit Hop-off Guard
   (geofence 300-500 m before the target stop) and needs an Android build.
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

## Hardware measured 2026-09-08 — six app bugs found, five closed

The wristband hardware works end to end (ESP32-C3 + AH024 over PWM). Measuring
it on a real wrist produced one number that invalidates several app defaults:

**Perception floor = PWM duty 135 / 255 = intensity 0.53.** Below that the
motor is not weak, it is *silent*. Full record + method in
[`firmware/MEASUREMENTS.md`](firmware/MEASUREMENTS.md) (n=1, medium confidence).

Everything below sends the band a value it physically cannot render:

| Bug | Status |
|---|---|
| Calibration levels 1-2 were 0.30 / 0.475 — silent | ✅ levels now span 0.0-1.0 (duty 135-255) |
| `mapPattern` marked "mapped" when the packet was merely *sent* | ✅ the wearer's tap IS the measurement now |
| The assessment could hand mild-LD users a profile under the floor | ✅ clamped at play time by `floorIntensity` |
| PREP was intensity × 0.5, arithmetically below the floor | ✅ PREP is its own tested constant (0.42) |
| `hapu_ema` clamped at 0.1 — could tune a band to silence | ✅ clamps at the wearer's measured floor |
| Settings slider starts at 0.1, ~48% of it inert | 🟠 **still open** — output is clamped so nothing goes silent, but the control still lies about its range |

**Two different floors, do not conflate them.** The HARDWARE floor (135) is
what the motor physically cannot go below — that belongs to firmware. The
PERSONAL floor is what a given wearer can feel, which sits at or above it and
is now measured by the Test Vibration screen into
`VibrationProfile.floorIntensity` (default 0.42 = duty 185, the weakest level
confirmed usable). The app never asks for less than the personal floor; the
firmware maps whatever it asks for onto the motor's range —

```
duty = FLOOR + intensity × (255 − FLOOR)
```

The app keeps sending 0.0-1.0. One change kills all six rows, and swapping to
an LRA later means editing one constant. This is decision #1 for `PROTOCOL.md`.

Longer term `FLOOR` must be per-user, not a constant: the Test Vibration screen
(`calibration_controller.dart`) already exists for exactly this and should
*measure* it rather than assume it.

**Cue patterns v2** (now IN the app — `proximity_pulser.dart` +
`haptic_cue_player.dart`):
v1 encoded urgency in amplitude and failed a blind test — the usable range is
only 135-255 and skin resolves 2-3 steps in it. v2 encodes urgency in **pulse
count** (PREP 1 tap / ALERT 2 / NOW 4 fast). Blind re-test still pending.

**Sensor I2C pins decided 2026-09-08 (#13 groundwork):** GY-MAX30102 and
MPU-6050 share one I2C bus on **SDA=GPIO6 / SCL=GPIO7** (moved off the board
default GPIO8/9 = LED/BOOT). Powered from the 3.3 pin, never 5V (C3 GPIOs are
not 5V-tolerant and the module pull-ups follow VIN). Smoke test:
`firmware/test/max30102_test` **v3 (2026-09-09)**: I2C scan → part ID 0x15 →
two independent HR estimators side by side (`beat` = adaptive per-beat
detector, `win` = 4 s autocorrelation with a red-vs-IR quality gate), both
gated on skin contact. SparkFun lib used for I2C/FIFO only; its
`heartRate.h` was dropped (no contact gate, no refractory, never resets).
Algorithms validated on a synthetic PPG in Python (20 cases, `win` never
wrong when it answers); compiles against esp32 core 3.3.11 + SparkFun
MAX3010x 1.1.2; **not yet run on hardware**. Full wiring + screen legend in
`firmware/README.md`. The **MPU-6050 is also wired** on the same bus (user's
raw-reading sketch `firmware/test/mpu-6050/Test-Mpu.ino`, Adafruit_MPU6050
lib; folder ≠ file name, so rename before opening in the Arduino IDE).

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
- **🔴 2026-10-20: the Maps key `…mhLsvg` was DELETED by the user** before
  making the repo public. Verified dead: Directions + Places both return
  `REQUEST_DENIED — This API project was not found` (the Maps key lived in a
  different Google Cloud project from Firebase, and that project or key is
  gone). Firebase is unaffected (Firestore 403 by rules, Auth OK).
- **New Maps key (same day) — ends `…Rbhs`, lives ONLY in `app/.env`**
  (gitignored; template `app/.env.example` is committed). Created in the
  Google Cloud project **"Sense-Safe"** (separate from Firebase — never link
  billing to the Firebase project, it would flip Firebase to Blaze).
  Restricted: Websites `http://localhost:8090/*` + `http://127.0.0.1:8090/*`;
  APIs Maps JavaScript + Directions + Places. **Before any deploy, add the
  real domain to the key's Websites list** or the map shows
  `RefererNotAllowedMapError`. How it flows: `--dart-define-from-file=.env`
  → `googleMapsApiKey` (`lib/app/maps_config.dart`, no default) →
  `loadGoogleMaps()` (`lib/app/maps_loader*.dart`, web injects the Maps
  `<script>` before `runApp`, 10 s timeout, never blocks startup). The old
  hard-coded `<script>` in `web/index.html` is gone; AndroidManifest holds
  the placeholder `ANDROID_MAPS_KEY_NOT_SET` (make a separate Android-
  restricted key when the Android build starts). Never print or commit the
  key; to put a new one in, copy it to the clipboard and write `app/.env`
  from it without echoing.
- **Old Maps key** (ends `…mhLsvg`, DELETED 2026-10-20) used to be hard-coded
  in `app/web/index.html`, `AndroidManifest.xml` and `maps_config.dart`; it
  still sits in git history, dead. It was **API-restricted** to 4 APIs (Maps JS, Maps SDK Android, Directions,
  Places). On **free trial** (no auto-charge; ฿10 budget alert set). Repo is
  **private**, so committing it is acceptable for now.
  - **Decision 2026-07-17 (user chose)**: key-splitting/restrictions stay
    deferred until there's a public domain — referrer locks are meaningless
    on localhost, Android is unused, and web-service endpoints need a proxy
    anyway (do together with the Gemini proxy). Tracked as issue **#8** with
    the red `launch-blocker` label = the pre-launch checklist.
- **Public-repo audit 2026-10-20** (all 7 remote branches, full history,
  issues/PRs): no `.env`, keystores, private keys, Gemini/Claude/GitHub
  tokens, or personal data (emails/phones/IDs) in files; interview form is a
  blank template. **Only blocker to going public = the Maps key `…mhLsvg`**
  (in history since 2026-06-28, so deleting it from files does not help —
  restrict it by HTTP referrer + Android package/SHA-1, or rotate it). Also
  public on flip: commit author emails (incl. a teammate's student email),
  team names in the report PDF, local paths in `.claude/skills` and
  `.vscode/settings.json`. No LICENSE file.
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
(`flutter run -d web-server --web-port=8090 --dart-define-from-file=.env`;
without `app/.env` the app still runs but maps/routing are off). Always reuse 8090; the skill
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
                           maps_config.dart (key from .env), maps_loader*.dart
                           (web: inject Maps script), app_navigation.dart
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
                           cue_scheduler, route_progress, haptic_cue_player,
                           proximity_pulser (v2 rate ladder), hapu_ema
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

- `flutter analyze` clean; **51 tests** passing (re-verified 2026-10-10).
  Files: `profile_service_test`
  (scoring), `route_maneuver_test` (SAFETY: exhaustive maneuver→wrist),
  `route_progress_test` (geometry), `cue_scheduler_test` (cue order/dedupe),
  `proximity_pulser_test` (v2 distance→tap-rate ladder),
  `hapu_ema_test` (EMA math: exact deltas, convergence, clamps, no-FP-drift),
  `favourite_test` + `recent_trip_test` + `vibration_profile_test`
  (model round-trips), `widget_test` (boot smoke). Run `flutter test`.
- Firmware has no CI. Its checks: compile with the Arduino IDE's bundled CLI
  (`%LOCALAPPDATA%\Programs\Arduino IDE\resources\app\lib\backend\resources\arduino-cli.exe
  compile --fqbn esp32:esp32:esp32c3:CDCOnBoot=cdc <sketch dir>`) and, for the
  MAX30102 algorithms, `python firmware/tools/sim_ppg.py` (target: 0 wrong).

## Git / GitHub

- **Current working branch: `restructure/single-repo`** (all Sept work; not
  yet merged to `main`; last commit 2026-09-08, plus uncommitted work — see
  NEXT 0a).
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
