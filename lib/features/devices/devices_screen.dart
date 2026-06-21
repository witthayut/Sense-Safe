import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/wristband.dart';
import '../../services/ble_controller.dart';
import 'waiting_screen.dart';

/// Devices tab — pairing status + test vibration for both wristbands.
///
/// Three states map directly to the Figma frames:
///  - devices1 (idle/disconnected) → tile list + "Connect" button
///  - waiting (scanning/connecting) → [WaitingScreen]
///  - devices2 (connected)         → tile list + "Disconnect" button
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final notifier = ref.read(bleControllerProvider.notifier);

    final isConnecting = _isMidConnection(ble);

    if (isConnecting) {
      return WaitingScreen(
        onCancel: notifier.disconnect,
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text('Devices', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            ble.bothConnected
                ? 'Both wristbands paired & connected'
                : 'BLE status for both wristbands and a quick test pulse.',
            style: const TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          _BandTile(
            band: ble.left,
            onTest: () => context.push('/calibrate/left'),
          ),
          const SizedBox(height: 12),
          _BandTile(
            band: ble.right,
            onTest: () => context.push('/calibrate/right'),
          ),
          const SizedBox(height: 24),
          if (!ble.bothConnected)
            FilledButton.icon(
              onPressed: notifier.scanAndConnect,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Connect'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sageDark,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: notifier.disconnect,
              icon: const Icon(Icons.bluetooth_disabled),
              label: const Text('Disconnect'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// True while either band is actively scanning or connecting —
  /// this is the moment the Figma "waiting" frame should be shown.
  bool _isMidConnection(BleState ble) {
    bool mid(Wristband band) =>
        band.status == BandStatus.scanning ||
        band.status == BandStatus.connecting;
    return mid(ble.left) || mid(ble.right);
  }

}

class _BandTile extends StatelessWidget {
  const _BandTile({required this.band, required this.onTest});

  final Wristband band;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              band.isConnected ? Icons.watch : Icons.watch_outlined,
              size: 32,
              color: band.isConnected ? AppColors.sageDark : AppColors.inkSoft,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${band.sideLabel} wristband',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    band.isConnected
                        ? 'Battery ${band.batteryPct ?? '--'}% · signal strong'
                        : 'Not connected',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (band.isConnected)
              const Icon(Icons.check_circle, color: AppColors.sageDark, size: 20)
            else
              const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 20),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: band.isConnected ? onTest : null,
              icon: const Icon(Icons.vibration, size: 18),
              label: const Text('Test'),
            ),
          ],
        ),
      ),
    );
  }
}