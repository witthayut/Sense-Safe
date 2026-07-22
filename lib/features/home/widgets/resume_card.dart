import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/recent_trip.dart';

/// One-tap "Resume last route" card (shown when a recent trip exists).
class ResumeCard extends StatelessWidget {
  const ResumeCard({super.key, required this.trip, required this.onTap});

  final RecentTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.sageSoft, width: 1.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.sageSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.replay,
                    size: 24, color: AppColors.sageDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESUME LAST ROUTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      trip.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sageDark,
                ),
                child: const Icon(Icons.arrow_forward,
                    size: 20, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
