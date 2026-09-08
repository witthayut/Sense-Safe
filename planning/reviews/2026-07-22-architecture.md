# Haptic Drive — Architecture Review (2026-07-22)

> ✅ **UPDATE (same day)**: acted on the two top refactor rows — `home_screen`
> 641→191 lines (widgets → `home/widgets/`) and `results_screen` 650→144
> (→ `assessment/widgets/`). Pure widget extraction, no behavior change;
> analyze clean, 42 tests still pass. `drive_screen` (500) left for next time
> it's edited, per convention.

## Overall: 🟢 — no errors, no bugs found, layering verified clean; growth since the last review (07-06) followed the rules. A few screens have grown into split candidates.

**Direct answer to "any errors or bugs?": none found.**
- `flutter analyze`: clean (0 issues)
- `flutter test`: all **42 tests** pass (incl. safety-critical wrist mapping, cue
  scheduling, EMA math)
- Dependency direction: **zero violations** — models import no services/features,
  services import no UI, no screen touches Firestore/HTTP directly, shared
  widgets import no features
- Orphan scan: **no dead files** (placeholder_tab from last review stayed gone)

## What's good (keep doing)
- **The 07-06 cleanup held.** route_screen went 1,007 → 483 lines and stayed
  split; new features (settings, favourites, recents, survey) each landed as
  model + controller + screen in the right folders on day one.
- **Controller consistency**: favourites / recent-trips / assessment all use the
  identical load-on-login / clear-on-logout pattern (verified by grep — one
  auth-listen block each). New code imitates old code — that's how a codebase
  stays learnable.
- **Safety logic still isolated + tested**: wristForManeuver / CueScheduler /
  HapuEma are pure classes with exhaustive tests. HAPU's EMA joined the same
  pattern instead of being buried in a widget.
- Drive feature already has its `widgets/` subfolder (trip_survey_sheet).

## 🟢 Safe to delete
Nothing. No orphans, no dead code found.

## 🟡 Refactor (god files — none urgent, ranked by value)
| File | Size | Recommendation | Risk |
|---|---|---|---|
| `features/assessment/results_screen.dart` | 650 lines, 9 classes | Fresh from the v3 redesign — split private widgets into `assessment/widgets/` (hero_card, dimension_card, ring_painter, ctas) per the established pattern | Low |
| `features/home/home_screen.dart` | 641 lines, 9 classes | Same treatment → `home/widgets/` (hero_status_card, resume_card, recent_trip_card, favourite_tile, search_bar) | Low |
| `features/drive/drive_screen.dart` | 500 lines, 5 classes | Move _GuidanceCard/_StatusBar/_ArrivedCard into the existing `drive/widgets/` | Low |
| `features/assistant/ai_assistant_overlay.dart` | 416 lines, 9 classes | Tam's file; split only if it's touched again (e.g. when Gemini activates) | — |
| `features/routes/route_screen.dart` | 483 lines | State machine + wiring; already split once. Leave it. | — |

These are hygiene, not problems — the ~300-line rule from CLAUDE.md says split
*when touched next*, and none of them hides logic (all pure UI widgets).

## 🟡 Re-categorize / mild duplication
- `favourites_controller` and `recent_trips_controller` are near-identical in
  shape (auth-listen, `_load`, best-effort `_save` to one field of
  `users/{uid}`). Two copies is fine; **if a third list-of-things-per-user
  controller appears** (e.g. tripSurveys reader for HAPU history), extract a
  shared `UserDocListController<T>` base then. Not before — premature
  abstraction costs more than duplication at n=2.
- The io/web `_friendly*` error helpers in the directions fetchers remain
  intentionally separate (different error shapes per platform) — still fine.

## ⚠ Do NOT touch (look duplicated / deletable, are not)
- `directions_fetch.dart` / `places_fetch.dart` + their `_io`/`_web` siblings —
  conditional-import platform pattern (verified stubs unchanged).
- `firebase_options.dart` — generated.
- `firestore.rules` + `firebase.json` at repo root — deployed security config,
  not clutter.

## Architecture notes
- **Separation of concerns: exemplary right now.** Every business rule added
  since the last review (EMA tuning, favourite dedupe, trip recording, route
  detail-path fix) landed in `services/` or `models/`, screens stayed mirrors.
- **Haptic Engine**: unchanged and healthy — decision chain is
  route_maneuver (side) → cue_scheduler (when) → haptic_cue_player (pattern) →
  ble_controller (transport), each testable alone.
- `core/ble_protocol.dart` (tech-plan idea) still doesn't exist — correctly so;
  it becomes real when issue #9 writes PROTOCOL.md and #12 implements it.

## Ranked next steps
1. Nothing blocking — ship features; split `results_screen` / `home_screen`
   widgets opportunistically next time each file is edited.
2. When Gemini activates, split the assistant overlay in the same PR.
3. When a third per-user list controller appears, extract the shared base.
