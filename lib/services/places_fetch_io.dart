import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/place_prediction.dart';

/// Mobile/desktop: Places Autocomplete over HTTP (no CORS off-web).
Future<List<PlacePrediction>> fetchPredictions({
  required String input,
  required String apiKey,
}) async {
  final uri = Uri.https(
    'maps.googleapis.com',
    '/maps/api/place/autocomplete/json',
    {'input': input, 'key': apiKey},
  );
  final resp = await http.get(uri);
  if (resp.statusCode != 200) {
    throw Exception('Places network error (${resp.statusCode}).');
  }
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final status = data['status'];
  if (status == 'ZERO_RESULTS') return const [];
  if (status != 'OK') {
    throw Exception('Places $status: ${data['error_message'] ?? ''}');
  }
  return (data['predictions'] as List)
      .cast<Map<String, dynamic>>()
      .map((p) => PlacePrediction(
            description: p['description'] as String? ?? '',
            placeId: p['place_id'] as String? ?? '',
          ))
      .toList();
}
