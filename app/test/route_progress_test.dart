import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:haptic_drive/services/route_progress.dart';

void main() {
  // A straight path heading due north from Bangkok city centre.
  // 0.01° latitude ≈ 1113 m.
  const start = LatLng(13.7500, 100.5000);
  const mid = LatLng(13.7550, 100.5000);
  const end = LatLng(13.7600, 100.5000);
  final northPath = RoutePath(const [start, mid, end]);

  test('total length of a 0.01°-latitude path is ~1113 m', () {
    expect(northPath.totalM, closeTo(1113, 10));
  });

  test('pointAt walks the path linearly', () {
    final half = northPath.pointAt(northPath.totalM / 2);
    expect(half.latitude, closeTo(13.7550, 0.0002));
    expect(half.longitude, closeTo(100.5000, 0.0000001));
    expect(northPath.pointAt(-5), start);
    expect(northPath.pointAt(999999), end);
  });

  test('bearing of a due-north path is ~0°', () {
    expect(northPath.bearingAt(100), closeTo(0, 1));
  });

  test('project finds the along-distance of a nearby point', () {
    // A point slightly east of the path, level with 1/4 of the way up.
    const probe = LatLng(13.7525, 100.5003);
    final r = northPath.project(probe);
    expect(r.alongM, closeTo(northPath.totalM / 4, 15));
    expect(r.offM, closeTo(32, 8)); // 0.0003° lng ≈ 32 m at this latitude
  });

  test('minM window prevents snapping to the wrong leg of an out-and-back',
      () {
    // North 1113 m, then straight back south over the same coordinates.
    final outAndBack = RoutePath(const [start, end, start]);
    const probe = LatLng(13.7525, 100.5001); // matches both legs equally

    final onWayOut = outAndBack.project(probe);
    expect(onWayOut.alongM, closeTo(278, 20)); // first leg

    final onWayBack = outAndBack.project(probe, minM: 1200);
    expect(onWayBack.alongM, closeTo(2 * 1113 - 278, 25)); // second leg
  });
}
