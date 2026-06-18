import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/survey.dart';
import '../../services/assessment_controller.dart';
import '../../widgets/pill_button.dart';

/// The 6-question assessment for users who picked "I'm not sure" at sign-up.
/// One question per page; answers feed the scoring in ProfileService.
class SurveyScreen extends ConsumerStatefulWidget {
  const SurveyScreen({super.key});

  @override
  ConsumerState<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends ConsumerState<SurveyScreen> {
  int _index = 0;

  void _next() {
    if (_index < kSurveyQuestions.length - 1) {
      setState(() => _index++);
    } else {
      ref.read(assessmentControllerProvider.notifier).compute();
      context.go('/results');
    }
  }

  void _back() {
    if (_index > 0) {
      setState(() => _index--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentControllerProvider);
    final q = kSurveyQuestions[_index];
    final selected = state.answers[_index];
    final total = kSurveyQuestions.length;
    final isLast = _index == total - 1;

    return Scaffold(
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CircleBackButton(onTap: _back),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${_index + 1} of $total',
                        style: const TextStyle(
                          color: AppColors.sageDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(q.prompt,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 24),
                      for (var i = 0; i < q.options.length; i++)
                        _OptionTile(
                          text: q.options[i].text,
                          selected: selected == i,
                          onTap: () => ref
                              .read(assessmentControllerProvider.notifier)
                              .answer(_index, i),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: PillButton(
                  label: isLast ? 'Finished' : 'Continue  ›',
                  onPressed: selected == null ? null : _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Floating circular back button (white, soft shadow) from the design.
class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      elevation: 1.5,
      shadowColor: const Color(0x22000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_ios_new,
              size: 16, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected ? AppColors.sageSoft : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.sageDark : AppColors.line,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Radio(selected: selected),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(text, style: const TextStyle(height: 1.35)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom radio dot matching the design's outlined circle.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.sageDark : AppColors.inkSoft,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sageDark,
                ),
              ),
            )
          : null,
    );
  }
}
