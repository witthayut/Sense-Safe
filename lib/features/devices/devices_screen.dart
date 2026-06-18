import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/wristband.dart';
import '../../services/ble_controller.dart';

/// Devices tab — pairing status + test vibration for both wristbands.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final notifier = ref.read(bleControllerProvider.notifier);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text('Devices', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            ble.bothConnected
                ? 'Both wristbands paired & connected'
                : 'Connect your wristbands to start',
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
              label: const Text('Scan & connect'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sageDark,
                minimumSize: const Size.fromHeight(52),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: notifier.disconnect,
              icon: const Icon(Icons.bluetooth_disabled),
              label: const Text('Disconnect'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
        ],
      ),
    );
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
