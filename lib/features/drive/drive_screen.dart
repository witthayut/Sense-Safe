import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/theme.dart';
import '../../models/route_option.dart';
import '../../models/wristband.dart';
import '../../services/ble_controller.dart';
import '../../services/cue_scheduler.dart';
import '../../services/drive_controller.dart';
import '../../widgets/pill_button.dart';

/// Guided drive screen: the simulated car follows the chosen route on the
/// map while the Haptic Engine buzzes the correct wrist ahead of each turn.
/// The big arrow mirrors exactly what the wristbands say, so a passenger (or
/// demo audience) can verify the haptics are correct.
class DriveScreen extends ConsumerStatefulWidget {
  const DriveScreen({super.key, required this.route});

  final RouteOption? route;

  @override
  ConsumerState<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends ConsumerState<DriveScreen> {
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    if (route != null) {
      // Start after the first frame so the provider isn't mutated in build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(driveControllerProvider.notifier).start(route);
      });
    }
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _follow(LatLng position) async {
    final map = _map;
    if (map == null) return;
    try {
      await map.animateCamera(CameraUpdate.newLatLng(position));
    } catch (_) {
      // Map already disposed mid-rebuild — best-effort only.
    }
  }

  void _endDrive() {
    ref.read(driveControllerProvider.notifier).stop();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    if (route == null) {
      // Deep-linked without a route — nothing to drive.
      return Scaffold(
        appBar: AppBar(title: const Text('Drive')),
        body: const Center(child: Text('No route selected.')),
      );
    }

    final drive = ref.watch(driveControllerProvider);
    final ble = ref.watch(bleControllerProvider);

    ref.listen<DriveState>(driveControllerProvider, (prev, next) {
      final pos = next.position;
      if (pos != null && next.status == DriveStatus.driving) _follow(pos);
    });

    final position = drive.position ?? route.points.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  GoogleMap(
                    key: const ValueKey('drive-map'),
                    initialCameraPosition:
                        CameraPosition(target: position, zoom: 16),
                    onMapCreated: (c) => _map = c,
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: route.points,
                        color: AppColors.sageDark,
                        width: 5,
                      ),
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('car'),
                        position: position,
                        flat: true,
                        anchor: const Offset(0.5, 0.5),
                        rotation: drive.bearingDeg,
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    compassEnabled: false,
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: _StatusBar(drive: drive, ble: ble),
                  ),
                ],
              ),
            ),
            if (drive.status == DriveStatus.arrived)
              _ArrivedCard(onDone: _endDrive)
            else
              _GuidanceCard(
                drive: drive,
                onEnd: _endDrive,
                onSpeed: (m) => ref
                    .read(driveControllerProvider.notifier)
                    .setSpeedMultiplier(m),
              ),
          ],
        ),
      ),
    );
  }
}

/// Band connectivity + simulation chips floating over the map.
class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.drive, required this.ble});

  final DriveState drive;
  final BleState ble;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _chip(
              icon: Icons.watch,
              label: 'L',
              ok: ble.left.isConnected,
            ),
            const SizedBox(width: 6),
            _chip(
              icon: Icons.watch,
              label: 'R',
              ok: ble.right.isConnected,
            ),
            const Spacer(),
            _chip(icon: Icons.play_circle_outline, label: 'Simulation', ok: true),
          ],
        ),
        if (!drive.hapticsAvailable &&
            drive.status == DriveStatus.driving) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Wristband disconnected — follow the arrows on screen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _chip({required IconData icon, required String label, required bool ok}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ok ? AppColors.sageDark : AppColors.danger),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ok ? AppColors.ink : AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom guidance card: huge arrow + stage text + progress to the turn.
class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard({
    required this.drive,
    required this.onEnd,
    required this.onSpeed,
  });

  final DriveState drive;
  final VoidCallback onEnd;
  final ValueChanged<double> onSpeed;

  @override
  Widget build(BuildContext context) {
    final next = drive.nextManeuver;
    final d = drive.distanceToNextM;
    final wrist = next?.wrist;

    final (title, hint) = _texts();
    final highlight = drive.lastCue != null &&
        drive.lastCue!.maneuverIndex == drive.nextManeuverIndex &&
        drive.lastCue!.stage == CueStage.now;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: highlight ? AppColors.sageDark : AppColors.sageSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _iconFor(next?.googleType),
                  size: 56,
                  color: highlight ? Colors.white : AppColors.sageDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    if (wrist != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        wrist == Wrist.left
                            ? 'Left wrist buzzes'
                            : 'Right wrist buzzes',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sageDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (next != null && d != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (1 - d / 300).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.surfaceMuted,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.sageDark),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${d.round()} m',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Text(
                'Speed',
                style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
              ),
              const SizedBox(width: 8),
              for (final m in const [1.0, 2.0, 4.0]) ...[
                _speedChip(m),
                const SizedBox(width: 6),
              ],
              const Spacer(),
              SizedBox(
                width: 130,
                child: PillButton(label: 'End drive', onPressed: onEnd),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _speedChip(double m) {
    final selected = drive.speedMultiplier == m;
    return GestureDetector(
      onTap: () => onSpeed(m),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageDark : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${m.toInt()}×',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }

  (String, String) _texts() {
    final next = drive.nextManeuver;
    if (next == null) return ('Follow the road', 'You are on your way');

    final wrist = next.wrist;
    final side = switch (wrist) {
      Wrist.left => 'Turn LEFT',
      Wrist.right => 'Turn RIGHT',
      null => 'Continue',
    };

    final cue = drive.lastCue;
    final onThisTurn =
        cue != null && cue.maneuverIndex == drive.nextManeuverIndex;
    final hint = switch (onThisTurn ? cue.stage : null) {
      CueStage.now => 'Turn NOW',
      CueStage.alert => 'Turn coming up',
      CueStage.prep => 'Get ready…',
      null => next.instruction.isNotEmpty ? next.instruction : 'Coming up',
    };
    return (side, hint);
  }

  IconData _iconFor(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.isEmpty) return Icons.straight;
    final left = t.contains('left');
    if (t.contains('uturn')) return left ? Icons.u_turn_left : Icons.u_turn_right;
    if (t.contains('roundabout')) {
      return left ? Icons.roundabout_left : Icons.roundabout_right;
    }
    if (t.contains('fork')) return left ? Icons.fork_left : Icons.fork_right;
    if (t.contains('ramp')) return left ? Icons.ramp_left : Icons.ramp_right;
    if (t.contains('merge')) return Icons.merge;
    if (t.contains('slight') || t.contains('keep')) {
      return left ? Icons.turn_slight_left : Icons.turn_slight_right;
    }
    if (t.contains('sharp')) {
      return left ? Icons.turn_sharp_left : Icons.turn_sharp_right;
    }
    if (left) return Icons.turn_left;
    if (t.contains('right')) return Icons.turn_right;
    return Icons.straight;
  }
}

class _ArrivedCard extends StatelessWidget {
  const _ArrivedCard({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.sageSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 44, color: AppColors.sageDark),
          ),
          const SizedBox(height: 12),
          const Text(
            'You have arrived',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Both wrists pulsed gently — that always means "arrived".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          PillButton(label: 'Done', onPressed: onDone),
        ],
      ),
    );
  }
}
