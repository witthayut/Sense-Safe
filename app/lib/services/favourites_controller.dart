import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/favourite.dart';
import 'auth_controller.dart';

/// Per-user favourite destinations, stored in Firestore at
/// `users/{uid}.favourites` (same merge-into-the-user-doc pattern as
/// `vibrationProfile`). Loaded on login, cleared on logout; writes are
/// best-effort so the UI stays responsive offline.
class FavouritesController extends Notifier<List<Favourite>> {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String? _uid;

  @override
  List<Favourite> build() {
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
      final raw = (doc.data()?['favourites'] as List?) ?? const [];
      state = [
        for (final item in raw)
          if (Favourite.fromMap(item) case final f?) f,
      ];
    } catch (_) {
      // offline / rules — keep whatever we have in memory.
    }
  }

  bool contains(String destination) =>
      state.any((f) => f.destination == destination);

  Future<void> add(Favourite favourite) async {
    if (contains(favourite.destination)) return; // no duplicates
    state = [...state, favourite];
    await _save();
  }

  Future<void> removeByDestination(String destination) async {
    state = state.where((f) => f.destination != destination).toList();
    await _save();
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {'favourites': [for (final f in state) f.toMap()]},
        SetOptions(merge: true),
      );
    } catch (_) {
      // Best-effort; in-memory list still drives the UI this session.
    }
  }
}

final favouritesControllerProvider =
    NotifierProvider<FavouritesController, List<Favourite>>(
        FavouritesController.new);
