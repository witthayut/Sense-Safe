import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/survey.dart';
import '../../services/assessment_controller.dart';
import '../../widgets/pill_button.dart';

/// The 6-question assessment. One question per page.
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentControllerProvider);
    final q = kSurveyQuestions[_index];
    final selected = state.answers[_index];
    final total = kSurveyQuestions.length;

    return Scaffold(
      appBar: AppBar(
        leading: _index == 0
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _index--),
              ),
        title: Text('Question ${_index + 1} of $total'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / total,
                    minHeight: 6,
                    backgroundColor: AppColors.line,
                    color: AppColors.sageDark,
                  ),
                ),
                const SizedBox(height: 24),
                Text(q.prompt,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: q.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final isSel = selected == i;
                      return _OptionTile(
                        text: q.options[i].text,
                        selected: isSel,
                        onTap: () => ref
                            .read(assessmentControllerProvider.notifier)
                            .answer(_index, i),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                PillButton(
                  label: _index == total - 1 ? 'See my results' : 'Continue',
                  icon: Icons.arrow_forward,
                  onPressed: selected == null ? null : _next,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageSoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.sageDark : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? AppColors.sageDark : AppColors.inkSoft,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
