---
name: check-architecture
description: Review the folder structure and architecture of the Haptic Drive Flutter project — is it well organized, are files in the right category, what overlaps or duplicates, what is dead/orphaned code, and which files are too big. Flags false-positive "duplicates" (platform conditional imports, generated files) that must NOT be deleted. Produces a ranked cleanup plan to reduce complexity. Use when the user says "check architecture", "check structure", "is the structure good", "review folder structure", "what can I delete", "reduce complexity", "ดู architecture", "จัดระเบียบดีไหม", "ไฟล์ไหนทับซ้อน", or "อยู่ผิดหมวดไหม".
---

Review whether the Haptic Drive codebase is **well organized** and report concrete, ranked actions to reduce complexity — **without breaking anything**. This skill is read-only by default: it analyzes and recommends; it only edits files if the user explicitly asks after seeing the report.

Project dir: `c:\Users\USER\Desktop\Sense&Safe\app`
Reference structure: `c:\Users\USER\Desktop\Sense&Safe\planning\Tech-Plan.md` (section 4 "Suggested project structure")

Run every section below from `app/lib`. Base findings on actual command output, not assumption.

---

## Section 1 — Map the structure

```
cd "c:/Users/USER/Desktop/Sense&Safe/app/lib"
find . -name "*.dart" | sort | while read f; do printf "%5s  %s\n" "$(wc -l < "$f")" "$f"; done
```

Note the top-level layout (expected feature-first: `app/ features/ services/ models/ widgets/`). State whether the layout is clear — can you guess each folder's purpose from its name without opening files?

## Section 2 — Dead / orphaned files (safe to delete)

Find files no other file imports (excluding `main.dart`):

```
for f in $(find . -name "*.dart" ! -name "main.dart"); do
  base=$(basename "$f")
  cnt=$(grep -rl "$base" . --include=*.dart | grep -v "^$f$" | wc -l)
  if [ "$cnt" -eq 0 ]; then echo "ORPHAN? $f"; fi
done
```

For each hit, **confirm before recommending deletion**: grep the class/widget name across `lib` to be sure it's truly unused (a file can be referenced by symbol even if the filename isn't). Only then mark it **safe to delete**.
> Known finding: `features/home/placeholder_tab.dart` (class `PlaceholderTab`) has historically shown up here as genuinely unused.

## Section 3 — God files (biggest complexity win)

Flag any file over ~300 lines, and any file holding many classes:

```
find . -name "*.dart" -exec wc -l {} + | sort -rn | head -10
grep -rc "^class " . --include=*.dart | awk -F: '$2>3{print $2"  "$1}' | sort -rn
```

For each, list the classes inside (`grep -nE "class |Widget build" <file>`) and recommend splitting the private widgets into a `features/<name>/widgets/` folder. Order recommendations by line count — the largest file is the highest-value refactor.
> Known finding: `features/routes/route_screen.dart` (~950+ lines, ~13 classes) is the top split candidate.

## Section 4 — Wrong category / inconsistent naming

Look for files that don't belong where they sit, or naming that mixes concepts:

- **controllers vs services:** check `services/` for both `*_controller.dart` (Riverpod state) and `*_service.dart` (IO/data). Mixing two concepts in one folder is a categorization smell — recommend splitting into `controllers/` (or `state/`) and `services/`.
- **widgets in feature files:** reusable widgets buried inside a screen file that other features could use → suggest promoting to `lib/widgets/`.
- **models scattered:** confirm all data classes live under `models/`.
- Compare against the tech plan's section-4 structure; note real divergences (e.g. the plan's `core/` folder for shared utils + BLE protocol constants does not exist — say whether that matters yet).

## Section 5 — Real duplication vs FALSE positives (do not over-delete)

Look for genuinely overlapping logic (two files doing the same job). But first, **exclude these legitimate patterns — they look duplicated but must NOT be deleted:**

- **Platform conditional imports** — a stub file that does `export 'x_web.dart' if (dart.library.io) 'x_io.dart';`. The `_web` and `_io` siblings are required; deleting either breaks that platform. Confirm by reading the stub.
  > In this project: `directions_fetch.dart` + `_io` + `_web`, and `places_fetch.dart` + `_io` + `_web` are this pattern — **leave them alone.**
- **Generated files** — `*.g.dart`, `*.freezed.dart`, `firebase_options.dart`. Never hand-delete; they're regenerated.
- **Barrel/part files** — `part`/`part of` or export-only files.

Only after excluding the above, report any true duplication (e.g. two near-identical helper functions in different files) and recommend merging the canonical one.

## Section 6 — Architecture soundness

Beyond folders, judge the design:
- **Separation of concerns** — do screens (`features/`) stay UI-only and push logic into `services/`/`controllers/`? Flag screens doing direct IO or business logic.
- **The Haptic Engine** — the tech plan calls a dedicated maneuver→wrist→intensity engine "the heart of the product." Check whether haptic decision logic is isolated (e.g. a `haptic_engine.dart`) or scattered across `ble_controller.dart` / `calibration_controller.dart` / `profile_service.dart`. Scattered safety-critical logic is an architecture risk worth calling out.
- **Dependency direction** — models should not import features/services; services should not import UI. Spot-check a few imports.

## Section 7 — Report

Write `c:\Users\USER\Desktop\Sense&Safe\planning\reviews\<YYYY-MM-DD>-architecture.md` and present it. Grade overall **Green / Yellow / Red**, then a ranked action table where every row has: action, why, evidence (file), and **risk** (Safe / Low / Medium). Use these buckets:

```
# Haptic Drive — Architecture Review (<date>)
## Overall: 🟢/🟡/🔴 — one line
## What's good (keep doing)
## 🟢 Safe to delete   (orphans confirmed unused)
## 🟡 Refactor         (god files to split, with target sub-files)
## 🟡 Re-categorize    (wrong folder / naming inconsistency)
## ⚠ Do NOT touch      (conditional-import / generated files that look duplicate)
## Architecture notes  (separation of concerns, haptic engine, deps)
## Ranked next steps   (most complexity reduction first)
```

Lead with the single highest-value change. Keep it honest — "looks fine" is a valid verdict if the structure is genuinely clean.

## Notes / conventions
- Read-only review by default. If the user approves changes, after editing run `flutter analyze` from the project dir to confirm nothing broke, and report the result.
- Never recommend deleting platform `_io.dart` / `_web.dart` siblings, generated files, or `firebase_options.dart`.
- The ~300-line threshold and ">3 classes per file" are heuristics, not hard rules — use judgement and explain why a given file is or isn't a problem.
- Re-run anytime; each report is dated so structure can be compared over time. Pairs with the `check-project` skill (overall health); this one focuses only on structure/architecture.
