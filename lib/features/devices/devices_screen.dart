import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/wristband.dart';
import '../../services/ble_controller.dart';
import '../../widgets/band_tile.dart';
import '../../widgets/pill_button.dart';
import 'waiting_screen.dart';

/// Devices tab — BLE status for both wristbands + a quick test pulse.
///
/// Three states map to the Figma frames:
///  - disconnected → tile list (red status) + "Connect"
///  - waiting (scanning/connecting) → [WaitingScreen]
///  - connected → "paired & connected" banner + tile list (green status,
///    battery/signal) + "Disconnect"
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final notifier = ref.read(bleControllerProvider.notifier);

    if (_isMidConnection(ble)) {
      return WaitingScreen(onCancel: notifier.disconnect);
    }

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text('Devices',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              const Text(
                'BLE status for both wristbands and a quick test pulse.',
                style: TextStyle(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),
              if (ble.bothConnected) ...[
                const _ConnectedBanner(),
                const SizedBox(height: 16),
              ],
              BandTile(
                band: ble.left,
                onTest: () => context.push('/calibrate/left'),
              ),
              const SizedBox(height: 14),
              BandTile(
                band: ble.right,
                onTest: () => context.push('/calibrate/right'),
              ),
              const SizedBox(height: 28),
              if (!ble.bothConnected)
                PillButton(
                  label: 'Connect',
                  icon: Icons.bluetooth_searching,
                  onPressed: notifier.scanAndConnect,
                )
              else
                PillButton(
                  label: 'Disconnect',
                  icon: Icons.bluetooth_disabled,
                  filled: false,
                  onPressed: notifier.disconnect,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// True while either band is actively scanning or connecting.
  bool _isMidConnection(BleState ble) {
    bool mid(Wristband b) =>
        b.status == BandStatus.scanning || b.status == BandStatus.connecting;
    return mid(ble.left) || mid(ble.right);
  }
}

/// Green "Both wristbands paired & connected" banner shown when connected.
class _ConnectedBanner extends StatelessWidget {
  const _ConnectedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sageSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.bluetooth_connected, color: AppColors.sageDark, size: 18),
          SizedBox(width: 10),
          Text('Both wristbands paired & connected',
              style: TextStyle(
                  color: AppColors.sageDark, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
