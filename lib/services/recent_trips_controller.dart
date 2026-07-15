import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recent_trip.dart';
import 'auth_controller.dart';

/// Per-user recent drives, newest first, stored at `users/{uid}.recentTrips`
/// (same merge-into-the-user-doc pattern as favourites/vibrationProfile).
/// Recorded when the user taps "Start drive"; capped so the doc stays small.
class RecentTripsController extends Notifier<List<RecentTrip>> {
  static const _maxTrips = 5;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? _uid;

  @override
  List<RecentTrip> build() {
    try {
      ref.listen<dynamic>(authControllerProvider, (prev, next) {
        final uid = next?.id as String?;
        _uid = uid;
        if (uid == null) {
          state = const [];
        } else if (prev?.id != uid) {
          _load(uid);
        }
      });
      final current = ref.read(authControllerProvider);
      _uid = current?.id;
      if (current != null) _load(current.id);
    } catch (_) {
      // Firebase not initialized (widget tests) — stay empty.
    }
    return const [];
  }

  Future<void> _load(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final raw = (doc.data()?['recentTrips'] as List?) ?? const [];
      state = [
        for (final item in raw)
          if (RecentTrip.fromMap(item) case final t?) t,
      ];
    } catch (_) {
      // offline / rules — keep whatever we have in memory.
    }
  }

  /// Newest first; re-driving a known destination moves it to the front
  /// instead of duplicating it.
  Future<void> record(RecentTrip trip) async {
    state = [
      trip,
      ...state.where((t) => t.destination != trip.destination),
    ].take(_maxTrips).toList();
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {'recentTrips': [for (final t in state) t.toMap()]},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Best-effort; in-memory list still drives the UI this session.
    }
  }
}

final recentTripsControllerProvider =
    NotifierProvider<RecentTripsController, List<RecentTrip>>(
        RecentTripsController.new);
