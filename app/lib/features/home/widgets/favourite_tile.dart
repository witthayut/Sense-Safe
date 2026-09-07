import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/favourite.dart';

/// A compact favourite tile: tap re-routes, long-press removes.
class FavouriteTile extends StatelessWidget {
  const FavouriteTile({
    super.key,
    required this.favourite,
    required this.onTap,
    required this.onLongPress,
  });

  final Favourite favourite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  IconData get _icon {
    final l = favourite.label.toLowerCase();
    if (l.contains('home') || l.contains('บ้าน')) return Icons.home_outlined;
    if (l.contains('work') || l.contains('งาน')) return Icons.work_outline;
    if (l.contains('school') ||
        l.contains('university') ||
        l.contains('มอ') ||
        l.contains('โรงเรียน')) {
      return Icons.school_outlined;
    }
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon, size: 22, color: AppColors.sageDark),
              const SizedBox(height: 7),
              Text(
                favourite.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown in place of the tiles when the user has no favourites yet.
class NoFavouritesHint extends StatelessWidget {
  const NoFavouritesHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.star_border, color: AppColors.inkSoft, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No favourites yet — search a route, then tap the star to '
              'save it here.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
