import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/survey.dart';
import '../../models/vibration_profile.dart';
import '../../services/assessment_controller.dart';
import '../../widgets/pill_button.dart';

/// "Your results" — the vibration profile, shown as confidence bars.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(assessmentControllerProvider).profile;

    if (profile == null) {
      // Shouldn't happen in the normal flow, but guard anyway.
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/survey'),
            child: const Text('Take the assessment'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your results')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('SPATIAL TYPE',
                    style: TextStyle(
                        color: AppColors.inkSoft,
                        letterSpacing: 1.2,
                        fontSize: 12)),
                const SizedBox(height: 4),
                Text(profile.spatialType.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Guided by wrist side · distance felt as intensity · '
                  '${profile.rhythm.label.toLowerCase()} rhythm · '
                  '${profile.leadTimeSeconds}s lead time',
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
                const SizedBox(height: 24),
                for (final d in ProfileDimension.values) ...[
                  _DimensionBar(
                    label: d.label,
                    supportPct: profile.supportPctFor(d),
                  ),
                  const SizedBox(height: 18),
                ],
                const SizedBox(height: 8),
                const Text(
                  'Not a diagnosis — just your starting vibration profile. '
                  'You can fine-tune it later.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 24),
                PillButton(
                  label: 'Use this profile',
                  icon: Icons.arrow_forward,
                  onPressed: () => context.go('/onboarding'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    ref.read(assessmentControllerProvider.notifier).reset();
                    context.go('/survey');
                  },
                  child: const Text('Retake the assessment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DimensionBar extends StatelessWidget {
  const _DimensionBar({required this.label, required this.supportPct});

  final String label;
  final int supportPct; // 0..100 — higher = more haptic support

  @override
  Widget build(BuildContext context) {
    final confidence = 100 - supportPct;
    // Higher support need shows warmer; lots of confidence shows green.
    final color = supportPct >= 60
        ? AppColors.warn
        : (supportPct >= 35 ? AppColors.sage : AppColors.sageDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              supportPct >= 50 ? 'needs support' : 'confident',
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: confidence / 100,
            minHeight: 10,
            backgroundColor: AppColors.line,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text('$confidence% confident',
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
      ],
    );
  }
}
