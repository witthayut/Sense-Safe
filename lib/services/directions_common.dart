import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Thrown when routes can't be computed; [message] is user-friendly.
class DirectionsException implements Exception {
  const DirectionsException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A parsed-but-unclassified route, shared by the IO (HTTP) and web (JS
/// interop) fetchers before [DirectionsService] assigns badges.
class RawRoute {
  const RawRoute({
    required this.points,
    required this.durationSec,
    required this.distanceM,
    required this.turns,
    required this.origin,
    required this.destination,
    required this.startAddress,
    required this.endAddress,
  });

  final List<LatLng> points;
  final int durationSec;
  final int distanceM;
  final int turns;
  final LatLng origin;
  final LatLng destination;
  final String startAddress;
  final String endAddress;
}

/// Decodes a Google "encoded polyline" into lat/lng points (used by the HTTP
/// fetcher; the web JS API returns geometry already decoded).
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0, lat = 0, lng = 0;

  while (index < encoded.length) {
    int shift = 0, result = 0, b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}
