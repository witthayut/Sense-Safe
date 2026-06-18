import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/wristband.dart';
import '../../services/ble_controller.dart';
import '../../widgets/pill_button.dart';

/// "Welcome to DriveAssist" — connect the two wristbands before first drive.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Set up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome to DriveAssist',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                const Text(
                  'A few quick steps to personalise your haptic guidance.',
                  style: TextStyle(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 24),
                _BandCard(band: ble.left, ref: ref),
                const SizedBox(height: 12),
                _BandCard(band: ble.right, ref: ref),
                const SizedBox(height: 24),
                if (!ble.bothConnected)
                  PillButton(
                    label: 'Scan & connect wristbands',
                    icon: Icons.bluetooth_searching,
                    onPressed: () =>
                        ref.read(bleControllerProvider.notifier).scanAndConnect(),
                  )
                else
                  PillButton(
                    label: 'Continue',
                    icon: Icons.arrow_forward,
                    onPressed: () => context.go('/home'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BandCard extends StatelessWidget {
  const _BandCard({required this.band, required this.ref});

  final Wristband band;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              band.isConnected ? Icons.watch : Icons.watch_outlined,
              color: band.isConnected ? AppColors.sageDark : AppColors.inkSoft,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(band.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(_statusText(band),
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 13)),
                ],
              ),
            ),
            if (band.isConnected)
              TextButton.icon(
                onPressed: () => context.push(
                    '/calibrate/${band.wrist == Wrist.left ? 'left' : 'right'}'),
                icon: const Icon(Icons.vibration, size: 18),
                label: const Text('Test'),
              ),
          ],
        ),
      ),
    );
  }

  String _statusText(Wristband b) {
    switch (b.status) {
      case BandStatus.disconnected:
        return 'Not connected';
      case BandStatus.scanning:
        return 'Scanning…';
      case BandStatus.connecting:
        return 'Connecting…';
      case BandStatus.connected:
        return 'Connected · ${b.batteryPct ?? '--'}%';
    }
  }
}
