import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/maps_config.dart';
import '../models/place_prediction.dart';
import 'places_fetch.dart';

/// Provides destination suggestions (Places Autocomplete). Returns an empty
/// list on any failure so the search box degrades gracefully.
class PlacesService {
  const PlacesService();

  Future<List<PlacePrediction>> autocomplete(String input) async {
    final query = input.trim();
    if (!hasMapsApiKey || query.length < 3) return const [];
    try {
      return await fetchPredictions(input: query, apiKey: googleMapsApiKey);
    } catch (_) {
      return const []; // suggestions are best-effort; fail quietly
    }
  }
}

final placesServiceProvider =
    Provider<PlacesService>((ref) => const PlacesService());
