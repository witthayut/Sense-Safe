import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Which "best for…" badge a route earned, used to colour/label the cards.
enum RouteBadge { ldFriendly, fastest, fewestTurns, alternative }

extension RouteBadgeLabel on RouteBadge {
  String get label => switch (this) {
        RouteBadge.ldFriendly => 'Most LD-friendly',
        RouteBadge.fastest => 'Fastest',
        RouteBadge.fewestTurns => 'Fewest turns',
        RouteBadge.alternative => 'Alternative',
      };
}

/// One candidate route from the Directions API, with derived metrics.
class RouteOption {
  const RouteOption({
    required this.points,
    required this.durationSec,
    required this.distanceM,
    required this.turns,
    required this.origin,
    required this.destination,
    required this.startAddress,
    required this.endAddress,
    required this.badge,
    required this.description,
  });

  final List<LatLng> points;
  final int durationSec;
  final int distanceM;
  final int turns; // number of maneuvers (turn-by-turn decisions)
  final LatLng origin;
  final LatLng destination;
  final String startAddress;
  final String endAddress;
  final RouteBadge badge;
  final String description;

  String get durationText {
    final totalMin = (durationSec / 60).round();
    if (totalMin < 60) return '$totalMin min';
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  String get distanceText => '${(distanceM / 1000).toStringAsFixed(1)} km';

  RouteOption copyWith({RouteBadge? badge, String? description}) => RouteOption(
        points: points,
        durationSec: durationSec,
        distanceM: distanceM,
        turns: turns,
        origin: origin,
        destination: destination,
        startAddress: startAddress,
        endAddress: endAddress,
        badge: badge ?? this.badge,
        description: description ?? this.description,
      );

  LatLngBounds get bounds {
    var minLat = origin.latitude, maxLat = origin.latitude;
    var minLng = origin.longitude, maxLng = origin.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
