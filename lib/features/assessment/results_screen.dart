import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/survey.dart';
import '../../models/vibration_profile.dart';
import '../../services/assessment_controller.dart';

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
                  _Header(
                    onBack: () => _back(context),
                    onExplain: () => _explain(context),
                  ),
                  const SizedBox(height: 18),
                  _HeroCard(profile: profile, overallPct: overallPct),
                  const SizedBox(height: 16),
                  for (final d in ProfileDimension.values) ...[
                    _DimensionCard(
                      dimension: d,
                      confidence: profile.confidencePctFor(d),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 6),
                  const _ReassuranceCallout(),
                  const SizedBox(height: 18),
                  _DoneButton(
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
                  _RetakeButton(
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onExplain});

  final VoidCallback onBack;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: const SizedBox(
              width: 38,
              height: 38,
              child: Icon(Icons.arrow_back_ios_new,
                  size: 16, color: AppColors.ink),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Your Results',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.white,
          shape: const StadiumBorder(
              side: BorderSide(color: AppColors.sageSoft)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onExplain,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline,
                      size: 13, color: AppColors.sageDeep),
                  SizedBox(width: 5),
                  Text(
                    'What this means?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.sageDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.profile, required this.overallPct});

  final VibrationProfile profile;
  final int overallPct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.onSage, AppColors.background],
          stops: [0, 0.8],
        ),
        border: Border.all(color: AppColors.sageSoft),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: CustomPaint(
              painter: _RingPainter(progress: overallPct / 100),
              child: const Center(
                child: Icon(Icons.person_outline,
                    size: 30, color: AppColors.sageDark),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SPATIAL PROFILE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: AppColors.sageDark,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  profile.spatialType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                const _Tag(
                    icon: Icons.swap_horiz, label: 'Guided by wrist side'),
                const _Tag(
                    icon: Icons.more_horiz,
                    label: 'Distance felt as intensity'),
                _Tag(
                    icon: Icons.show_chart,
                    label: '${profile.rhythm.label} rhythm'),
                _Tag(
                    icon: Icons.schedule,
                    label: '${profile.leadTimeSeconds}s lead time'),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'This profile helps guide the vibration cues built '
                    'for you.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.sageDark,
                      height: 1.4,
                    ),
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

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.sageDark),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

/// Overall-confidence ring: white disc with a sageSoft track and a sageDark
/// progress arc (round caps, starting at 12 o'clock).
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress});

  final double progress; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const stroke = 6.0;
    final radius = (size.shortestSide - stroke) / 2 - 3;

    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.sageSoft,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = AppColors.sageDark,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─── Dimension cards ──────────────────────────────────────────────────────────

class _DimensionCard extends StatelessWidget {
  const _DimensionCard({required this.dimension, required this.confidence});

  final ProfileDimension dimension;
  final int confidence; // 0..100

  static const _subtitles = {
    ProfileDimension.leftRight:
        'Understanding left and right while driving',
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
            child:
                Icon(_icons[dimension], size: 20, color: AppColors.sageDark),
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

// ─── Reassurance callout ──────────────────────────────────────────────────────

class _ReassuranceCallout extends StatelessWidget {
  const _ReassuranceCallout();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.onSage,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: DecoratedBox(
              decoration:
                  BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.verified_user_outlined,
                  size: 18, color: AppColors.sageDark),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              "These results aren't a diagnosis — just your starting "
              'vibration profile. You can fine-tune it anytime.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.ink, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CTAs ─────────────────────────────────────────────────────────────────────

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.subtitle, required this.onPressed});

  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sageDark,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 15, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetakeButton extends StatelessWidget {
  const _RetakeButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh, size: 15, color: AppColors.sageDark),
              SizedBox(width: 8),
              Text(
                'Retake the assessment',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sageDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
