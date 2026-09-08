// Unit tests for the assessment scoring (the one piece of real Phase-1 logic).

import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_drive/models/survey.dart';
import 'package:haptic_drive/models/vibration_profile.dart';
import 'package:haptic_drive/services/profile_service.dart';

void main() {
  const service = ProfileService();
  final questionCount = kSurveyQuestions.length;

  test('all highest-difficulty answers → strong, sharp profile', () {
    // Option 0 of every question carries the highest weight (1.0).
    final answers = List<int?>.filled(questionCount, 0);
    final profile = service.scoreSurvey(answers);

    expect(profile.rhythm, HapticRhythm.sharp);
    expect(profile.intensity, closeTo(0.85, 0.001));
    expect(profile.leadTimeSeconds, 8);
    // "distance" question's option 0 is weight 1.0 → full support need.
    expect(profile.supportPctFor(ProfileDimension.distance), 100);
    expect(profile.confidencePctFor(ProfileDimension.distance), 0);
  });

  test('all confident answers → gentle, soft profile', () {
    // Option 1 is the low/no-difficulty answer on every question.
    final answers = List<int?>.filled(questionCount, 1);
    final profile = service.scoreSurvey(answers);

    expect(profile.rhythm, HapticRhythm.soft);
    expect(profile.intensity, lessThan(0.6));
    expect(profile.supportPctFor(ProfileDimension.distance), 0);
    expect(profile.confidencePctFor(ProfileDimension.distance), 100);
  });

  test('unanswered survey is handled without crashing', () {
    final answers = List<int?>.filled(questionCount, null);
    final profile = service.scoreSurvey(answers);

    // No data → lowest support, gentle defaults.
    expect(profile.rhythm, HapticRhythm.soft);
    expect(profile.intensity, closeTo(0.35, 0.001));
    for (final d in ProfileDimension.values) {
      expect(profile.scoreFor(d), 0.0);
    }
  });

  test('confidence is the inverse of support for every dimension', () {
    final answers = List<int?>.filled(questionCount, 0);
    final profile = service.scoreSurvey(answers);
    for (final d in ProfileDimension.values) {
      expect(
        profile.confidencePctFor(d) + profile.supportPctFor(d),
        100,
      );
    }
  });
}
