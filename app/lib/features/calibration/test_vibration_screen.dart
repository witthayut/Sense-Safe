import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/wristband.dart';
import '../../services/ble_controller.dart';
import '../../services/calibration_controller.dart';
import '../../widgets/pill_button.dart';

/// Human-friendly label per pulse, from softest to strongest. Parallel to the
/// 5 patterns; purely cosmetic (the intensity ramp lives in the controller).
const List<String> _pulseLabels = ['Soft', 'Light', 'Medium', 'Strong', 'Max'];

/// "Test Vibration" — cold-start calibration for a single wrist.
///
/// Opened from the Devices screen when the user taps "Test" on a band
/// (right band -> right page, left band -> left page).
///
/// Pure presentation: it only reads/watches the providers and calls their
/// methods. All state + the (mock) buzz live in the controllers, so this
/// screen never touches BLE directly.
class TestVibrationScreen extends ConsumerWidget {
  const TestVibrationScreen({super.key, required this.wrist});

  final Wrist wrist;

  bool get _isLeft => wrist == Wrist.left;
  String get _sideLabel => _isLeft ? 'left' : 'right';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calibrationControllerProvider);
    final ble = ref.watch(bleControllerProvider);
    final band = _isLeft ? ble.left : ble.right;

    final mapped = state.mappedFor(wrist);
    final count = state.countFor(wrist);
    final complete = state.isCompleteFor(wrist);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Test Vibration',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('Quick test pulse for $_sideLabel side',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _ConnectionStatus(band: band),
                const SizedBox(height: 18),
                _CalibrationCard(
                  mapped: mapped,
                  count: count,
                  onPulse: (i) => _pulse(context, ref, i),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: complete
                      ? _SuccessBanner(side: _sideLabel)
                      : const SizedBox(width: double.infinity),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PillButton(
                    label: 'Finish Setup',
                    onPressed: complete ? () => _finish(context) : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pulse(BuildContext context, WidgetRef ref, int index) async {
    final ok = await ref
        .read(calibrationControllerProvider.notifier)
        .mapPattern(wrist, index);
    if (ok || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connect the $_sideLabel wristband first'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _finish(BuildContext context) {
    // Return to wherever the test was launched from (Devices); fall back home.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

/// Small "● Connected · 92%" / "Not connected" line above the card.
class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.band});

  final Wristband band;

  @override
  Widget build(BuildContext context) {
    final connected = band.isConnected;
    final color = connected ? AppColors.sageDark : AppColors.danger;
    final text = connected
        ? 'Connected${band.batteryPct != null ? ' · ${band.batteryPct}%' : ''}'
        : 'Not connected — connect the band to test';

    return Row(
      children: [
        Icon(connected ? Icons.circle : Icons.circle_outlined,
            size: 10, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

/// The "Cold-start calibration" card: header + the row of labelled pulse
/// buttons + the progress bar and "x/5 patterns mapped" counter.
class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard({
    required this.mapped,
    required this.count,
    required this.onPulse,
  });

  final Set<int> mapped;
  final int count;
  final ValueChanged<int> onPulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000), // soft drop shadow
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.sageSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.monitor_heart_outlined,
                      size: 22, color: AppColors.sageDark),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cold-start calibration',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Tap each pulse you feel clearly',
                          style: TextStyle(
                              color: AppColors.inkSoft, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < kCalibrationPatternCount; i++) ...[
                  Expanded(
                    child: _PulseButton(
                      label: _pulseLabels[i],
                      mapped: mapped.contains(i),
                      onTap: () => onPulse(i),
                    ),
                  ),
                  if (i < kCalibrationPatternCount - 1)
                    const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: count / kCalibrationPatternCount,
                minHeight: 6,
                backgroundColor: AppColors.surfaceMuted,
                color: AppColors.sageDark,
              ),
            ),
            const SizedBox(height: 12),
            Text('$count/$kCalibrationPatternCount patterns mapped',
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

/// A rounded-square pulse button with an intensity label underneath.
/// Plays a quick scale + glow "buzz" animation when tapped, and turns sage
/// once its pattern is mapped.
class _PulseButton extends StatefulWidget {
  const _PulseButton({
    required this.label,
    required this.mapped,
    required this.onTap,
  });

  final String label;
  final bool mapped;
  final VoidCallback onTap;

  @override
  State<_PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<_PulseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0).then((_) {
      if (mounted) _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final mapped = widget.mapped;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            return Transform.scale(
              scale: 1 + t * 0.16,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sageDark.withValues(alpha: 0.35 * t),
                      blurRadius: 16 * t,
                      spreadRadius: 2 * t,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: AspectRatio(
            aspectRatio: 1,
            child: Material(
              color: mapped ? AppColors.sageSoft : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: _handleTap,
                borderRadius: BorderRadius.circular(18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: mapped
                        ? Border.all(color: AppColors.sageDark, width: 1.4)
                        : null,
                  ),
                  child: Icon(
                    mapped ? Icons.check : Icons.vibration,
                    size: 20,
                    color: mapped ? AppColors.sageDark : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: mapped ? AppColors.sageDark : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

/// Shown once all patterns are mapped, just above "Finish Setup".
class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.side});

  final String side;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.sageSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.sageDark, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'All set — your $side band is calibrated.',
              style: const TextStyle(
                  color: AppColors.sageDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
