import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haptic_drive/models/route_maneuver.dart';
import 'package:haptic_drive/models/wristband.dart';
import 'package:haptic_drive/services/cue_scheduler.dart';

PlannedManeuver planned(String type, double alongM) => PlannedManeuver(
      maneuver: RouteManeuver(
        googleType: type,
        position: const LatLng(0, 0),
        instruction: type,
      ),
      alongM: alongM,
    );

void main() {
  // Profile: leadTime 5 s at 40 km/h (11.11 m/s) → alert at ~55.6 m,
  // clamped up to the 60 m minimum. prep = 300 m, now = 30 m.
  CueScheduler makeScheduler(List<PlannedManeuver> ms) => CueScheduler(
        maneuvers: ms,
        leadTimeSeconds: 5,
        speedMps: 40 / 3.6,
      );

  test('a full drive fires PREP → ALERT → NOW per turn, correct wrists', () {
    final s = makeScheduler([
      planned('turn-left', 800),
      planned('turn-right', 1500),
    ]);

    final fired = <FiredCue>[];
    // Simulate 20 m steps to 1600 m (well past both maneuvers).
    for (var p = 0.0; p <= 1600; p += 20) {
      fired.addAll(s.onProgress(p));
    }

    expect(fired.map((c) => (c.stage, c.wrist, c.maneuverIndex)).toList(), [
      (CueStage.prep, Wrist.left, 0), // ≤300 m before 800
      (CueStage.alert, Wrist.left, 0), // ≤60 m
      (CueStage.now, Wrist.left, 0), // ≤30 m
      (CueStage.prep, Wrist.right, 1),
      (CueStage.alert, Wrist.right, 1),
      (CueStage.now, Wrist.right, 1),
    ]);
  });

  test('cue distances respect the thresholds', () {
    final s = makeScheduler([planned('turn-left', 800)]);
    final fired = <FiredCue>[];
    for (var p = 0.0; p <= 800; p += 10) {
      fired.addAll(s.onProgress(p));
    }
    expect(fired, hasLength(3));
    expect(fired[0].distanceM, lessThanOrEqualTo(300));
    expect(fired[0].distanceM, greaterThan(250));
    expect(fired[1].distanceM, lessThanOrEqualTo(60));
    expect(fired[2].distanceM, lessThanOrEqualTo(30));
  });

  test('a big jump fires only the MOST urgent stage — never a stale burst',
      () {
    final s = makeScheduler([planned('turn-right', 800)]);
    // One step from far away straight to 40 m before the turn:
    final fired = s.onProgress(760);
    expect(fired, hasLength(1));
    expect(fired.single.stage, CueStage.alert);
    expect(fired.single.wrist, Wrist.right);
    // Next step inside 30 m still gets the NOW cue:
    final now = s.onProgress(775);
    expect(now.single.stage, CueStage.now);
    // But PREP never fires afterwards:
    expect(s.onProgress(776), isEmpty);
  });

  test('no stage ever fires twice for the same maneuver', () {
    final s = makeScheduler([planned('turn-left', 500)]);
    final all = <FiredCue>[];
    for (var p = 0.0; p <= 520; p += 5) {
      all.addAll(s.onProgress(p));
    }
    expect(all.where((c) => c.stage == CueStage.prep), hasLength(1));
    expect(all.where((c) => c.stage == CueStage.alert), hasLength(1));
    expect(all.where((c) => c.stage == CueStage.now), hasLength(1));
  });

  test('ambiguous maneuvers (merge/straight) never produce a haptic cue', () {
    final s = makeScheduler([planned('merge', 400), planned('straight', 700)]);
    final fired = <FiredCue>[];
    for (var p = 0.0; p <= 800; p += 10) {
      fired.addAll(s.onProgress(p));
    }
    expect(fired, isEmpty);
  });

  test('passing a maneuver advances to the next one', () {
    final s = makeScheduler([
      planned('turn-left', 300),
      planned('turn-right', 320), // immediately after the first
    ]);
    expect(s.nextManeuverIndex, 0);
    // Within passedM (6 m) of the first → it is passed, and the second turn
    // is only 24 m ahead → its NOW cue fires immediately in the same step.
    // Wrist must be RIGHT (the second maneuver), never the passed one's.
    final fired = s.onProgress(296);
    expect(s.nextManeuverIndex, 1);
    expect(fired.single.wrist, Wrist.right);
    expect(fired.single.stage, CueStage.now);
    // And it never re-fires.
    expect(s.onProgress(297), isEmpty);
  });

  test('alert threshold scales with lead time and clamps to 60–250 m', () {
    double alertFor(int leadS) => CueScheduler(
          maneuvers: [planned('turn-left', 1000)],
          leadTimeSeconds: leadS,
          speedMps: 40 / 3.6,
        ).alertM;

    expect(alertFor(3), 60); // 33 m → clamped up
    expect(alertFor(8), closeTo(88.9, 0.5)); // 11.11 × 8
    expect(alertFor(30), 250); // 333 m → clamped down
  });
}
