import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_maneuver.dart';
import 'directions_common.dart';

/// Web fetch: call the in-page `google.maps.DirectionsService` (loaded via the
/// Maps JavaScript API <script> in web/index.html). This avoids the CORS block
/// that prevents the browser from calling the Directions *web service* over
/// HTTP. [apiKey] is unused here — the key lives in the <script> tag.
Future<List<RawRoute>> fetchRawRoutes({
  required String origin,
  required String destination,
  required String apiKey,
}) async {
  try {
    // origin arrives as "lat,lng" (current location) → use a LatLngLiteral.
    final parts = origin.split(',');
    final JSAny originJs = parts.length == 2
        ? _LatLngLiteral(
            lat: double.parse(parts[0]).toJS,
            lng: double.parse(parts[1]).toJS,
          )
        : origin.toJS;

    final request = _DirRequest(
      origin: originJs,
      destination: destination.toJS,
      travelMode: 'DRIVING'.toJS,
      provideRouteAlternatives: true.toJS,
    );

    final result = await _DirectionsService().route(request).toDart;
    final routes = result.routes.toDart;

    return [
      for (final r in routes.take(3)) _toRaw(r),
    ];
  } on DirectionsException {
    rethrow;
  } catch (e) {
    throw DirectionsException(_friendly(e.toString()));
  }
}

RawRoute _toRaw(_DirRoute r) {
  final leg = r.legs.toDart.first;
  final maneuvers = <RouteManeuver>[
    for (final s in leg.steps.toDart)
      if ((s.maneuver?.toDart ?? '').isNotEmpty)
        RouteManeuver(
          googleType: s.maneuver!.toDart,
          position: LatLng(
            s.startLocation.lat().toDartDouble,
            s.startLocation.lng().toDartDouble,
          ),
          instruction: stripHtml(s.instructions?.toDart ?? ''),
        ),
  ];
  final points = [
    for (final p in r.overviewPath.toDart)
      LatLng(p.lat().toDartDouble, p.lng().toDartDouble),
  ];
  return RawRoute(
    points: points,
    durationSec: leg.duration.value.toDartInt,
    distanceM: leg.distance.value.toDartInt,
    turns: maneuvers.length,
    origin:
        LatLng(leg.startLocation.lat().toDartDouble, leg.startLocation.lng().toDartDouble),
    destination:
        LatLng(leg.endLocation.lat().toDartDouble, leg.endLocation.lng().toDartDouble),
    startAddress: leg.startAddress.toDart,
    endAddress: leg.endAddress.toDart,
    maneuvers: maneuvers,
  );
}

String _friendly(String err) {
  if (err.contains('ZERO_RESULTS') || err.contains('NOT_FOUND')) {
    return 'No route found to that destination. Check the spelling.';
  }
  if (err.contains('REQUEST_DENIED')) {
    return 'Request denied — check the key & that Directions API is enabled.';
  }
  if (err.contains('OVER_QUERY_LIMIT')) {
    return 'Quota exceeded for the Directions API.';
  }
  if (err.contains('undefined') || err.contains('google')) {
    return 'Map service still loading — try again in a moment.';
  }
  return 'Could not get a route.';
}

// ─── Minimal JS interop bindings for the Maps DirectionsService ──────────────

@JS('google.maps.DirectionsService')
extension type _DirectionsService._(JSObject _) implements JSObject {
  external factory _DirectionsService();
  external JSPromise<_DirResult> route(_DirRequest request);
}

extension type _DirRequest._(JSObject _) implements JSObject {
  external factory _DirRequest({
    JSAny origin,
    JSAny destination,
    JSString travelMode,
    JSBoolean provideRouteAlternatives,
  });
}

extension type _LatLngLiteral._(JSObject _) implements JSObject {
  external factory _LatLngLiteral({JSNumber lat, JSNumber lng});
}

extension type _DirResult._(JSObject _) implements JSObject {
  external JSArray<_DirRoute> get routes;
}

extension type _DirRoute._(JSObject _) implements JSObject {
  external JSArray<_DirLeg> get legs;
  @JS('overview_path')
  external JSArray<_MLatLng> get overviewPath;
}

extension type _DirLeg._(JSObject _) implements JSObject {
  external _TextValue get duration;
  external _TextValue get distance;
  external JSArray<_DirStep> get steps;
  @JS('start_address')
  external JSString get startAddress;
  @JS('end_address')
  external JSString get endAddress;
  @JS('start_location')
  external _MLatLng get startLocation;
  @JS('end_location')
  external _MLatLng get endLocation;
}

extension type _TextValue._(JSObject _) implements JSObject {
  external JSString get text;
  external JSNumber get value;
}

extension type _DirStep._(JSObject _) implements JSObject {
  external JSString? get maneuver;
  external JSString? get instructions;
  @JS('start_location')
  external _MLatLng get startLocation;
}

extension type _MLatLng._(JSObject _) implements JSObject {
  external JSNumber lat();
  external JSNumber lng();
}
