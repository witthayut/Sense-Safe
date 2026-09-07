/// A single Places Autocomplete suggestion.
class PlacePrediction {
  const PlacePrediction({required this.description, required this.placeId});

  /// Full human-readable place text, e.g. "Mahidol University, Nakhon Pathom".
  final String description;

  /// Stable Google place id (kept for future precise routing by place_id).
  final String placeId;
}
