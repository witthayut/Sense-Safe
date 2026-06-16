/// Which wrist a band is worn on. Drives left/right turn cues.
enum Wrist { left, right }

enum BandStatus { disconnected, scanning, connecting, connected }

/// A paired haptic wristband.
class Wristband {
  const Wristband({
    required this.wrist,
    required this.name,
    this.status = BandStatus.disconnected,
    this.batteryPct,
  });

  final Wrist wrist;
  final String name;
  final BandStatus status;
  final int? batteryPct;

  bool get isConnected => status == BandStatus.connected;

  String get sideLabel => wrist == Wrist.left ? 'Left' : 'Right';

  Wristband copyWith({BandStatus? status, int? batteryPct}) => Wristband(
        wrist: wrist,
        name: name,
        status: status ?? this.status,
        batteryPct: batteryPct ?? this.batteryPct,
      );
}
