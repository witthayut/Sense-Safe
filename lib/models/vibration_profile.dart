import 'survey.dart';

/// Haptic rhythm styles a turn can be delivered with.
enum HapticRhythm {
  soft,
  medium,
  sharp;

  String get label => switch (this) {
        HapticRhythm.soft => 'Soft pulse',
        HapticRhythm.medium => 'Medium',
        HapticRhythm.sharp => 'Sharp',
      };
}

/// The output of the assessment — the user's "vibration profile".
///
/// Each dimension is stored as a 0..1 "support need" score, where higher
/// means the user benefits from stronger / earlier haptic guidance.
/// The UI shows these as the confidence bars on the results screen.
class VibrationProfile {
  const VibrationProfile({
    required this.scores,
    required this.intensity,
    required this.leadTimeSeconds,
    required this.rhythm,
    required this.spatialType,
  });

  /// support-need score per dimension, 0.0 .. 1.0
  final Map<ProfileDimension, double> scores;

  /// 0.0 .. 1.0 — base vibration strength.
  final double intensity;

  /// How many seconds before a turn the first cue fires.
  final int leadTimeSeconds;

  final HapticRhythm rhythm;

  /// A friendly classification label, e.g. "Dyspraxia-leaning".
  final String spatialType;

  double scoreFor(ProfileDimension d) => scores[d] ?? 0.0;

  /// Confidence (inverse of support-need) as a percentage 0..100.
  int confidencePctFor(ProfileDimension d) =>
      ((1 - scoreFor(d)) * 100).round();

  /// Support-need as a percentage 0..100.
  int supportPctFor(ProfileDimension d) => (scoreFor(d) * 100).round();
}

extension ProfileDimensionLabel on ProfileDimension {
  String get label => switch (this) {
        ProfileDimension.leftRight => 'Telling left from right',
        ProfileDimension.distance => 'Judging distance to a turn',
        ProfileDimension.signReading => 'Reading signs on screen',
        ProfileDimension.hearing => 'Hearing spoken directions',
        ProfileDimension.attention => 'Attention while driving',
      };
}
