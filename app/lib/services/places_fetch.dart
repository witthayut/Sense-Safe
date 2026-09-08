/// Platform-specific Places Autocomplete fetch.
///   - web  → JS interop to google.maps.places.AutocompleteService
///   - else → HTTP to the Places Autocomplete web service
///
/// Both expose: Future<List<PlacePrediction>> fetchPredictions({input, apiKey}).
library;

export 'places_fetch_web.dart'
    if (dart.library.io) 'places_fetch_io.dart';
