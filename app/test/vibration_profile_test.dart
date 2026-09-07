import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_drive/models/survey.dart';
import 'package:haptic_drive/models/vibration_profile.dart';

void main() {
  const original = VibrationProfile(
    scores: {ProfileDimension.attention: 0.85, ProfileDimension.distance: 0.2},
    intensity: 0.6,
    leadTimeSeconds: 5,
    rhythm: HapticRhythm.medium,
    spatialType: 'ADHD-leaning',
  );

  test('copyWith replaces only the tuning fields', () {
    final tuned = original.copyWith(
      intensity: 0.9,
      leadTimeSeconds: 8,
      rhythm: HapticRhythm.sharp,
    );
    expect(tuned.intensity, 0.9);
    expect(tuned.leadTimeSeconds, 8);
    expect(tuned.rhythm, HapticRhythm.sharp);
    // Assessment results must survive user tuning untouched:
    expect(tuned.scores, original.scores);
    expect(tuned.spatialType, 'ADHD-leaning');
  });

  test('copyWith with no arguments is an identical profile', () {
    final copy = original.copyWith();
    expect(copy.intensity, original.intensity);
    expect(copy.leadTimeSeconds, original.leadTimeSeconds);
    expect(copy.rhythm, original.rhythm);
  });

  test('tuned profile survives a Firestore round-trip', () {
    final tuned = original.copyWith(intensity: 0.35, rhythm: HapticRhythm.soft);
    final restored = VibrationProfile.fromFirestore(tuned.toFirestore());
    expect(restored, isNotNull);
    expect(restored!.intensity, 0.35);
    expect(restored.rhythm, HapticRhythm.soft);
    expect(restored.leadTimeSeconds, tuned.leadTimeSeconds);
    expect(restored.scoreFor(ProfileDimension.attention), 0.85);
  });
}
