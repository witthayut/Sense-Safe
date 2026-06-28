/// Platform-specific Directions fetch:
///   - web  → JS interop to the in-page google.maps DirectionsService
///   - else → HTTP to the Directions web service
///
/// Both expose: Future<List<RawRoute>> fetchRawRoutes({origin, destination, apiKey}).
library;

export 'directions_fetch_web.dart'
    if (dart.library.io) 'directions_fetch_io.dart';
