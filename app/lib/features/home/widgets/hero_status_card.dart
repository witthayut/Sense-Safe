import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../services/ble_controller.dart';

/// Home hero: sage-gradient wristband status card with L/R battery chips
/// when connected (design "1a Readiness Hero").
class HeroStatusCard extends StatelessWidget {
  const HeroStatusCard({super.key, required this.ble});

  final BleState ble;

  @override
  Widget build(BuildContext context) {
    final connected = ble.bothConnected;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -1),
            end: Alignment(0.7, 1),
            colors: [AppColors.sageDark, AppColors.sageDeep],
          ),
        ),
        child: Stack(
          children: [
            // Decorative flourish circle, clipped top-right.
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                        child: const Icon(Icons.watch,
                            size: 24, color: AppColors.onSage),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connected
                                  ? 'Wristbands connected'
                                  : 'Wristbands not connected',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              connected
                                  ? 'Both bands · HAPU calibrated'
                                  : 'Go to Devices tab to connect',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        connected ? Icons.verified : Icons.bluetooth_disabled,
                        size: 22,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                  if (connected) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroBatteryChip(
                              label: 'LEFT', pct: ble.left.batteryPct),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeroBatteryChip(
                              label: 'RIGHT', pct: ble.right.batteryPct),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBatteryChip extends StatelessWidget {
  const _HeroBatteryChip({required this.label, required this.pct});

  final String label;
  final int? pct;

  @override
  Widget build(BuildContext context) {
    final level = pct ?? 0;
    final icon = level >= 80
        ? Icons.battery_5_bar
        : level >= 50
            ? Icons.battery_4_bar
            : level >= 20
                ? Icons.battery_2_bar
                : Icons.battery_alert;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.onSage),
              const SizedBox(width: 6),
              Text(
                pct != null ? '$pct%' : '--',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
