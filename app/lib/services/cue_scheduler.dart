import '../models/route_maneuver.dart';
import '../models/wristband.dart';

/// The escalation stages of a turn cue, in increasing urgency.
enum CueStage {
  /// Early heads-up (~300 m out): "a turn is coming".
  prep,

  /// The main cue, timed from the profile's lead-time: "turn soon".
  alert,

  /// Final cue (~30 m): "turn NOW".
  now,
}

/// A maneuver planned onto the route: the maneuver plus where it sits along
/// the path (metres from the start).
class PlannedManeuver {
  const PlannedManeuver({required this.maneuver, required this.alongM});
  final RouteManeuver maneuver;
  final double alongM;

  Wrist? get wrist => maneuver.wrist;
}

/// A cue the scheduler decided must fire.
class FiredCue {
  const FiredCue({
    required this.stage,
    required this.wrist,
    required this.maneuverIndex,
    required this.distanceM,
  });

  final CueStage stage;
  final Wrist wrist;
  final int maneuverIndex;

  /// Distance to the maneuver when the cue fired (for logs/debug).
  final double distanceM;
}

/// Decides which haptic cues fire as the drive progresses.
///
/// Pure and synchronous so the safety-critical behaviour (correct wrist,
/// correct order, no duplicates, no spam) is fully unit-testable without
/// timers or BLE.
///
/// Rules:
/// - Stages fire once per maneuver, in escalating order.
/// - If several stages become due in one step (e.g. fast simulation), only
///   the MOST urgent fires — the rest are marked done silently, so the user
///   never gets a burst of stale cues.
/// - Maneuvers without an unambiguous side (wrist == null) never produce a
///   haptic cue; they exist only for on-screen display.
class CueScheduler {
  CueScheduler({
    required List<PlannedManeuver> maneuvers,
    required int leadTimeSeconds,
    required double speedMps,
    this.prepM = 300,
    this.nowM = 30,
    this.passedM = 6,
  })  : _maneuvers = List.unmodifiable(maneuvers),
        alertM = (speedMps * leadTimeSeconds).clamp(60.0, 250.0),
        _fired = List.generate(maneuvers.length, (_) => <CueStage>{});

  final List<PlannedManeuver> _maneuvers;

  /// Distance thresholds (metres before the maneuver) per stage.
  final double prepM;
  final double alertM;
  final double nowM;

  /// Once within this distance the maneuver counts as passed.
  final double passedM;

  final List<Set<CueStage>> _fired;
  int _next = 0;

  int get nextManeuverIndex => _next;

  PlannedManeuver? get nextManeuver =>
      _next < _maneuvers.length ? _maneuvers[_next] : null;

  double _thresholdFor(CueStage s) => switch (s) {
        CueStage.prep => prepM,
        CueStage.alert => alertM,
        CueStage.now => nowM,
      };

  /// Advance to [progressM] along the route; returns the cues to fire now
  /// (at most one per maneuver passed through).
  List<FiredCue> onProgress(double progressM) {
    final out = <FiredCue>[];

    while (_next < _maneuvers.length) {
      final m = _maneuvers[_next];
      final d = m.alongM - progressM;

      if (d <= passedM) {
        _next++; // maneuver passed — move on to the next one
        continue;
      }

      final wrist = m.wrist;
      if (wrist != null) {
        // Most-urgent due stage that hasn't fired yet.
        CueStage? due;
        for (final s in [CueStage.now, CueStage.alert, CueStage.prep]) {
          if (d <= _thresholdFor(s) && !_fired[_next].contains(s)) {
            due = s;
            break;
          }
        }
        if (due != null) {
          // Mark this stage and every less-urgent one as done, so a fast
          // approach can't fire a stale PREP after the ALERT already went.
          for (final s in CueStage.values) {
            if (_thresholdFor(s) >= _thresholdFor(due)) _fired[_next].add(s);
          }
          out.add(FiredCue(
            stage: due,
            wrist: wrist,
            maneuverIndex: _next,
            distanceM: d,
          ));
        }
      }
      break; // only ever look at the nearest upcoming maneuver
    }
    return out;
  }
}
