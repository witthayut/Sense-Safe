import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// "Connecting Devices…" screen — shown while [BleController] is mid
/// scan/connect. Matches the Figma 'waiting' frame: spinner, paired
/// wristband illustration, status copy, and a cancel action.
///
/// This is not a separate go_router route — DevicesScreen swaps this
/// in place of the tile list whenever the bands are mid-connection, so
/// it lives inside the same /home → Devices tab.
class WaitingScreen extends StatelessWidget {
  const WaitingScreen({super.key, required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.sageDark,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Connecting Devices...',
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 36),
            const _PairedBandsIllustration(),
            const SizedBox(height: 36),

            Text(
              'Waiting for wristbands to connect...',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Scanning for available devices...',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.sageDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onCancel,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sage,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: const Text(
                  'Cancel pairing',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple L/R wristband pair illustration with a pulsing connect motif.
/// Drawn with CustomPaint so no external image assets are required.
class _PairedBandsIllustration extends StatelessWidget {
  const _PairedBandsIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      width: 220,
      child: CustomPaint(painter: _PairedBandsPainter()),
    );
  }
}

class _PairedBandsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bandPaint = Paint()..color = AppColors.sageSoft;
    final outlinePaint = Paint()
      ..color = AppColors.sageDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final wavePaint = Paint()
      ..color = AppColors.sage.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    void drawBand(double cx, String label) {
      final rect = Rect.fromCenter(center: Offset(cx, 65), width: 70, height: 92);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(36));
      canvas.drawRRect(rrect, bandPaint);
      canvas.drawRRect(rrect, outlinePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, 65 - textPainter.height / 2),
      );
    }

    final leftX = size.width * 0.32;
    final rightX = size.width * 0.68;

    drawBand(leftX, 'L');
    drawBand(rightX, 'R');

    // Outward "signal" arcs on the outside of each band.
    canvas.drawArc(
      Rect.fromCircle(center: Offset(leftX - 50, 65), radius: 18),
      -0.9,
      1.8,
      false,
      wavePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(leftX - 50, 65), radius: 30),
      -0.9,
      1.8,
      false,
      wavePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(rightX + 50, 65), radius: 18),
      math.pi - 0.9,
      1.8,
      false,
      wavePaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: Offset(rightX + 50, 65), radius: 30),
      math.pi - 0.9,
      1.8,
      false,
      wavePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}