import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/wristband.dart';

class BleState {
  const BleState({required this.left, required this.right});

  final Wristband left;
  final Wristband right;

  bool get bothConnected => left.isConnected && right.isConnected;

  BleState copyWith({Wristband? left, Wristband? right}) =>
      BleState(left: left ?? this.left, right: right ?? this.right);
}

/// Mock BLE layer for Phase 1/2.
///
/// Simulates scanning, connecting, and a "test vibration" pulse for the two
/// wristbands so the whole app is usable without hardware. In Phase 3 this is
/// re-implemented with `flutter_blue_plus` against the real firmware's
/// service/characteristic UUIDs — the rest of the app keeps calling the same
/// methods.
class BleController extends Notifier<BleState> {
  @override
  BleState build() => const BleState(
        left: Wristband(wrist: Wrist.left, name: 'Left wristband'),
        right: Wristband(wrist: Wrist.right, name: 'Right wristband'),
      );

  /// Pretend to scan + connect both bands.
  Future<void> scanAndConnect() async {
    state = state.copyWith(
      left: state.left.copyWith(status: BandStatus.scanning),
      right: state.right.copyWith(status: BandStatus.scanning),
    );
    await Future<void>.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(
      left: state.left.copyWith(status: BandStatus.connecting),
      right: state.right.copyWith(status: BandStatus.connecting),
    );
    await Future<void>.delayed(const Duration(milliseconds: 900));
    state = state.copyWith(
      left: state.left.copyWith(status: BandStatus.connected, batteryPct: 92),
      right: state.right.copyWith(status: BandStatus.connected, batteryPct: 88),
    );
  }

  void disconnect() {
    state = state.copyWith(
      left: state.left.copyWith(status: BandStatus.disconnected),
      right: state.right.copyWith(status: BandStatus.disconnected),
    );
  }

  /// Fire a test vibration on one wrist. Returns false if not connected.
  /// Real implementation: write the vibrate characteristic over BLE.
  Future<bool> testVibration(Wrist wrist, {double intensity = 0.7}) async {
    final band = wrist == Wrist.left ? state.left : state.right;
    if (!band.isConnected) return false;
    // Simulated buzz.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return true;
  }
}

final bleControllerProvider =
    NotifierProvider<BleController, BleState>(BleController.new);
