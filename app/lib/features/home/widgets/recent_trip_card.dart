import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/recent_trip.dart';

/// A compact recent-trip card (tap re-routes to the destination).
class RecentTripCard extends StatelessWidget {
  const RecentTripCard({super.key, required this.trip, required this.onTap});

  final RecentTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.history, size: 20, color: AppColors.sageDark),
              const SizedBox(height: 8),
              Text(
                trip.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                trip.metaText(DateTime.now()),
                style:
                    const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
