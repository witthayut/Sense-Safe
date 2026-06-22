import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/survey.dart';
import '../models/vibration_profile.dart';
import 'profile_service.dart';

class AssessmentState {
  const AssessmentState({
    required this.answers,
    this.profile,
  });

  /// One entry per survey question; null = not yet answered.
  final List<int?> answers;
  final VibrationProfile? profile;

  bool get isComplete => answers.every((a) => a != null);

  AssessmentState copyWith({
    List<int?>? answers,
    VibrationProfile? profile,
    bool clearProfile = false,
  }) {
    return AssessmentState(
      answers: answers ?? this.answers,
      profile: clearProfile ? null : (profile ?? this.profile),
    );
  }
}

/// Tracks survey answers and produces the [VibrationProfile].
class AssessmentController extends Notifier<AssessmentState> {
  final _service = const ProfileService();

  @override
  AssessmentState build() => AssessmentState(
        answers: List<int?>.filled(kSurveyQuestions.length, null),
      );

  void answer(int questionIndex, int optionIndex) {
    final next = [...state.answers];
    next[questionIndex] = optionIndex;
    state = state.copyWith(answers: next);
  }

  /// Score the survey and store the resulting profile.
  VibrationProfile compute() {
    final profile = _service.scoreSurvey(state.answers);
    state = state.copyWith(profile: profile);
    return profile;
  }

  void reset() {
    state = AssessmentState(
      answers: List<int?>.filled(kSurveyQuestions.length, null),
    );
  }
}

final assessmentControllerProvider =
    NotifierProvider<AssessmentController, AssessmentState>(
        AssessmentController.new);
