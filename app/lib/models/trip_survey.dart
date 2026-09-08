/// The post-trip Quick Survey (report §3.3: 5 questions, < 30 seconds).
/// Answers feed HAPU's EMA — see `services/hapu_ema.dart`.
library;

enum SurveyTiming {
  tooEarly,
  justRight,
  tooLate;

  String get label => switch (this) {
        SurveyTiming.tooEarly => 'Too early',
        SurveyTiming.justRight => 'Just right',
        SurveyTiming.tooLate => 'Too late',
      };
}

enum SurveyStrength {
  tooSoft,
  justRight,
  tooStrong;

  String get label => switch (this) {
        SurveyStrength.tooSoft => 'Too soft',
        SurveyStrength.justRight => 'Just right',
        SurveyStrength.tooStrong => 'Too strong',
      };
}

class TripSurvey {
  const TripSurvey({
    required this.missedTurns,
    required this.timing,
    required this.strength,
    required this.confusing,
    required this.comfort,
    required this.at,
  });

  /// Q1 — did they miss any turns?
  final bool missedTurns;

  /// Q2 — cue timing (drives the lead-time EMA).
  final SurveyTiming timing;

  /// Q3 — vibration strength (drives the intensity EMA).
  final SurveyStrength strength;

  /// Q4 — any confusing moment?
  final bool confusing;

  /// Q5 — overall comfort, 1..5 stars.
  final int comfort;

  final DateTime at;

  Map<String, dynamic> toMap() => {
        'missedTurns': missedTurns,
        'timing': timing.name,
        'strength': strength.name,
        'confusing': confusing,
        'comfort': comfort,
        'at': at.toIso8601String(),
      };

  static TripSurvey? fromMap(dynamic data) {
    if (data is! Map) return null;
    final at = DateTime.tryParse(data['at'] as String? ?? '');
    if (at == null) return null;
    return TripSurvey(
      missedTurns: data['missedTurns'] as bool? ?? false,
      timing: SurveyTiming.values.firstWhere(
        (t) => t.name == data['timing'],
        orElse: () => SurveyTiming.justRight,
      ),
      strength: SurveyStrength.values.firstWhere(
        (s) => s.name == data['strength'],
        orElse: () => SurveyStrength.justRight,
      ),
      confusing: data['confusing'] as bool? ?? false,
      comfort: ((data['comfort'] as num?)?.toInt() ?? 3).clamp(1, 5),
      at: at,
    );
  }
}
