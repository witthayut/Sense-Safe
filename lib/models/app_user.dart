import 'learning_difference.dart';

/// A signed-in user — maps to a Firebase Auth user (id/email) plus the profile
/// fields we store in the Firestore `users/{uid}` document.
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.learningDifferences = const {},
  });

  final String id; // Firebase Auth uid
  final String email;
  final String fullName;
  final Set<LearningDifference> learningDifferences;

  AppUser copyWith({
    String? fullName,
    Set<LearningDifference>? learningDifferences,
  }) {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      learningDifferences: learningDifferences ?? this.learningDifferences,
    );
  }

  /// The profile fields we own in Firestore (Auth owns id/email).
  Map<String, dynamic> toFirestore() => {
        'fullName': fullName,
        'email': email,
        'learningDifferences':
            learningDifferences.map((d) => d.name).toList(),
      };

  static Set<LearningDifference> parseLearningDifferences(dynamic raw) {
    if (raw is! List) return const {};
    final result = <LearningDifference>{};
    for (final item in raw) {
      final match = LearningDifference.values
          .where((d) => d.name == item)
          .firstOrNull;
      if (match != null) result.add(match);
    }
    return result;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
