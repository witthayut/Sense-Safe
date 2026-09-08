import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/survey.dart';
import '../../services/assessment_controller.dart';
import 'widgets/dimension_card.dart';
import 'widgets/results_footer.dart';
import 'widgets/results_header.dart';
import 'widgets/spatial_profile_card.dart';

/// "Your Results" — design v3: hero spatial-profile card with an overall
/// confidence ring, five dimension cards with status chips, a reassurance
/// callout, and the Done / Retake CTAs.
///
/// [viewOnly] = true when a returning user just wants to *see* their saved
/// profile (opened from Profile): Done pops back instead of continuing into
/// onboarding.
class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key, this.viewOnly = false});

  final bool viewOnly;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _explain(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What this means',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            const Text(
              'Your spatial profile describes which parts of driving '
              'navigation take the most effort for you — like telling left '
              'from right quickly, or judging distances.\n\n'
              'The app uses it to tune your wristband cues: how strong they '
              'buzz, how early they warn you, and their rhythm. Lower '
              'confidence in an area simply means the vibrations do more of '
              'the work there.\n\n'
              'It is not a diagnosis, and it keeps adjusting as you drive.',
              style: TextStyle(
                  color: AppColors.inkSoft, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

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

    final overallPct = (ProfileDimension.values
                .map(profile.confidencePctFor)
                .reduce((a, b) => a + b) /
            ProfileDimension.values.length)
        .round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResultsHeader(
                    onBack: () => _back(context),
                    onExplain: () => _explain(context),
                  ),
                  const SizedBox(height: 18),
                  SpatialProfileCard(profile: profile, overallPct: overallPct),
                  const SizedBox(height: 16),
                  for (final d in ProfileDimension.values) ...[
                    DimensionCard(
                      dimension: d,
                      confidence: profile.confidencePctFor(d),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                  const ReassuranceCallout(),
                  const SizedBox(height: 18),
                  ResultsDoneButton(
                    subtitle: viewOnly
                        ? 'Back to your profile'
                        : 'Save my profile & continue',
                    onPressed: () {
                      if (viewOnly) {
                        _back(context);
                      } else {
                        context.go('/onboarding');
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  ResultsRetakeButton(
                    onPressed: () {
                      ref.read(assessmentControllerProvider.notifier).reset();
                      context.go('/survey');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
