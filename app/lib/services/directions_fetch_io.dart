import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/route_maneuver.dart';
import 'directions_common.dart';

/// Mobile/desktop fetch: the Directions web service over HTTP (no CORS here).
Future<List<RawRoute>> fetchRawRoutes({
  required String origin,
  required String destination,
  required String apiKey,
}) async {
  final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
    'origin': origin,
    'destination': destination,
    'mode': 'driving',
    'alternatives': 'true',
    'key': apiKey,
  });

  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw DirectionsException('Network error (${resp.statusCode}).');
  }
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final status = data['status'] as String? ?? 'UNKNOWN';
  if (status != 'OK') {
    throw DirectionsException(
        _friendlyStatus(status, data['error_message'] as String?));
  }

  final routes = (data['routes'] as List).cast<Map<String, dynamic>>();
  return routes.take(3).map(_parse).toList();
}

RawRoute _parse(Map<String, dynamic> route) {
  final leg = (route['legs'] as List).first as Map<String, dynamic>;
  final steps = (leg['steps'] as List).cast<Map<String, dynamic>>();
  final maneuvers = <RouteManeuver>[
    for (final s in steps)
      if ((s['maneuver'] as String?)?.isNotEmpty ?? false)
        RouteManeuver(
          googleType: s['maneuver'] as String,
          position: LatLng(
            (s['start_location'] as Map<String, dynamic>)['lat'] as double,
            (s['start_location'] as Map<String, dynamic>)['lng'] as double,
          ),
          instruction: stripHtml(s['html_instructions'] as String? ?? ''),
        ),
  ];
  final start = leg['start_location'] as Map<String, dynamic>;
  final end = leg['end_location'] as Map<String, dynamic>;

  // Build the path from PER-STEP polylines, not overview_polyline: the
  // overview is heavily simplified (cuts across blocks), which made the
  // simulated drive leave the road and threw off cue distances.
  final points = <LatLng>[];
  for (final s in steps) {
    final encoded =
        ((s['polyline'] as Map<String, dynamic>?)?['points'] as String?) ?? '';
    for (final p in decodePolyline(encoded)) {
      if (points.isEmpty || points.last != p) points.add(p); // skip joints
    }
  }
  if (points.isEmpty) {
    points.addAll(decodePolyline(
        (route['overview_polyline'] as Map<String, dynamic>)['points']
            as String));
  }

  return RawRoute(
    points: points,
    durationSec: (leg['duration'] as Map<String, dynamic>)['value'] as int,
    distanceM: (leg['distance'] as Map<String, dynamic>)['value'] as int,
    turns: maneuvers.length,
    origin: LatLng(start['lat'] as double, start['lng'] as double),
    destination: LatLng(end['lat'] as double, end['lng'] as double),
    startAddress: leg['start_address'] as String? ?? '',
    endAddress: leg['end_address'] as String? ?? '',
    maneuvers: maneuvers,
  );
}

String _friendlyStatus(String status, String? message) {
  switch (status) {
    case 'NOT_FOUND':
    case 'ZERO_RESULTS':
      return 'No drivable route between those places — check the spelling, '
          'and make sure both are reachable by road.';
    case 'REQUEST_DENIED':
      return 'Request denied — check the key & that Directions API is enabled.';
    case 'OVER_QUERY_LIMIT':
      return 'Quota exceeded for the Directions API.';
    default:
      return message ?? 'Could not get a route ($status).';
  }
}
