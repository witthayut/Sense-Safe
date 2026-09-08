import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/wristband.dart';

/// A wristband card used on both the Devices tab and the onboarding "Set up"
/// page: figure avatar + name (+ battery/signal when connected), a status
/// icon, and a "Test Vibration" button (disabled until the band connects).
class BandTile extends StatelessWidget {
  const BandTile({super.key, required this.band, required this.onTest});

  final Wristband band;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final connected = band.isConnected;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _BandAvatar(wrist: band.wrist, connected: connected),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${band.sideLabel} Wristband',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      connected
                          ? 'Battery ${band.batteryPct ?? '--'}% · Signal strong'
                          : 'Not connected',
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(
                connected ? Icons.check_circle : Icons.highlight_off,
                color: connected ? AppColors.sageDark : AppColors.danger,
                size: 22,
                semanticLabel: connected ? 'Connected' : 'Disconnected',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            // Only testable once the band is connected.
            onPressed: connected ? onTest : null,
            icon: const Icon(Icons.bolt, size: 18),
            label: const Text('Test Vibration'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sand,
              foregroundColor: AppColors.ink,
              disabledBackgroundColor: AppColors.surfaceMuted,
              disabledForegroundColor: AppColors.inkSoft,
              elevation: 0,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Square sage tile showing the L/R figure (from assets, with a letter
/// fallback) and a small dot when the band is connected.
class _BandAvatar extends StatelessWidget {
  const _BandAvatar({required this.wrist, required this.connected});

  final Wrist wrist;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    final isLeft = wrist == Wrist.left;
    final asset = 'assets/images/figure_${isLeft ? 'left' : 'right'}.png';

    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 50,
            height: 50,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.sage,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              cacheWidth: 96, // decode small; the tile is ~50px
              // The source PNGs have a dark background; "lighten" against the
              // sage colour turns that background green (no black) while
              // keeping the white figure.
              color: AppColors.sage,
              colorBlendMode: BlendMode.lighten,
              semanticLabel: '${isLeft ? 'Left' : 'Right'} wristband',
              // Until figure_left/right.png are added, show a clean letter.
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  isLeft ? 'L' : 'R',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 20),
                ),
              ),
            ),
          ),
          if (connected)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sageDark, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
