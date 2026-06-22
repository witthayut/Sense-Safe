import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/wristband.dart';
import '../../services/ble_controller.dart';
import '../../widgets/band_tile.dart';
import '../../widgets/pill_button.dart';
import '../devices/waiting_screen.dart';

/// "Welcome to DriveAssist" — connect the two wristbands before first drive.
/// Uses the same band-tile + connecting design as the Devices tab.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = ref.watch(bleControllerProvider);
    final notifier = ref.read(bleControllerProvider.notifier);

    // While scanning/connecting, show the same "Connecting Devices…" page
    // used on the Devices tab — the connecting step before the connected view.
    if (_isMidConnection(ble)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Set up')),
        body: WaitingScreen(onCancel: notifier.disconnect),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Set up')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                Text('Welcome to DriveAssist',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                const Text(
                  'A few quick steps to personalise your haptic guidance.',
                  style: TextStyle(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 24),
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
                    label: 'Scan & connect wristbands',
                    icon: Icons.bluetooth_searching,
                    onPressed: notifier.scanAndConnect,
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

  /// True while either band is actively scanning or connecting.
  bool _isMidConnection(BleState ble) {
    bool mid(Wristband b) =>
        b.status == BandStatus.scanning || b.status == BandStatus.connecting;
    return mid(ble.left) || mid(ble.right);
  }
}
