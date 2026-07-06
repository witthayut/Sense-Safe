import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haptic_drive/models/route_maneuver.dart';
import 'package:haptic_drive/models/wristband.dart';

/// SAFETY-CRITICAL: the wrist side must derive from Google's maneuver string
/// and nothing else. This exhaustively pins every documented Directions
/// maneuver to its expected wrist (or to "no cue").
void main() {
  const leftManeuvers = [
    'turn-left',
    'turn-slight-left',
    'turn-sharp-left',
    'uturn-left',
    'ramp-left',
    'fork-left',
    'roundabout-left',
    'keep-left',
  ];

  const rightManeuvers = [
    'turn-right',
    'turn-slight-right',
    'turn-sharp-right',
    'uturn-right',
    'ramp-right',
    'fork-right',
    'roundabout-right',
    'keep-right',
  ];

  const neutralManeuvers = [
    'merge',
    'straight',
    'ferry',
    'ferry-train',
    '',
  ];

  test('every left-family maneuver maps to the LEFT wrist', () {
    for (final m in leftManeuvers) {
      expect(wristForManeuver(m), Wrist.left, reason: m);
    }
  });

  test('every right-family maneuver maps to the RIGHT wrist', () {
    for (final m in rightManeuvers) {
      expect(wristForManeuver(m), Wrist.right, reason: m);
    }
  });

  test('ambiguous maneuvers produce NO side cue', () {
    for (final m in neutralManeuvers) {
      expect(wristForManeuver(m), isNull, reason: '"$m"');
    }
  });

  test('mapping is case-insensitive', () {
    expect(wristForManeuver('Turn-Left'), Wrist.left);
    expect(wristForManeuver('TURN-RIGHT'), Wrist.right);
  });

  test('RouteManeuver.wrist delegates to the single mapping function', () {
    const m = RouteManeuver(
      googleType: 'roundabout-right',
      position: LatLng(13.75, 100.5),
      instruction: 'At the roundabout, take the 2nd exit',
    );
    expect(m.wrist, Wrist.right);
  });
}
