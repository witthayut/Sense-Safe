import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Pure geometry over a route polyline: cumulative distances, point-at-
/// distance, bearing, and projection of an arbitrary position onto the path.
///
/// All distances are metres. Uses an equirectangular approximation, which is
/// accurate to well under 1% at city scale — plenty for cue thresholds.
class RoutePath {
  RoutePath(List<LatLng> points)
      : assert(points.length >= 2, 'route needs at least 2 points'),
        _pts = List.unmodifiable(points) {
    final cum = List<double>.filled(_pts.length, 0);
    for (var i = 1; i < _pts.length; i++) {
      cum[i] = cum[i - 1] + metersBetween(_pts[i - 1], _pts[i]);
    }
    _cum = cum;
  }

  final List<LatLng> _pts;
  late final List<double> _cum;

  double get totalM => _cum.last;

  static const _mPerDegLat = 111320.0;

  static double metersBetween(LatLng a, LatLng b) {
    final midLatRad = (a.latitude + b.latitude) / 2 * math.pi / 180;
    final dy = (b.latitude - a.latitude) * _mPerDegLat;
    final dx = (b.longitude - a.longitude) * _mPerDegLat * math.cos(midLatRad);
    return math.sqrt(dx * dx + dy * dy);
  }

  /// The point [m] metres along the path (clamped to the ends).
  LatLng pointAt(double m) {
    if (m <= 0) return _pts.first;
    if (m >= totalM) return _pts.last;
    final i = _segmentIndexFor(m);
    final segLen = _cum[i + 1] - _cum[i];
    final t = segLen == 0 ? 0.0 : (m - _cum[i]) / segLen;
    return LatLng(
      _pts[i].latitude + (_pts[i + 1].latitude - _pts[i].latitude) * t,
      _pts[i].longitude + (_pts[i + 1].longitude - _pts[i].longitude) * t,
    );
  }

  /// Compass bearing (0..360°, 0 = north) of the segment at [m] metres along.
  double bearingAt(double m) {
    final i = _segmentIndexFor(m.clamp(0, totalM));
    final a = _pts[i];
    final b = _pts[math.min(i + 1, _pts.length - 1)];
    final midLatRad = (a.latitude + b.latitude) / 2 * math.pi / 180;
    final dy = (b.latitude - a.latitude);
    final dx = (b.longitude - a.longitude) * math.cos(midLatRad);
    final deg = math.atan2(dx, dy) * 180 / math.pi;
    return (deg + 360) % 360;
  }

  /// Projects [p] onto the path and returns how far along it lies (metres),
  /// plus how far off the path it is.
  ///
  /// [minM] restricts the search to at/after that progress — pass the
  /// previous known progress so an out-and-back route can't snap the
  /// projection onto the wrong (returning) leg.
  ({double alongM, double offM}) project(LatLng p, {double minM = 0}) {
    var bestAlong = minM.clamp(0, totalM).toDouble();
    var bestOff = double.infinity;

    for (var i = 0; i < _pts.length - 1; i++) {
      if (_cum[i + 1] < minM) continue; // segment entirely before the window
      final a = _pts[i], b = _pts[i + 1];
      final segLen = _cum[i + 1] - _cum[i];
      if (segLen == 0) continue;

      // Work in a local metre grid around a.
      final midLatRad = a.latitude * math.pi / 180;
      const ax = 0.0, ay = 0.0;
      final bx = (b.longitude - a.longitude) *
          _mPerDegLat *
          math.cos(midLatRad);
      final by = (b.latitude - a.latitude) * _mPerDegLat;
      final px =
          (p.longitude - a.longitude) * _mPerDegLat * math.cos(midLatRad);
      final py = (p.latitude - a.latitude) * _mPerDegLat;

      final segSq = (bx - ax) * (bx - ax) + (by - ay) * (by - ay);
      var t = ((px - ax) * (bx - ax) + (py - ay) * (by - ay)) / segSq;
      t = t.clamp(0.0, 1.0);
      var along = _cum[i] + segLen * t;
      if (along < minM) {
        along = minM; // clamp within the window
        t = ((minM - _cum[i]) / segLen).clamp(0.0, 1.0);
      }
      final qx = ax + (bx - ax) * t, qy = ay + (by - ay) * t;
      final off = math.sqrt((px - qx) * (px - qx) + (py - qy) * (py - qy));

      // Prefer the EARLIEST segment when several are (near-)equally close —
      // an out-and-back route overlaps itself, and floating-point noise must
      // not be what decides which leg the position lands on.
      if (off < bestOff - _tieToleranceM) {
        bestOff = off;
        bestAlong = along;
      }
    }
    return (alongM: bestAlong, offM: bestOff);
  }

  static const _tieToleranceM = 1.0;

  int _segmentIndexFor(double m) {
    var lo = 0, hi = _cum.length - 2;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (_cum[mid] <= m) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo;
  }
}
