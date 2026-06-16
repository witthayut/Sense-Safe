import '../models/survey.dart';
import '../models/vibration_profile.dart';

/// Turns survey answers into a [VibrationProfile].
///
/// This is intentionally simple and transparent so it's easy to tune later.
/// `answers` is a list parallel to [kSurveyQuestions]: each entry is the index
/// of the chosen option for that question (or null if skipped).
class ProfileService {
  const ProfileService();

  VibrationProfile scoreSurvey(List<int?> answers) {
    // Accumulate weight + count per dimension.
    final totals = <ProfileDimension, double>{};
    final counts = <ProfileDimension, int>{};

    for (var i = 0; i < kSurveyQuestions.length; i++) {
      final q = kSurveyQuestions[i];
      final choice = (i < answers.length) ? answers[i] : null;
      if (choice == null || choice < 0 || choice >= q.options.length) continue;
      final w = q.options[choice].weight;
      totals[q.dimension] = (totals[q.dimension] ?? 0) + w;
      counts[q.dimension] = (counts[q.dimension] ?? 0) + 1;
    }

    final scores = <ProfileDimension, double>{};
    for (final d in ProfileDimension.values) {
      final c = counts[d] ?? 0;
      scores[d] = c == 0 ? 0.0 : (totals[d]! / c).clamp(0.0, 1.0);
    }

    // Overall support need drives default intensity + lead time.
    final overall = scores.values.isEmpty
        ? 0.0
        : scores.values.reduce((a, b) => a + b) / scores.length;

    final intensity = (0.35 + overall * 0.5).clamp(0.0, 1.0);
    final leadTime = (3 + (overall * 5)).round(); // 3..8 seconds
    final rhythm = overall > 0.66
        ? HapticRhythm.sharp
        : (overall > 0.33 ? HapticRhythm.medium : HapticRhythm.soft);

    return VibrationProfile(
      scores: scores,
      intensity: intensity,
      leadTimeSeconds: leadTime,
      rhythm: rhythm,
      spatialType: _classify(scores),
    );
  }

  String _classify(Map<ProfileDimension, double> scores) {
    final leftRight = scores[ProfileDimension.leftRight] ?? 0;
    final distance = scores[ProfileDimension.distance] ?? 0;
    final sign = scores[ProfileDimension.signReading] ?? 0;
    final attention = scores[ProfileDimension.attention] ?? 0;

    // Pick the dominant need; purely a friendly label, never a diagnosis.
    final entries = {
      'Dyspraxia-leaning': leftRight,
      'Dyscalculia-leaning': distance,
      'Dyslexia-leaning': sign,
      'ADHD-leaning': attention,
    };
    final top = entries.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (top.value < 0.25) return 'Balanced profile';
    return top.key;
  }
}
