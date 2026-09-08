/// One rung of the approach ladder: while the turn is within [withinM],
/// tap every [intervalMs] at [intensity].
class ProximityBand {
  const ProximityBand({
    required this.withinM,
    required this.intervalMs,
    required this.intensity,
  });

  /// Active when the remaining distance is at or below this.
  final double withinM;

  /// Gap between taps. Shorter = more urgent.
  final int intervalMs;

  /// 0..1, as the rest of the app expresses strength. The firmware maps this
  /// onto the motor's usable range (see firmware/MEASUREMENTS.md).
  final double intensity;
}

/// Turns "how far to the turn" into an accelerating train of taps.
///
/// WHY RATE AND NOT AMPLITUDE
/// The obvious design — raise the buzz strength smoothly as you approach —
/// cannot work on this hardware. Measured on a real wrist, the motor's usable
/// range is duty 135..255, and skin resolves only two or three steps across
/// it. Ramping over 300 m in 10 m increments would move the duty about 4 per
/// step: far below what anyone can feel, so the whole approach would read as
/// one flat buzz. Worse, a continuous 27-second vibration numbs the skin, so
/// it would feel like it was fading exactly when it should feel urgent.
///
/// Tap RATE has none of those limits. People count rhythm well and compare
/// strengths badly, the silence between taps lets the skin recover, and a
/// motor that is off most of the time costs far less battery. This is the
/// same reason a parking sensor beeps faster instead of louder.
///
/// Pure and synchronous — like [CueScheduler] and [HapuEma] — so the timing
/// can be tested without a car, a timer, or BLE.
class ProximityPulser {
  ProximityPulser({List<ProximityBand>? ladder})
      : _ladder = ladder ?? defaultLadder;

  /// Below this, [CueStage.now] takes over with one continuous buzz. The
  /// pulser deliberately goes quiet so the two never overlap.
  static const double handoverM = 20;

  /// Nearest band first — the lookup takes the first one that matches.
  /// Duty values assume the firmware's floor remap (135 + intensity * 120).
  static const List<ProximityBand> defaultLadder = [
    ProximityBand(withinM: 40, intervalMs: 500, intensity: 0.79), // duty 230
    ProximityBand(withinM: 80, intervalMs: 1000, intensity: 0.58), // duty 205
    ProximityBand(withinM: 150, intervalMs: 2000, intensity: 0.42), // duty 185
    ProximityBand(withinM: 250, intervalMs: 4000, intensity: 0.25), // duty 165
  ];

  final List<ProximityBand> _ladder;

  static const int _never = -1000000;
  int _lastPulseMs = _never;
  int _forManeuver = -1;

  /// The intensity to tap right now, or null for silence.
  ///
  /// [nowMs] is any monotonically rising clock; [maneuverIndex] resets the
  /// cadence so a new turn always starts from a clean beat instead of
  /// inheriting the previous turn's timing.
  double? onProgress({
    required double distanceM,
    required int nowMs,
    required int maneuverIndex,
  }) {
    if (maneuverIndex != _forManeuver) {
      _forManeuver = maneuverIndex;
      _lastPulseMs = _never;
    }

    // Handed over to the NOW cue, or still too far out to say anything.
    if (distanceM < handoverM) return null;

    ProximityBand? band;
    for (final b in _ladder) {
      if (distanceM <= b.withinM) {
        band = b;
        break;
      }
    }
    if (band == null) return null;

    if (nowMs - _lastPulseMs < band.intervalMs) return null;
    _lastPulseMs = nowMs;
    return band.intensity;
  }
}
