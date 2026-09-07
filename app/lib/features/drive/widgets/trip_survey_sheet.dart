import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../models/trip_survey.dart';
import '../../../widgets/pill_button.dart';

/// Post-trip Quick Survey (report §3.3): 5 questions, big tappable choices,
/// friendly defaults so one tap on Submit is always valid, and skippable.
/// Pops with a [TripSurvey] on submit, or null on skip/dismiss.
class TripSurveySheet extends StatefulWidget {
  const TripSurveySheet({super.key});

  @override
  State<TripSurveySheet> createState() => _TripSurveySheetState();
}

class _TripSurveySheetState extends State<TripSurveySheet> {
  bool _missedTurns = false;
  SurveyTiming _timing = SurveyTiming.justRight;
  SurveyStrength _strength = SurveyStrength.justRight;
  bool _confusing = false;
  int _comfort = 4;

  void _submit() {
    Navigator.of(context).pop(TripSurvey(
      missedTurns: _missedTurns,
      timing: _timing,
      strength: _strength,
      confusing: _confusing,
      comfort: _comfort,
      at: DateTime.now(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'How was your drive?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '5 quick taps — this tunes your wristbands for next time.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                  const SizedBox(height: 18),

                  _Question(
                    label: 'Did you make every turn?',
                    child: _ChipRow<bool>(
                      options: const [(false, 'All of them'), (true, 'Missed some')],
                      selected: _missedTurns,
                      onSelect: (v) => setState(() => _missedTurns = v),
                    ),
                  ),
                  _Question(
                    label: 'Cue timing?',
                    child: _ChipRow<SurveyTiming>(
                      options: [
                        for (final t in SurveyTiming.values) (t, t.label),
                      ],
                      selected: _timing,
                      onSelect: (v) => setState(() => _timing = v),
                    ),
                  ),
                  _Question(
                    label: 'Vibration strength?',
                    child: _ChipRow<SurveyStrength>(
                      options: [
                        for (final s in SurveyStrength.values) (s, s.label),
                      ],
                      selected: _strength,
                      onSelect: (v) => setState(() => _strength = v),
                    ),
                  ),
                  _Question(
                    label: 'Any confusing moment?',
                    child: _ChipRow<bool>(
                      options: const [(false, 'No'), (true, 'Yes')],
                      selected: _confusing,
                      onSelect: (v) => setState(() => _confusing = v),
                    ),
                  ),
                  _Question(
                    label: 'Overall comfort',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () => setState(() => _comfort = star),
                            icon: Icon(
                              star <= _comfort ? Icons.star : Icons.star_border,
                              size: 32,
                              color: star <= _comfort
                                  ? AppColors.warn
                                  : AppColors.line,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),
                  PillButton(label: 'Submit', onPressed: _submit),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Skip'),
                    ),
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

class _Question extends StatelessWidget {
  const _Question({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// A row of equally-sized big choice chips (same style as Settings' rhythm
/// picker) — records `(value, label)` pairs, one always selected.
class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (value, label) in options) ...[
          Expanded(
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected == value
                        ? AppColors.sageDark
                        : AppColors.inkSoft,
                  ),
                ),
              ),
              selected: selected == value,
              selectedColor: AppColors.sageSoft,
              backgroundColor: AppColors.surfaceMuted,
              showCheckmark: false,
              onSelected: (_) => onSelect(value),
            ),
          ),
          if (value != options.last.$1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
