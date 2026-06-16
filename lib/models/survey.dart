/// The personalization assessment: 6 questions from the mockups.
///
/// Each answer carries a [weight] from 0.0 (no difficulty / fully confident)
/// to 1.0 (high difficulty / needs the most haptic support), plus the
/// [dimension] it contributes to. The scoring logic in
/// `profile_service.dart` turns these into a VibrationProfile.

enum ProfileDimension {
  leftRight, // telling left from right
  distance, // judging distance to a turn
  signReading, // reading signs on screen
  hearing, // hearing spoken directions
  attention, // attention while driving
}

class SurveyOption {
  const SurveyOption({
    required this.text,
    required this.weight,
  });

  final String text;
  final double weight; // 0.0 .. 1.0  (higher = more difficulty)
}

class SurveyQuestion {
  const SurveyQuestion({
    required this.prompt,
    required this.dimension,
    required this.options,
  });

  final String prompt;
  final ProfileDimension dimension;
  final List<SurveyOption> options;
}

/// The six questions, transcribed from the design.
const List<SurveyQuestion> kSurveyQuestions = [
  SurveyQuestion(
    prompt: 'When the GPS says "turn left," what usually happens?',
    dimension: ProfileDimension.leftRight,
    options: [
      SurveyOption(
        text:
            'I sometimes turn the wrong way, or need a moment to work out which side is left or right.',
        weight: 1.0,
      ),
      SurveyOption(
        text: 'I hear it fine, but I turn a little too early or too late.',
        weight: 0.5,
      ),
      SurveyOption(
        text: "I don't catch the instructions in time — it doesn't register.",
        weight: 0.7,
      ),
      SurveyOption(
        text: 'Something distracts me and I miss it entirely.',
        weight: 0.6,
      ),
    ],
  ),
  SurveyQuestion(
    prompt: 'When the app says "in 400 meters, turn right," that distance feels...',
    dimension: ProfileDimension.distance,
    options: [
      SurveyOption(
        text: 'Hard to gauge — 400 m and 200 m feel about the same.',
        weight: 1.0,
      ),
      SurveyOption(
        text: "Clear enough — distance isn't my problem.",
        weight: 0.0,
      ),
    ],
  ),
  SurveyQuestion(
    prompt: 'Reading street names or signs on a screen while driving is...',
    dimension: ProfileDimension.signReading,
    options: [
      SurveyOption(
        text: 'Slow or tiring — the letters take effort to decode.',
        weight: 1.0,
      ),
      SurveyOption(
        text: "Fine to read, but I can't look away from the road long enough.",
        weight: 0.5,
      ),
    ],
  ),
  SurveyQuestion(
    prompt: 'With spoken voice directions specifically, I...',
    dimension: ProfileDimension.hearing,
    options: [
      SurveyOption(
        text: 'Often need them repeated, or I mishear words.',
        weight: 1.0,
      ),
      SurveyOption(
        text: 'Hear them clearly.',
        weight: 0.0,
      ),
    ],
  ),
  SurveyQuestion(
    prompt: 'While driving, my attention...',
    dimension: ProfileDimension.attention,
    options: [
      SurveyOption(
        text:
            'Jumps to billboards, other cars or sounds, and I lose the navigation thread.',
        weight: 1.0,
      ),
      SurveyOption(
        text: 'Stays focused on the route.',
        weight: 0.0,
      ),
    ],
  ),
  SurveyQuestion(
    prompt: 'Telling left from right quickly, without thinking, is...',
    dimension: ProfileDimension.leftRight,
    options: [
      SurveyOption(
        text: 'Something I have to pause and work out.',
        weight: 1.0,
      ),
      SurveyOption(
        text: 'Automatic — I never think about it.',
        weight: 0.0,
      ),
    ],
  ),
];
