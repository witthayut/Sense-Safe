/// Loads the Google Maps JavaScript API at startup, using the key from
/// `app/.env` (passed in with `--dart-define-from-file=.env`).
///
///   - web  → injects the Maps <script> tag and waits for it to load
///   - else → nothing to do (Android/iOS maps get their key from the
///            platform manifest, not from a script)
///
/// The key used to live in a hard-coded <script> in web/index.html, which put
/// it in git. Loading it from Dart keeps the key out of the repo entirely.
library;

export 'maps_loader_web.dart' if (dart.library.io) 'maps_loader_io.dart';
