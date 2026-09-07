import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/vibration_profile.dart';

/// Hero card: overall-confidence ring + spatial-profile type + trait tags,
/// fed by the live [VibrationProfile].
class SpatialProfileCard extends StatelessWidget {
  const SpatialProfileCard({
    super.key,
    required this.profile,
    required this.overallPct,
  });

  final VibrationProfile profile;
  final int overallPct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.onSage, AppColors.background],
          stops: [0, 0.8],
        ),
        border: Border.all(color: AppColors.sageSoft),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: CustomPaint(
              painter: _RingPainter(progress: overallPct / 100),
              child: const Center(
                child: Icon(Icons.person_outline,
                    size: 30, color: AppColors.sageDark),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SPATIAL PROFILE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.sageDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.spatialType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const _Tag(
                    icon: Icons.swap_horiz, label: 'Guided by wrist side'),
                const _Tag(
                    icon: Icons.more_horiz,
                    label: 'Distance felt as intensity'),
                _Tag(
                    icon: Icons.show_chart,
                    label: '${profile.rhythm.label} rhythm'),
                _Tag(
                    icon: Icons.schedule,
                    label: '${profile.leadTimeSeconds}s lead time'),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'This profile helps guide the vibration cues built '
                    'for you.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.sageDark,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.sageDark),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overall-confidence ring: white disc with a sageSoft track and a sageDark
/// progress arc (round caps, starting at 12 o'clock).
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 6.0;
    final radius = (size.shortestSide - stroke) / 2 - 3;

    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.sageSoft,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = AppColors.sageDark,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
