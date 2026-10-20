import 'dart:async';
import 'dart:js_interop';

/// Injects the Maps JavaScript API (with the Places library, used for
/// autocomplete) and waits until `google.maps` exists.
///
/// Never blocks startup for long: with no key, a network failure or a slow
/// connection, the app still opens and the Routes tab shows its own
/// "no key / routing failed" message instead of a frozen splash screen.
Future<void> loadGoogleMaps(String apiKey) async {
  if (apiKey.isEmpty || _google != null) return;

  final done = Completer<void>();
  final script = _createScript('script')
    ..src = 'https://maps.googleapis.com/maps/api/js'
        '?key=${Uri.encodeQueryComponent(apiKey)}&libraries=places'
    ..async = true
    ..onload = (() {
      if (!done.isCompleted) done.complete();
    }).toJS
    ..onerror = ((JSAny? _) {
      if (!done.isCompleted) done.complete();
    }).toJS;
  _appendToHead(script);

  await done.future.timeout(const Duration(seconds: 10), onTimeout: () {});
}

@JS('google')
external JSObject? get _google;

@JS('document.createElement')
external _ScriptElement _createScript(String tag);

@JS('document.head.appendChild')
external void _appendToHead(_ScriptElement element);

extension type _ScriptElement._(JSObject _) implements JSObject {
  external set src(String value);
  external set async(bool value);
  external set onload(JSFunction handler);
  external set onerror(JSFunction handler);
}
