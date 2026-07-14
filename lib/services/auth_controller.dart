import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/learning_difference.dart';

/// Real authentication backed by Firebase Auth (email/password) with the
/// user's profile stored in Firestore at `users/{uid}`.
class AuthController extends Notifier<AppUser?> {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  StreamSubscription<User?>? _sub;

  @override
  AppUser? build() {
    try {
      _sub = _auth.authStateChanges().listen(_onAuthChanged);
      ref.onDispose(() => _sub?.cancel());
      final current = _auth.currentUser;
      if (current != null) _onAuthChanged(current);
    } catch (_) {
      // Firebase not initialized (e.g. widget tests) — stay signed out.
    }
    return null;
  }

  bool get isSignedIn => state != null;

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      state = null;
      return;
    }
    Map<String, dynamic>? data;
    try {
      data = (await _db.collection('users').doc(user.uid).get()).data();
    } catch (_) {
      data = null; // offline / rules — fall back to Auth fields
    }
    state = AppUser(
      id: user.uid,
      email: user.email ?? '',
      fullName: (data?['fullName'] as String?) ?? user.displayName ?? '',
      learningDifferences:
          AppUser.parseLearningDifferences(data?['learningDifferences']),
    );
  }

  /// Returns null on success, or a user-friendly error message.
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Sends a password-reset email. Returns null on "success" — including
  /// unknown emails, which are deliberately treated as success so the app
  /// never reveals whether an address is registered (issue #5).
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return null; // conceal, don't reveal
      return _friendly(e);
    } catch (_) {
      return 'Could not send the reset email. Please try again.';
    }
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required Set<LearningDifference> learningDifferences,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(fullName.trim());

      final appUser = AppUser(
        id: user.uid,
        email: email.trim(),
        fullName: fullName.trim(),
        learningDifferences: learningDifferences,
      );
      await _db
          .collection('users')
          .doc(user.uid)
          .set(appUser.toFirestore(), SetOptions(merge: true));
      state = appUser;
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendly(e);
    } catch (_) {
      return 'Something went wrong creating your account.';
    }
  }

  Future<void> updateLearningDifferences(Set<LearningDifference> diffs) async {
    final user = state;
    if (user == null) return;
    state = user.copyWith(learningDifferences: diffs);
    await _db.collection('users').doc(user.id).set(
      {'learningDifferences': diffs.map((d) => d.name).toList()},
      SetOptions(merge: true),
    );
  }

  Future<void> logout() => _auth.signOut();

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'That email is already registered. Try logging in.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error — check your connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AppUser?>(AuthController.new);
