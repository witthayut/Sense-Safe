import 'dart:js_interop';

import '../models/place_prediction.dart';

/// Web: the in-page `google.maps.places.AutocompleteService` (loaded via the
/// `libraries=places` script param) — avoids the CORS block on the HTTP API.
/// [apiKey] is unused here (the key lives in the <script> tag).
Future<List<PlacePrediction>> fetchPredictions({
  required String input,
  required String apiKey,
}) async {
  try {
    final service = _AutocompleteService();
    final response =
        await service.getPlacePredictions(_AutoRequest(input: input.toJS)).toDart;
    return [
      for (final p in response.predictions.toDart)
        PlacePrediction(
          description: p.description.toDart,
          placeId: p.placeId.toDart,
        ),
    ];
  } catch (e) {
    final msg = e.toString();
    if (msg.contains('ZERO_RESULTS')) return const []; // genuinely no matches
    if (msg.contains('REQUEST_DENIED')) {
      throw Exception('Places API not enabled or not allowed for this key.');
    }
    if (msg.toLowerCase().contains('undefined') ||
        msg.toLowerCase().contains('places')) {
      throw Exception('Places library not loaded — hard refresh (Ctrl+Shift+R).');
    }
    throw Exception('Places error: $msg');
  }
}

@JS('google.maps.places.AutocompleteService')
extension type _AutocompleteService._(JSObject _) implements JSObject {
  external factory _AutocompleteService();
  external JSPromise<_AutoResponse> getPlacePredictions(_AutoRequest request);
}

extension type _AutoRequest._(JSObject _) implements JSObject {
  external factory _AutoRequest({JSString input});
}

extension type _AutoResponse._(JSObject _) implements JSObject {
  external JSArray<_Prediction> get predictions;
}

extension type _Prediction._(JSObject _) implements JSObject {
  external JSString get description;
  @JS('place_id')
  external JSString get placeId;
}
