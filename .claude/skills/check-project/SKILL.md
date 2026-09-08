---
name: check-project
description: Run an overall health check on the Haptic Drive project — automated code checks (analyze, tests, format), feature progress vs the phased roadmap, safety-critical review (haptic left/right correctness + BLE), and manual-QA readiness from the test checklist. Produces a Go/No-Go report. Use when the user says "check the project", "check the overall", "project health", "is the project ready", "review the whole project", "where are we", or "overall status".
---

Produce a single, honest **Project Health Report** for Haptic Drive that answers: *Does this app actually work, and is it ready to ship?* Combine automated checks with a structured review, then give a clear Go/No-Go with a prioritized action list.

Project dir: `c:\Users\USER\Desktop\Sense&Safe\app`
Roadmap reference: `c:\Users\USER\Desktop\Sense&Safe\planning\Tech-Plan.md` (Phases 0-6)
Manual QA checklist: `c:\Users\USER\Desktop\Sense&Safe\planning\Test-Checklist.xlsx`

Work through all five sections below in order. Do not skip a section — if a step can't run, record it as **Could not verify** with the reason rather than assuming pass.

---

## Section 1 — Automated code health

Run from the project dir. Capture the real output; never assume green.

```
cd "c:/Users/USER/Desktop/Sense&Safe/app"
flutter pub get
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed .
```

Record for each:
- **pub get** — resolves cleanly? any version conflicts?
- **analyze** — count of errors / warnings / infos. List every *error* (not info) verbatim.
- **test** — how many passed / failed. Name each failing test. (Current suite is small: `test/profile_service_test.dart`, `test/widget_test.dart` — note thin coverage.)
- **format** — files needing formatting (non-blocking, but report).

Also scan for unfinished work:
```
grep -rniE "todo|fixme|hack|xxx" app/lib | head -40
```
Summarize count and call out any in safety-critical files (see Section 3).

## Section 2 — Feature progress vs the roadmap

Map what exists in `lib/` against the 6 phases in the tech plan. Inspect `lib/features/*` and `lib/services/*` to judge each phase **Done / Partial / Not started / Mocked**, with one line of evidence each.

- **Phase 0 Foundations** — theme, router, placeholder screens, Firebase wired (`firebase_options.dart`, `lib/app/`).
- **Phase 1 Auth** — `features/auth/*`, `services/auth_controller.dart`, Firebase Auth.
- **Phase 2 Assessment & profile** — `features/assessment/*`, `services/assessment_controller.dart`, `services/profile_service.dart`, `models/vibration_profile.dart`, `models/survey.dart`. This is the differentiator — check the 6-question survey scoring actually produces a profile.
- **Phase 3 Device pairing (BLE)** — `features/devices/*`, `features/calibration/*`, `services/ble_controller.dart`. **Important:** `flutter_blue_plus` is still commented out in `pubspec.yaml`, so BLE is almost certainly a **mock**. Confirm whether real hardware comms exist or it's simulated, and say so plainly.
- **Phase 4 Maps, routing & Haptic Engine** — `features/routes/*`, `services/directions_*`, `services/location_service.dart`, `services/places_*`. Note the plan recommended **Mapbox** but the code uses **google_maps_flutter** — flag this divergence. **Critical gap to check:** is there a dedicated **Haptic Engine** (maneuver + profile -> which wrist, when, how strong)? The plan calls it "the heart of the product." If there's no `haptic_engine.dart` / equivalent, that is a major finding.
- **Phase 5 Settings, feedback, edge handling** — settings screens, post-drive survey, lost-BLE / GPS-loss / reroute handling.
- **Phase 6 Test & release prep** — test coverage, CI, store assets.

Give an overall "current phase" verdict (e.g., "solidly through Phase 2, Phase 3 mocked, Phase 4 partial").

## Section 3 — Safety-critical review (weight this heaviest)

This app fires cues to a driver. Wrong behavior is dangerous, so these carry more weight than anything cosmetic. Inspect the code and judge each:

1. **Left/right correctness** — trace how a "turn left" maneuver maps to the **left** wrist. Find the place where direction -> wrist is decided. Is there any chance of swap (e.g., L/R band identity not pinned after pairing)? This is the single highest-risk item.
2. **Cue timing** — is lead-time (fire *before* the junction) driven by the user's profile and adjusted for speed? A late cue is unsafe.
3. **BLE reliability** — reconnection after dropout, and whether a **mid-drive disconnect alerts the user** instead of failing silently. Look in `ble_controller.dart`.
4. **Both-bands-required** — does navigation refuse to start (or warn) if only one band is connected?
5. **Background operation** — can cues still fire with the screen off / app backgrounded? (iOS is strict here.)
6. **Disclaimer** — is there a "for guidance, eyes on the road" notice, per the plan's safety note?

For each, state: implemented / partial / missing / can't tell from code, with the file as evidence.

## Section 4 — Manual-QA readiness

Open `planning/Test-Checklist.xlsx` (use the `xlsx` skill or `extract-text`). Read the **summary** sheet and report:
- total cases, Pass / Fail / Blocked / not-yet-tested
- **Critical-not-yet-passed** count (the Go/No-Go gate)

If the checklist is empty/untested, say so and treat manual QA as **not started** — automated checks alone do not prove the app works in real use, especially the haptic and on-road behavior that only manual/UAT testing covers.

## Section 5 — Verdict & report

Score each area Green / Yellow / Red:
- Code health (Section 1)
- Feature completeness vs roadmap (Section 2)
- Safety-critical (Section 3) — **any Red here forces an overall No-Go**
- QA readiness (Section 4)

**Go/No-Go rule:** No-Go if any safety-critical item is missing/unverified, if there are analyze *errors* or failing tests, or if any **Critical** checklist case is unpassed. Otherwise Go-with-caveats or Go.

Write the report to `c:\Users\USER\Desktop\Sense&Safe\Project_Health_Report_<YYYY-MM-DD>.md` with this shape, then present it to the user:

```
# Haptic Drive — Project Health Report (<date>)
## Verdict: GO / NO-GO  — one-line reason
## Scorecard: Code [G/Y/R]  Features [..]  Safety [..]  QA [..]
## 1. Code health      (analyze/test/format results)
## 2. Feature progress (phase-by-phase table)
## 3. Safety-critical  (the 6 items, weighted)
## 4. QA readiness     (checklist summary)
## 5. Top priorities   (ranked, safety first — each: what / why / where)
```

Keep findings concrete and file-anchored. Lead with the most important problem. Be honest about gaps — a falsely green report on a driving-safety app is worse than useless.

## Notes / conventions
- Read-only by default: this skill **reviews**, it does not fix. Only change code if the user explicitly asks after seeing the report.
- `flutter analyze` / `flutter test` can take a minute on first run; let them finish rather than timing out early.
- If `flutter` isn't on PATH in the shell, report that as a blocker for Section 1 and still complete Sections 2-4 from the source files.
- Re-run this skill anytime to track progress; each report is dated so you can compare over time.
