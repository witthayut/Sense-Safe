import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wristband.dart';
import 'ble_controller.dart';

/// How many calibration pulses ("patterns") the user maps per wrist.
const int kCalibrationPatternCount = 5;

/// Per-wrist "cold-start" calibration state.
///
/// During calibration the user taps each pulse and confirms they feel it; the
/// felt pulses get added to the wrist's [mappedFor] set. When every pattern is
/// mapped the wrist is ready and "Finish Setup" unlocks.
class CalibrationState {
  const CalibrationState({
    this.leftMapped = const {},
    this.rightMapped = const {},
  });

  /// Indices (0..[kCalibrationPatternCount]-1) of patterns mapped on each side.
  final Set<int> leftMapped;
  final Set<int> rightMapped;

  Set<int> mappedFor(Wrist wrist) =>
      wrist == Wrist.left ? leftMapped : rightMapped;

  int countFor(Wrist wrist) => mappedFor(wrist).length;

  /// 0.0 .. 1.0 — share of patterns mapped for this wrist.
  double progressFor(Wrist wrist) =>
      countFor(wrist) / kCalibrationPatternCount;

  bool isCompleteFor(Wrist wrist) =>
      countFor(wrist) >= kCalibrationPatternCount;

  CalibrationState copyWith({Set<int>? leftMapped, Set<int>? rightMapped}) {
    return CalibrationState(
      leftMapped: leftMapped ?? this.leftMapped,
      rightMapped: rightMapped ?? this.rightMapped,
    );
  }
}

/// Drives the cold-start calibration flow.
///
/// Owns the calibration *state*; the actual buzz is delegated to
/// [BleController] so this layer stays hardware-agnostic. In Phase 3 the only
/// thing that changes is what `testVibration` does under the hood.
class CalibrationController extends Notifier<CalibrationState> {
  @override
  CalibrationState build() => const CalibrationState();

  /// Each pattern is felt at a progressively stronger intensity so the user
  /// learns to distinguish the range. 0 -> soft, last -> full strength.
  double intensityForPattern(int patternIndex) {
    if (kCalibrationPatternCount <= 1) return 1.0;
    final t = patternIndex / (kCalibrationPatternCount - 1);
    return (0.3 + t * 0.7).clamp(0.0, 1.0);
  }

  /// Fire the pulse for [patternIndex] on [wrist] and, if it actually buzzed,
  /// mark it mapped. Returns false when the band isn't connected (so the UI
  /// can prompt the user to connect first); the pattern stays unmapped.
  Future<bool> mapPattern(Wrist wrist, int patternIndex) async {
    if (patternIndex < 0 || patternIndex >= kCalibrationPatternCount) {
      return false;
    }

    final ok = await ref.read(bleControllerProvider.notifier).testVibration(
          wrist,
          intensity: intensityForPattern(patternIndex),
        );
    if (!ok) return false;

    final updated = {...state.mappedFor(wrist), patternIndex};
    state = wrist == Wrist.left
        ? state.copyWith(leftMapped: updated)
        : state.copyWith(rightMapped: updated);
    return true;
  }

  /// Clear the mapped patterns for one wrist (used by "start over").
  void resetFor(Wrist wrist) {
    state = wrist == Wrist.left
        ? state.copyWith(leftMapped: const {})
        : state.copyWith(rightMapped: const {});
  }
}

final calibrationControllerProvider =
    NotifierProvider<CalibrationController, CalibrationState>(
        CalibrationController.new);
