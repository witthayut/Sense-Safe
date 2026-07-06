import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/route_option.dart';

/// Per-badge accent colour + icon for the route cards.
({Color color, IconData icon}) _badgeStyle(RouteBadge badge) => switch (badge) {
      RouteBadge.ldFriendly =>
        (color: AppColors.sageDark, icon: Icons.accessibility_new),
      RouteBadge.fastest => (color: AppColors.warn, icon: Icons.bolt),
      RouteBadge.fewestTurns =>
        (color: AppColors.chartBlue, icon: Icons.turn_slight_right),
      RouteBadge.alternative =>
        (color: AppColors.inkSoft, icon: Icons.alt_route),
    };

/// One selectable route option: badge, description, metrics, duration.
class RouteCard extends StatelessWidget {
  const RouteCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final RouteOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _badgeStyle(option.badge);
    final recommended = option.badge == RouteBadge.ldFriendly;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sageSoft.withValues(alpha: 0.45)
              : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.sageDark : AppColors.line,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            // Accent icon chip.
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(style.icon, color: style.color, size: 24),
            ),
            const SizedBox(width: 12),
            // Label + description + metrics.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          option.badge.label.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: style.color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        const _RecommendedTag(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(option.description,
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.straighten,
                          size: 14, color: AppColors.inkSoft),
                      const SizedBox(width: 4),
                      Text(option.distanceText,
                          style: const TextStyle(
                              color: AppColors.inkSoft, fontSize: 12.5)),
                      const SizedBox(width: 12),
                      const Icon(Icons.turn_slight_right,
                          size: 14, color: AppColors.inkSoft),
                      const SizedBox(width: 4),
                      Text('${option.turns} turns',
                          style: const TextStyle(
                              color: AppColors.inkSoft, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Duration + selection state.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.durationText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.sageDark : AppColors.line,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedTag extends StatelessWidget {
  const _RecommendedTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sageDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'RECOMMENDED',
        style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3),
      ),
    );
  }
}
