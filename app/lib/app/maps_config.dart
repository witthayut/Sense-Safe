/// Google Maps Platform configuration.
///
/// The key is NOT in source code. It lives in `app/.env` (gitignored; copy
/// `app/.env.example` to start) and reaches the app at build time:
///
///   flutter run -d web-server --web-port=8090 --dart-define-from-file=.env
///
/// The key is a browser key, so it ends up in the page the browser loads no
/// matter what. What protects it is the restriction set in Google Cloud:
///   - Application restrictions: Websites → http://localhost:8090/*,
///     http://127.0.0.1:8090/* (+ the real domain before any deploy)
///   - API restrictions: Maps JavaScript API, Directions API, Places API
///
/// Used on web to load the Maps script (see maps_loader.dart) and on mobile
/// for the Directions / Places HTTP calls. Android's native map reads a
/// separate key from AndroidManifest.xml (not set yet — Android is unused).
library;

const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

/// True when a key was provided (used to show a friendly hint instead of
/// failing silently when someone runs the app without `app/.env`).
bool get hasMapsApiKey => googleMapsApiKey.isNotEmpty;
