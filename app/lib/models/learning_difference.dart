/// The learning-difference options shown on the Register screen.
enum LearningDifference {
  dyslexia,
  adhd,
  dyscalculia,
  dyspraxia,
  notSure;

  String get label {
    switch (this) {
      case LearningDifference.dyslexia:
        return 'Dyslexia';
      case LearningDifference.adhd:
        return 'ADHD';
      case LearningDifference.dyscalculia:
        return 'Dyscalculia';
      case LearningDifference.dyspraxia:
        return 'Dyspraxia';
      case LearningDifference.notSure:
        return 'Not sure';
    }
  }
}
