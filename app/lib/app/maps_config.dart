/// Google Maps Platform configuration.
///
/// Replace [googleMapsApiKey] with your own key from Google Cloud, then enable
/// these APIs on the project and restrict the key:
///   - Maps JavaScript API   (web map)
///   - Maps SDK for Android   (Android map)
///   - Directions API         (A → B routing)
///
/// SECURITY: don't ship a real, unrestricted key in a public repo. Restrict it
/// by HTTP referrer (web) and Android app signature, and consider moving it to
/// a `--dart-define` / gitignored file before release.
///
/// The same key string must also be pasted into:
///   - web/index.html  (the Maps JavaScript <script> tag)
///   - android/app/src/main/AndroidManifest.xml  (com.google.android.geo.API_KEY)
library;

/// Used for the Directions API HTTP calls. Falls back to a build-time
/// --dart-define=GOOGLE_MAPS_API_KEY=... if provided.
const String googleMapsApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_API_KEY',
  defaultValue: 'AIzaSyBIUpO5Wc_gIEZjcpGg9Ep-IkmDhmhLsvg',
);

/// True when a real key has been provided (used to show a friendly hint
/// instead of failing silently).
bool get hasMapsApiKey =>
    googleMapsApiKey.isNotEmpty && googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY';
