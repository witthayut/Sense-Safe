import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wristband.dart';
import 'assessment_controller.dart';
import 'ble_controller.dart';

/// How many sample strengths the wearer is offered per wrist.
const int kCalibrationPatternCount = 5;

/// The sample strengths, weakest to strongest.
///
/// Deliberately spans the motor's ENTIRE usable range — 0.0 and 1.0 are duty
/// 135 and 255 after the firmware's floor remap. The old scale started at
/// 0.30 and stopped short at both ends, which meant a very sensitive wearer
/// and a very insensitive one both fell outside it and got a meaningless
/// answer.
double calibrationIntensity(int index) =>
    index / (kCalibrationPatternCount - 1); // 0, .25, .5, .75, 1

/// Per-wrist cold-start calibration.
///
/// This screen used to be a checklist: tap all five pulses, unlock Finish,
/// throw the answer away. It now measures something real — the WEAKEST level
/// this person can actually feel — because the perception floor turned out to
/// vary by wearer, strap tightness and motor, and hardcoding one number for
/// everybody is what made several cue levels silent in the first place.
class CalibrationState {
  const CalibrationState({this.leftFloor, this.rightFloor});

  /// Index of the weakest level felt on each wrist, or null if not measured.
  final int? leftFloor;
  final int? rightFloor;

  int? floorFor(Wrist wrist) =>
      wrist == Wrist.left ? leftFloor : rightFloor;

  bool isCompleteFor(Wrist wrist) => floorFor(wrist) != null;

  bool get bothMeasured => leftFloor != null && rightFloor != null;

  /// The value stored on the profile: the HIGHER of the two wrists.
  ///
  /// Conservative on purpose. A cue has to be felt on both sides, so the less
  /// sensitive wrist sets the floor; using the average would leave one wrist
  /// below its own threshold and a turn signal silent on that side.
  double? get floorIntensity {
    final l = leftFloor, r = rightFloor;
    if (l == null || r == null) return null;
    return calibrationIntensity(l > r ? l : r);
  }

  CalibrationState copyWith({
    int? leftFloor,
    int? rightFloor,
  }) =>
      CalibrationState(
        leftFloor: leftFloor ?? this.leftFloor,
        rightFloor: rightFloor ?? this.rightFloor,
      );
}

/// Drives the cold-start calibration flow.
///
/// Owns the calibration *state*; the buzz itself is delegated to
/// [BleController] so this layer stays hardware-agnostic.
class CalibrationController extends Notifier<CalibrationState> {
  @override
  CalibrationState build() => const CalibrationState();

  /// Play level [index] on [wrist] and record it as the weakest level felt
  /// there. Tapping a different level simply replaces the answer, so the
  /// wearer can hunt up and down freely.
  ///
  /// Returns false when the band is not connected, so the UI can say so —
  /// note that a true return means the packet went out, NOT that the wearer
  /// felt anything. Only their tap can mean that, which is exactly why the
  /// tap is the measurement.
  Future<bool> selectFloor(Wrist wrist, int index) async {
    if (index < 0 || index >= kCalibrationPatternCount) return false;

    final ok = await ref.read(bleControllerProvider.notifier).testVibration(
          wrist,
          intensity: calibrationIntensity(index),
        );
    if (!ok) return false;

    state = wrist == Wrist.left
        ? CalibrationState(leftFloor: index, rightFloor: state.rightFloor)
        : CalibrationState(leftFloor: state.leftFloor, rightFloor: index);

    // Once both wrists are known the profile can carry a real floor instead
    // of the shipped default.
    final floor = state.floorIntensity;
    if (floor != null) {
      ref.read(assessmentControllerProvider.notifier).updateTuning(
            floorIntensity: floor,
          );
    }
    return true;
  }

  /// Start over on one wrist.
  void clear(Wrist wrist) {
    state = wrist == Wrist.left
        ? CalibrationState(rightFloor: state.rightFloor)
        : CalibrationState(leftFloor: state.leftFloor);
  }
}

final calibrationControllerProvider =
    NotifierProvider<CalibrationController, CalibrationState>(
        CalibrationController.new);
