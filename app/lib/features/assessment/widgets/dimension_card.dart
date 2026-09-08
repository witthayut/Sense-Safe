import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/survey.dart';
import '../../../models/vibration_profile.dart';

/// One assessment dimension: icon, title + subtitle, status chip
/// (confidence < 50 → "Needs support", else "Confident"), and a bar.
class DimensionCard extends StatelessWidget {
  const DimensionCard({
    super.key,
    required this.dimension,
    required this.confidence,
  });

  final ProfileDimension dimension;
  final int confidence; // 0..100

  static const _subtitles = {
    ProfileDimension.leftRight: 'Understanding left and right while driving',
    ProfileDimension.distance: 'Estimating how far until the next turn',
    ProfileDimension.signReading: 'Reading navigation text and signs',
    ProfileDimension.hearing: 'Following audio navigation instructions',
    ProfileDimension.attention: 'Staying focused and not easily distracted',
  };

  static const _icons = {
    ProfileDimension.leftRight: Icons.swap_horiz,
    ProfileDimension.distance: Icons.straighten,
    ProfileDimension.signReading: Icons.signpost_outlined,
    ProfileDimension.hearing: Icons.volume_up_outlined,
    ProfileDimension.attention: Icons.adjust,
  };

  @override
  Widget build(BuildContext context) {
    final needsSupport = confidence < 50;
    final statusColor = needsSupport ? AppColors.warn : AppColors.sageDeep;
    final chipFill = needsSupport ? AppColors.warnSoft : AppColors.sageSoft;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.onSage,
              shape: BoxShape.circle,
            ),
            child: Icon(_icons[dimension], size: 20, color: AppColors.sageDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dimension.label,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _subtitles[dimension]!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: chipFill,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        needsSupport ? 'Needs support' : 'Confident',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: confidence / 100,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceMuted,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$confidence% confident',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.inkSoft),
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
