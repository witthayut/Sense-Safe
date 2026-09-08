import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_drive/services/proximity_pulser.dart';

void main() {
  group('ProximityPulser — when it stays quiet', () {
    test('says nothing beyond the top rung', () {
      final p = ProximityPulser();
      expect(
        p.onProgress(distanceM: 400, nowMs: 0, maneuverIndex: 0),
        isNull,
      );
      expect(
        p.onProgress(distanceM: 251, nowMs: 10000, maneuverIndex: 0),
        isNull,
      );
    });

    test('hands over to the NOW cue below 20 m', () {
      final p = ProximityPulser();
      // Warm it up on the bottom rung so a stale timer cannot explain the null.
      expect(p.onProgress(distanceM: 30, nowMs: 0, maneuverIndex: 0), isNotNull);
      expect(
        p.onProgress(distanceM: 19, nowMs: 60000, maneuverIndex: 0),
        isNull,
        reason: 'below handoverM the continuous NOW buzz owns the wrist',
      );
    });
  });

  group('ProximityPulser — the ladder', () {
    test('each band reports its own strength', () {
      // A fresh pulser per case: one tap each, no interval interference.
      double? tapAt(double m) =>
          ProximityPulser().onProgress(distanceM: m, nowMs: 0, maneuverIndex: 0);

      expect(tapAt(250), closeTo(0.25, 1e-9)); // duty 165
      expect(tapAt(150), closeTo(0.42, 1e-9)); // duty 185
      expect(tapAt(80), closeTo(0.58, 1e-9)); // duty 205
      expect(tapAt(40), closeTo(0.79, 1e-9)); // duty 230
    });

    test('strength rises monotonically as the turn closes', () {
      final samples = [250.0, 150.0, 80.0, 40.0, 25.0]
          .map((m) => ProximityPulser()
              .onProgress(distanceM: m, nowMs: 0, maneuverIndex: 0)!)
          .toList();

      for (var i = 1; i < samples.length; i++) {
        expect(samples[i], greaterThanOrEqualTo(samples[i - 1]));
      }
    });
  });

  group('ProximityPulser — cadence', () {
    test('holds silence until the band interval has elapsed', () {
      final p = ProximityPulser();
      // 250 m band: one tap every 4 s.
      expect(p.onProgress(distanceM: 240, nowMs: 0, maneuverIndex: 0), isNotNull);
      expect(p.onProgress(distanceM: 240, nowMs: 500, maneuverIndex: 0), isNull);
      expect(p.onProgress(distanceM: 240, nowMs: 3999, maneuverIndex: 0), isNull);
      expect(p.onProgress(distanceM: 240, nowMs: 4000, maneuverIndex: 0),
          isNotNull);
    });

    test('taps get closer together as the bands step down', () {
      int tapsOverTenSeconds(double distanceM) {
        final p = ProximityPulser();
        var taps = 0;
        // Sampled at the drive loop's real 500 ms tick.
        for (var t = 0; t <= 10000; t += 500) {
          if (p.onProgress(
                  distanceM: distanceM, nowMs: t, maneuverIndex: 0) !=
              null) {
            taps++;
          }
        }
        return taps;
      }

      final far = tapsOverTenSeconds(240); // every 4 s
      final mid = tapsOverTenSeconds(140); // every 2 s
      final near = tapsOverTenSeconds(70); // every 1 s
      final closest = tapsOverTenSeconds(35); // every 0.5 s

      expect(far, lessThan(mid));
      expect(mid, lessThan(near));
      expect(near, lessThan(closest));
    });

    test('a new maneuver restarts the beat instead of inheriting it', () {
      final p = ProximityPulser();
      expect(p.onProgress(distanceM: 240, nowMs: 0, maneuverIndex: 0), isNotNull);
      // Same instant, same band — but a different turn, so it must fire again
      // rather than wait out the previous turn's 4 s interval.
      expect(p.onProgress(distanceM: 240, nowMs: 0, maneuverIndex: 1), isNotNull);
    });
  });

  test('a custom ladder overrides the default', () {
    final p = ProximityPulser(ladder: const [
      ProximityBand(withinM: 100, intervalMs: 1000, intensity: 0.5),
    ]);
    expect(p.onProgress(distanceM: 150, nowMs: 0, maneuverIndex: 0), isNull);
    expect(p.onProgress(distanceM: 90, nowMs: 0, maneuverIndex: 0), 0.5);
  });
}
