import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Resolves the device's current location for use as the routing origin.
///
/// Always returns *something* usable: if location services are off, the user
/// denies permission, or it times out, it falls back to [fallback] so the
/// Routes screen still works.
class LocationService {
  const LocationService();

  /// Bangkok city centre — sensible default for this project's locale.
  static const LatLng fallback = LatLng(13.7563, 100.5018);

  Future<({LatLng latLng, bool isReal})> currentOrFallback() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (latLng: fallback, isReal: false);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (latLng: fallback, isReal: false);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (latLng: LatLng(pos.latitude, pos.longitude), isReal: true);
    } catch (_) {
      return (latLng: fallback, isReal: false);
    }
  }
}

final locationServiceProvider =
    Provider<LocationService>((ref) => const LocationService());
