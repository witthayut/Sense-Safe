import 'learning_difference.dart';

/// A signed-in user. In Phase 1 this lives only in memory (mock auth).
/// In Phase 1.5 it maps to a Firebase Auth user + Firestore document.
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.username,
    this.learningDifferences = const {},
  });

  final String id;
  final String fullName;
  final String username;
  final Set<LearningDifference> learningDifferences;

  AppUser copyWith({
    String? fullName,
    Set<LearningDifference>? learningDifferences,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username,
      learningDifferences: learningDifferences ?? this.learningDifferences,
    );
  }
}
