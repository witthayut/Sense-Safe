import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'wristband.dart';

/// Which wrist a Google maneuver string maps to.
///
/// SAFETY-CRITICAL: this is the ONLY place in the app allowed to decide
/// left vs right for a haptic cue, and it derives the side purely from
/// Google's maneuver string ("turn-left", "roundabout-right", ...) — never
/// from bearing/geometry math, which can flip near GPS noise. Ambiguous
/// maneuvers (merge, straight, ferry...) return null → no side cue at all;
/// on a safety feature, silence beats guessing.
Wrist? wristForManeuver(String googleType) {
  final t = googleType.toLowerCase();
  if (t.contains('left')) return Wrist.left;
  if (t.contains('right')) return Wrist.right;
  return null;
}

/// One turn-by-turn decision point on a route, parsed from a Google
/// Directions step that carries a `maneuver`.
class RouteManeuver {
  const RouteManeuver({
    required this.googleType,
    required this.position,
    required this.instruction,
  });

  /// Google's raw maneuver string, e.g. "turn-left", "roundabout-right".
  final String googleType;

  /// Where the maneuver happens (the step's start location).
  final LatLng position;

  /// Plain-text instruction for on-screen display ("Turn left onto ...").
  final String instruction;

  /// The wrist to buzz, or null when the maneuver has no unambiguous side.
  Wrist? get wrist => wristForManeuver(googleType);
}
