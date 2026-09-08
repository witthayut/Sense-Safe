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

  /// PREP sits at the bare perception floor by explicit request — under the
  /// firmware's floor remap, intensity 0.0 IS duty 135, not silence.
  ///
  /// Be aware this is the threshold measured sitting still, arm on a desk,
  /// concentrating. In a moving car — engine buzz, road vibration, a moving
  /// arm, attention on the road — that threshold rises, so PREP may be missed.
  /// If it is, raise this: 0.25 (duty 165, the ladder's first rung) is the
  /// safer starting point.
  static const double prepIntensity = 0.0;

  List<_Pulse> _patternFor(CueStage stage, VibrationProfile profile) {
    final i = profile.intensity.clamp(0.0, 1.0);
    switch (stage) {
      // Two short taps — an announcement, distinct from every single tap the
      // approach ladder fires afterwards.
      case CueStage.prep:
        return const [
          (intensity: prepIntensity, durationMs: 180, gapMs: 140),
          (intensity: prepIntensity, durationMs: 180, gapMs: 0),
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
        return const [(intensity: 1.0, durationMs: 800, gapMs: 0)];
    }
  }

  /// One tap from the approach ladder. Same wrist rules as any other cue.
  Future<void> playApproachTap(Wrist wrist, double intensity) =>
      _ble.pulse(wrist, intensity: intensity, durationMs: 140);

  /// Play a turn cue on one wrist. Fire-and-forget from the engine's tick.
  Future<void> playCue(
    CueStage stage,
    Wrist wrist,
    VibrationProfile profile,
  ) async {
    for (final p in _patternFor(stage, profile)) {
      await _ble.pulse(wrist, intensity: p.intensity, durationMs: p.durationMs);
      if (p.gapMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: p.gapMs));
      }
    }
  }

  /// Arrival: gentle simultaneous pulse on both wrists.
  Future<void> playArrival() async {
    await Future.wait([
      _ble.pulse(Wrist.left, intensity: 0.4, durationMs: 600),
      _ble.pulse(Wrist.right, intensity: 0.4, durationMs: 600),
    ]);
  }
}
