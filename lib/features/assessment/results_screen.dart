import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/survey.dart';
import '../../models/vibration_profile.dart';
import '../../services/assessment_controller.dart';

/// Describes how one dimension is framed on the results bars: the two opposing
/// poles (left = confident framing, right = support-needed framing) + a colour.
class _DimView {
  const _DimView({
    required this.dim,
    required this.leftLabel,
    required this.rightLabel,
    required this.caption,
    required this.color,
  });

  final ProfileDimension dim;
  final String leftLabel; // positive pole (paired with confidence %)
  final String rightLabel; // support-needed pole (paired with support %)
  final String caption;
  final Color color;
}

/// Order + framing copy straight from the design.
const List<_DimView> _dimViews = [
  _DimView(
    dim: ProfileDimension.leftRight,
    leftLabel: 'CONFIDENT',
    rightLabel: 'UNCERTAIN',
    caption: 'Telling left from right',
    color: AppColors.chartBlue,
  ),
  _DimView(
    dim: ProfileDimension.distance,
    leftLabel: 'NUMBER-BASED',
    rightLabel: 'FEEL-BASED',
    caption: 'Judging distance to a turn',
    color: AppColors.warn,
  ),
  _DimView(
    dim: ProfileDimension.signReading,
    leftLabel: 'COMFORTABLE',
    rightLabel: 'EFFORTFUL',
    caption: 'Reading signs on screen',
    color: AppColors.chartGreen,
  ),
  _DimView(
    dim: ProfileDimension.attention,
    leftLabel: 'STEADY FOCUS',
    rightLabel: 'EASILY PULLED',
    caption: 'Attention while driving',
    color: AppColors.chartPink,
  ),
  _DimView(
    dim: ProfileDimension.hearing,
    leftLabel: 'CLEAR',
    rightLabel: 'STRAINED',
    caption: 'Hearing spoken directions',
    color: AppColors.chartPurple,
  ),
];

const List<String> _manualTypes = [
  'Dyspraxia-leaning',
  'Dyscalculia-leaning',
  'Dyslexia-leaning',
  'ADHD-leaning',
  'Balanced profile',
];

/// "Your results" — the computed vibration profile shown as split bars.
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Text('Your results',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: AppColors.sageSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.explore_outlined,
                        size: 38, color: AppColors.sageDark),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text('Spatial Type',
                      style: TextStyle(
                          color: AppColors.sageDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    profile.spatialType.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.inkSoft,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                const _InfoLine(
                    icon: Icons.touch_app_outlined,
                    text: 'Guided by wrist side'),
                const SizedBox(height: 6),
                const _InfoLine(
                    icon: Icons.graphic_eq, text: 'Distance felt as intensity'),
                const SizedBox(height: 20),
                const Divider(color: AppColors.line),
                const SizedBox(height: 16),
                for (final v in _dimViews) ...[
                  _ResultBar(view: v, profile: profile),
                  const SizedBox(height: 20),
                ],
                const SizedBox(height: 4),
                _PrimaryButton(
                  label: 'Use this profile  →',
                  onPressed: () => context.go('/onboarding'),
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    'Not a diagnosis — just your starting vibration profile.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 2),
                Center(
                  child: TextButton(
                    onPressed: () => _pickType(context, ref, profile),
                    child: const Text('Pick a type manually'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickType(
      BuildContext context, WidgetRef ref, VibrationProfile profile) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Pick a type manually',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 4),
                const Text(
                  'Override the suggestion if you already know what fits you.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 12),
                for (final type in _manualTypes)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      type == profile.spatialType
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: type == profile.spatialType
                          ? AppColors.sageDark
                          : AppColors.inkSoft,
                    ),
                    title: Text(type),
                    onTap: () {
                      ref
                          .read(assessmentControllerProvider.notifier)
                          .setSpatialType(type);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.inkSoft),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.inkSoft)),
      ],
    );
  }
}

/// A single dimension's split bar: confident% on the left, support% on the
/// right, with the dominant side coloured in the dimension's accent.
class _ResultBar extends StatelessWidget {
  const _ResultBar({required this.view, required this.profile});

  final _DimView view;
  final VibrationProfile profile;

  @override
  Widget build(BuildContext context) {
    final confident = profile.confidencePctFor(view.dim); // left
    final support = profile.supportPctFor(view.dim); // right
    final leftDominant = confident >= support;

    final leftStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      fontStyle: leftDominant ? FontStyle.italic : FontStyle.normal,
      color: leftDominant ? view.color : AppColors.inkSoft,
    );
    final rightStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      fontStyle: leftDominant ? FontStyle.normal : FontStyle.italic,
      color: leftDominant ? AppColors.inkSoft : view.color,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$confident% ${view.leftLabel}', style: leftStyle),
            Text('${view.rightLabel} $support%', style: rightStyle),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Expanded(
                flex: confident.clamp(1, 100),
                child: Container(
                  height: 11,
                  color:
                      leftDominant ? view.color : AppColors.surfaceMuted,
                ),
              ),
              Expanded(
                flex: support.clamp(1, 100),
                child: Container(
                  height: 11,
                  color:
                      leftDominant ? AppColors.surfaceMuted : view.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(view.caption,
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
      ],
    );
  }
}

/// Full-width sage pill (the "Use this profile" CTA).
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.sage,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
