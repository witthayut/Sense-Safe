import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/learning_difference.dart';

/// Mock authentication for Phase 1.
///
/// Holds the current user in memory. Any non-empty username + password
/// "works". Swap the body of [login]/[register] for Firebase Auth in
/// Phase 1.5 without changing the UI.
class AuthController extends Notifier<AppUser?> {
  int _seq = 0;

  @override
  AppUser? build() => null;

  bool get isSignedIn => state != null;

  Future<String?> login(String username, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Please enter a username and password.';
    }
    state = AppUser(
      id: 'u${_seq++}',
      fullName: username,
      username: username.trim(),
    );
    return null; // null == success
  }

  Future<String?> register({
    required String fullName,
    required String username,
    required String password,
    required Set<LearningDifference> learningDifferences,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (fullName.trim().isEmpty ||
        username.trim().isEmpty ||
        password.isEmpty) {
      return 'Please fill in every field.';
    }
    state = AppUser(
      id: 'u${_seq++}',
      fullName: fullName.trim(),
      username: username.trim(),
      learningDifferences: learningDifferences,
    );
    return null;
  }

  void updateLearningDifferences(Set<LearningDifference> diffs) {
    final user = state;
    if (user == null) return;
    state = user.copyWith(learningDifferences: diffs);
  }

  void logout() => state = null;
}

final authControllerProvider =
    NotifierProvider<AuthController, AppUser?>(AuthController.new);
