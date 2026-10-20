import 'dart:async';

import '../models/vibration_profile.dart';
import '../models/wristband.dart';
import 'ble_controller.dart';
import 'cue_scheduler.dart';

/// One buzz in a pattern: intensity 0..1, buzz length, then a silent gap.
typedef _Pulse = ({double intensity, int durationMs, int gapMs});

/// Translates a cue (stage + the user's profile) into a pulse pattern and
/// plays it on the correct wrist through the BLE controller.
///
/// Patterns:
/// - PREP: one gentle half-intensity pulse — "heads-up".
/// - ALERT: shaped by the profile's rhythm (soft = 1 long, medium = 2,
///   sharp = 3 short pulses) at full profile intensity.
/// - NOW: two strong short pulses regardless of rhythm — a consistent
///   urgency signature.
/// - Arrival: a single soft pulse on BOTH wrists simultaneously — a pattern
///   never used for turns, so it can't be mistaken for a side cue.
class HapticCuePlayer {
  HapticCuePlayer(this._ble);

  final BleController _ble;

  /// All timings and strengths below were tuned on a real wrist 2026-09-08
  /// with firmware/test/turn_approach.
  ///
  /// The taps are long on purpose. A vibration motor needs 50-100 ms to spin
  /// up, so the first pass at 140 ms spent most of every tap accelerating and
  /// never delivered the strength its duty asked for — it read as both "too
  /// weak" and "too short", which turned out to be the same complaint.
  /// Lengthening a tap raises its felt strength at no extra power.

  /// PREP, duty 185. Above the 135 perception floor by a real margin: that
  /// floor was measured sitting still and concentrating, and rises in a
  /// moving car with engine buzz, road vibration and attention on the road.
  static const double prepIntensity = 0.42;

  /// One tap of the approach ladder.
  static const int approachTapMs = 350;

  /// Never let anything go out below the wearer's measured floor: under it a
  /// cue is not gentle, it is silence the app would report as delivered.
  double _atLeastFloor(double v, VibrationProfile profile) =>
      v < profile.floorIntensity ? profile.floorIntensity : v;

  List<_Pulse> _patternFor(CueStage stage, VibrationProfile profile) {
    final i = profile.intensity.clamp(0.0, 1.0);
    switch (stage) {
      // Two short taps — an announcement, distinct from every single tap the
      // approach ladder fires afterwards.
      case CueStage.prep:
        return const [
          (intensity: prepIntensity, durationMs: 300, gapMs: 200),
          (intensity: prepIntensity, durationMs: 300, gapMs: 0),
        ];

      // No longer fired during a drive — ProximityPulser owns the 250-20 m
      // window now. Kept because the Settings screen plays it as the live
      // preview while the user drags the intensity/rhythm controls.
      case CueStage.alert:
        return switch (profile.rhythm) {
          HapticRhythm.soft => [(intensity: i, durationMs: 500, gapMs: 0)],
          HapticRhythm.medium => [
              (intensity: i, durationMs: 220, gapMs: 150),
              (intensity: i, durationMs: 220, gapMs: 0),
            ],
          HapticRhythm.sharp => [
              (intensity: i, durationMs: 140, gapMs: 100),
              (intensity: i, durationMs: 140, gapMs: 100),
              (intensity: i, durationMs: 140, gapMs: 0),
            ],
        };

      // One long unbroken buzz at full power. Deliberately a different
      // TEXTURE from everything else, not just a stronger version of it:
      // taps mean "getting closer", continuous means "turn now".
      case CueStage.now:
        return const [(intensity: 1.0, durationMs: 1500, gapMs: 0)];
    }
  }

  /// One tap from the approach ladder. Same wrist rules as any other cue.
  Future<void> playApproachTap(
    Wrist wrist,
    double intensity,
    VibrationProfile profile,
  ) =>
      _ble.pulse(
        wrist,
        intensity: _atLeastFloor(intensity, profile),
        durationMs: approachTapMs,
      );

  /// Play a turn cue on one wrist. Fire-and-forget from the engine's tick.
  Future<void> playCue(
    CueStage stage,
    Wrist wrist,
    VibrationProfile profile,
  ) async {
    for (final p in _patternFor(stage, profile)) {
      final level = _atLeastFloor(p.intensity, profile);
      await _ble.pulse(wrist, intensity: level, durationMs: p.durationMs);
      if (p.gapMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: p.gapMs));
      }
    }
  }

  /// Arrival: gentle simultaneous pulse on both wrists.
  Future<void> playArrival() async {
    await Future.wait([
      // Lengthened with the rest for the same spin-up reason; strength left
      // gentle on purpose, since arrival is good news, not an instruction.
      _ble.pulse(Wrist.left, intensity: 0.42, durationMs: 900),
      _ble.pulse(Wrist.right, intensity: 0.42, durationMs: 900),
    ]);
  }
}
