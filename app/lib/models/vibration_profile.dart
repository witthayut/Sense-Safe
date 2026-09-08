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
    this.floorIntensity = defaultFloorIntensity,
  });

  /// Shipped default until the wearer calibrates: 0.42 = duty 185, the
  /// weakest level confirmed usable on a real wrist (firmware/MEASUREMENTS.md).
  /// It is NOT the 135 perception floor — that was measured sitting still and
  /// concentrating, and is too quiet to rely on in a moving car.
  static const double defaultFloorIntensity = 0.42;

  /// support-need score per dimension, 0.0 .. 1.0
  final Map<ProfileDimension, double> scores;

  /// 0.0 .. 1.0 — base vibration strength.
  final double intensity;

  /// How many seconds before a turn the first cue fires.
  final int leadTimeSeconds;

  final HapticRhythm rhythm;

  /// A friendly classification label, e.g. "Dyspraxia-leaning".
  final String spatialType;

  /// The weakest intensity THIS wearer can actually feel, measured by the
  /// Test Vibration screen. Nothing below this should ever be sent: it would
  /// not be a gentle cue, it would be silence the app mistakes for a cue.
  final double floorIntensity;

  /// New profile with some tuning values replaced — used by the Settings
  /// screen so user adjustments never touch the assessment scores/label.
  VibrationProfile copyWith({
    double? intensity,
    int? leadTimeSeconds,
    HapticRhythm? rhythm,
    double? floorIntensity,
  }) =>
      VibrationProfile(
        scores: scores,
        intensity: intensity ?? this.intensity,
        leadTimeSeconds: leadTimeSeconds ?? this.leadTimeSeconds,
        rhythm: rhythm ?? this.rhythm,
        spatialType: spatialType,
        floorIntensity: floorIntensity ?? this.floorIntensity,
      );

  double scoreFor(ProfileDimension d) => scores[d] ?? 0.0;

  /// Confidence (inverse of support-need) as a percentage 0..100.
  int confidencePctFor(ProfileDimension d) =>
      ((1 - scoreFor(d)) * 100).round();

  /// Support-need as a percentage 0..100.
  int supportPctFor(ProfileDimension d) => (scoreFor(d) * 100).round();

  /// Serialize for Firestore (enum keys/values stored as their `.name`).
  Map<String, dynamic> toFirestore() => {
        'scores': {for (final e in scores.entries) e.key.name: e.value},
        'intensity': intensity,
        'leadTimeSeconds': leadTimeSeconds,
        'rhythm': rhythm.name,
        'spatialType': spatialType,
        'floorIntensity': floorIntensity,
      };

  static VibrationProfile? fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return null;
    final rawScores = (data['scores'] as Map?) ?? const {};
    final scores = <ProfileDimension, double>{};
    for (final d in ProfileDimension.values) {
      final v = rawScores[d.name];
      if (v is num) scores[d] = v.toDouble();
    }
    final rhythm = HapticRhythm.values.firstWhere(
      (r) => r.name == data['rhythm'],
      orElse: () => HapticRhythm.medium,
    );
    return VibrationProfile(
      scores: scores,
      intensity: (data['intensity'] as num?)?.toDouble() ?? 0.0,
      leadTimeSeconds: (data['leadTimeSeconds'] as num?)?.toInt() ?? 3,
      rhythm: rhythm,
      spatialType: data['spatialType'] as String? ?? 'Balanced profile',
      floorIntensity: (data['floorIntensity'] as num?)?.toDouble() ??
          defaultFloorIntensity,
    );
  }
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
