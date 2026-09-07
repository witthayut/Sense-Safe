import '../models/trip_survey.dart';
import '../models/vibration_profile.dart';

/// HAPU's Exponential Moving Average — the report's §3.4 formula:
///
///   P(t) = α × feedback(t) + (1 − α) × P(t−1),  α = 0.3
///
/// Per the report, the survey adjusts ONLY `intensity` and
/// `leadTimeSeconds` (never the assessment scores, spatial type, or —
/// for now — rhythm). Q1/Q4/Q5 answers are stored for the future
/// K-Means/history work but do not move the profile yet.
///
/// Pure and synchronous so the tuning math is fully unit-testable.
class HapuEma {
  const HapuEma._();

  static const double alpha = 0.3;

  /// How far a single "too soft/strong" answer pulls the intensity target.
  /// Net effect per trip = alpha × step = ±0.09 — noticeable over a few
  /// trips, never jarring after one (the report's "เปลี่ยนแปลงช้าๆ ไม่กระโดด").
  static const double intensityStep = 0.3;

  /// How far a single "too early/late" answer pulls the lead-time target
  /// (seconds). Net effect per trip ≈ ±0.9 s.
  static const int leadStep = 3;

  /// Clamps match the Settings screen's slider ranges exactly, so EMA can
  /// never produce a value the UI can't represent.
  static const double minIntensity = 0.1;
  static const double maxIntensity = 1.0;
  static const int minLeadSeconds = 2;
  static const int maxLeadSeconds = 10;

  /// Returns the tuned (intensity, leadTimeSeconds) for [profile] given one
  /// [survey]. "Just right" answers return the EXACT current value (no EMA
  /// evaluated) so floating-point noise can never register as a change.
  static ({double intensity, int leadTimeSeconds}) apply(
    VibrationProfile profile,
    TripSurvey survey,
  ) {
    double intensity = profile.intensity;
    if (survey.strength != SurveyStrength.justRight) {
      final target = survey.strength == SurveyStrength.tooSoft
          ? profile.intensity + intensityStep
          : profile.intensity - intensityStep;
      intensity = (alpha * target + (1 - alpha) * profile.intensity)
          .clamp(minIntensity, maxIntensity)
          .toDouble();
    }

    int lead = profile.leadTimeSeconds;
    if (survey.timing != SurveyTiming.justRight) {
      // Cues arriving "too late" means the user wants MORE warning time.
      final target = survey.timing == SurveyTiming.tooLate
          ? profile.leadTimeSeconds + leadStep
          : profile.leadTimeSeconds - leadStep;
      lead = (alpha * target + (1 - alpha) * profile.leadTimeSeconds)
          .round()
          .clamp(minLeadSeconds, maxLeadSeconds);
    }

    return (intensity: intensity, leadTimeSeconds: lead);
  }
}
