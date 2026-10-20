import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/learning_difference.dart';
import '../models/survey.dart';
import '../models/trip_survey.dart';
import '../models/vibration_profile.dart';
import 'auth_controller.dart';
import 'hapu_ema.dart';
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

  /// HAPU (report §3.3–3.4): apply one post-trip Quick Survey. Q2/Q3 nudge
  /// lead-time/intensity via [HapuEma]; the full survey record is stored to
  /// Firestore for the future K-Means / history work. Returns the tuned
  /// values + whether anything actually changed (for the UI to report).
  ({double intensity, int leadTimeSeconds, bool changed}) applyTripSurvey(
      TripSurvey survey) {
    final base = state.profile ?? _defaultProfile;
    final tuned = HapuEma.apply(base, survey);
    final changed = tuned.intensity != base.intensity ||
        tuned.leadTimeSeconds != base.leadTimeSeconds;

    if (changed) {
      final updated = base.copyWith(
        intensity: tuned.intensity,
        leadTimeSeconds: tuned.leadTimeSeconds,
      );
      state = state.copyWith(profile: updated);
      _save(updated);
    } else if (state.profile == null) {
      // First-ever survey with no assessment: persist the default baseline
      // so future EMA nudges have a stored starting point.
      state = state.copyWith(profile: base);
      _save(base);
    }

    _storeSurvey(survey);
    return (
      intensity: tuned.intensity,
      leadTimeSeconds: tuned.leadTimeSeconds,
      changed: changed,
    );
  }

  /// Best-effort append of the raw survey record (evidence + future K-Means).
  Future<void> _storeSurvey(TripSurvey survey) async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set(
        {
          'tripSurveys': FieldValue.arrayUnion([survey.toMap()]),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // offline / rules — profile tuning above still applied in memory.
    }
  }

  static const _defaultProfile = VibrationProfile(
    scores: {},
    intensity: 0.6,
    leadTimeSeconds: 5,
    rhythm: HapticRhythm.medium,
    spatialType: 'Balanced profile',
  );

  /// Settings screen: user fine-tunes intensity / lead time / rhythm.
  /// Starts from a medium default if they never completed an assessment.
  void updateTuning({
    double? intensity,
    int? leadTimeSeconds,
    HapticRhythm? rhythm,
    double? floorIntensity,
  }) {
    final base = state.profile ?? _defaultProfile;
    final updated = base.copyWith(
      intensity: intensity,
      leadTimeSeconds: leadTimeSeconds,
      rhythm: rhythm,
      floorIntensity: floorIntensity,
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
