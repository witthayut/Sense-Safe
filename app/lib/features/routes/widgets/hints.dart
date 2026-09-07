import 'package:flutter/material.dart';

import '../../../app/theme.dart';

/// Small warn hint shown under the search bar (e.g. autocomplete unavailable).
class InlineHint extends StatelessWidget {
  const InlineHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warn, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.ink, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

/// Shown before any search: prompt to enter a destination.
class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.alt_route, color: AppColors.inkSoft, size: 32),
          SizedBox(height: 10),
          Text(
            'Enter a destination to compare routes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Shown when no API key is configured yet, so the map appears blank.
class ApiKeyHint extends StatelessWidget {
  const ApiKeyHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.key_off_outlined, color: AppColors.warn, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add your Google Maps API key to load the map and routes.',
              style: TextStyle(color: AppColors.ink, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
