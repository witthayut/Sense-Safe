import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/learning_difference.dart';
import '../models/survey.dart';
import '../models/vibration_profile.dart';
import 'auth_controller.dart';
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

/// Tracks survey answers and produces the [VibrationProfile], persisting it to
/// Firestore (`users/{uid}.vibrationProfile`) and reloading it on login.
class AssessmentController extends Notifier<AssessmentState> {
  final _service = const ProfileService();

  AssessmentState get _empty => AssessmentState(
        answers: List<int?>.filled(kSurveyQuestions.length, null),
      );

  @override
  AssessmentState build() {
    // Load the saved profile when a user signs in; clear it on sign-out.
    ref.listen<dynamic>(authControllerProvider, (prev, next) {
      if (next == null) {
        state = _empty;
      } else if (prev?.id != next.id) {
        _loadProfile(next.id as String);
      }
    });
    final current = ref.read(authControllerProvider);
    if (current != null) _loadProfile(current.id);
    return _empty;
  }

  Future<void> _loadProfile(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final profile = VibrationProfile.fromFirestore(
          doc.data()?['vibrationProfile'] as Map<String, dynamic>?);
      if (profile != null) state = state.copyWith(profile: profile);
    } catch (_) {
      // offline / rules — ignore; user can retake the assessment.
    }
  }

  void answer(int questionIndex, int optionIndex) {
    final next = [...state.answers];
    next[questionIndex] = optionIndex;
    state = state.copyWith(answers: next);
  }

  /// Score the survey, store the profile, and save it to Firestore.
  VibrationProfile compute() {
    final profile = _service.scoreSurvey(state.answers);
    state = state.copyWith(profile: profile);
    _save(profile);
    return profile;
  }

  /// Build + store a profile directly from self-declared learning
  /// difference(s) — for users who skip the survey.
  VibrationProfile applyFromLearningDifferences(Set<LearningDifference> diffs) {
    final profile = _service.profileFromLearningDifferences(diffs);
    state = state.copyWith(profile: profile);
    _save(profile);
    return profile;
  }

  /// Settings screen: user fine-tunes intensity / lead time / rhythm.
  /// Starts from a medium default if they never completed an assessment.
  void updateTuning({
    double? intensity,
    int? leadTimeSeconds,
    HapticRhythm? rhythm,
  }) {
    final base = state.profile ??
        const VibrationProfile(
          scores: {},
          intensity: 0.6,
          leadTimeSeconds: 5,
          rhythm: HapticRhythm.medium,
          spatialType: 'Balanced profile',
        );
    final updated = base.copyWith(
      intensity: intensity,
      leadTimeSeconds: leadTimeSeconds,
      rhythm: rhythm,
    );
    state = state.copyWith(profile: updated);
    _save(updated);
  }

  Future<void> _save(VibrationProfile profile) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .set({'vibrationProfile': profile.toFirestore()},
              SetOptions(merge: true));
    } catch (_) {
      // Best-effort; the profile still lives in memory for this session.
    }
  }

  void reset() {
    state = _empty;
  }
}

final assessmentControllerProvider =
    NotifierProvider<AssessmentController, AssessmentState>(
        AssessmentController.new);
