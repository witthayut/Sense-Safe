import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/maps_config.dart';
import '../models/route_option.dart';
import 'directions_common.dart';
import 'directions_fetch.dart';

// Re-export so screens can catch DirectionsException via this file.
export 'directions_common.dart' show DirectionsException;

/// Fetches alternative driving routes (platform-appropriately) and classifies
/// them into LD-friendly / fastest / fewest-turns [RouteOption]s.
class DirectionsService {
  const DirectionsService();

  /// [origin] may be "lat,lng" (current location) or an address; [destination]
  /// is an address/place.
  Future<List<RouteOption>> getRouteOptions({
    required String origin,
    required String destination,
  }) async {
    if (!hasMapsApiKey) {
      throw const DirectionsException(
        'No Google Maps API key set. Add it in lib/app/maps_config.dart.',
      );
    }

    final raw = await fetchRawRoutes(
      origin: origin,
      destination: destination,
      apiKey: googleMapsApiKey,
    );
    if (raw.isEmpty) {
      throw const DirectionsException('No routes found to that destination.');
    }
    return _classify(raw);
  }

  /// Assigns one distinct badge per route, then orders LD-friendly → fastest
  /// → fewest turns → alternatives.
  List<RouteOption> _classify(List<RawRoute> routes) {
    final remaining = List<int>.generate(routes.length, (i) => i);
    final badges = <int, RouteBadge>{};

    int pick(double Function(RawRoute) score) {
      var best = remaining.first;
      for (final i in remaining) {
        if (score(routes[i]) < score(routes[best])) best = i;
      }
      remaining.remove(best);
      return best;
    }

    if (remaining.isNotEmpty) {
      // LD-friendly: fewest turns, lightly weighted by time.
      badges[pick((r) => r.turns + r.durationSec / 600.0)] =
          RouteBadge.ldFriendly;
    }
    if (remaining.isNotEmpty) {
      badges[pick((r) => r.durationSec.toDouble())] = RouteBadge.fastest;
    }
    if (remaining.isNotEmpty) {
      badges[pick((r) => r.turns.toDouble())] = RouteBadge.fewestTurns;
    }
    for (final i in remaining) {
      badges[i] = RouteBadge.alternative;
    }

    final options = [
      for (var i = 0; i < routes.length; i++)
        _toOption(routes[i], badges[i] ?? RouteBadge.alternative),
    ];

    const order = {
      RouteBadge.ldFriendly: 0,
      RouteBadge.fastest: 1,
      RouteBadge.fewestTurns: 2,
      RouteBadge.alternative: 3,
    };
    options.sort((a, b) => order[a.badge]!.compareTo(order[b.badge]!));
    return options;
  }

  RouteOption _toOption(RawRoute r, RouteBadge badge) {
    final description = switch (badge) {
      RouteBadge.ldFriendly => 'Fewer turns · simpler decisions',
      RouteBadge.fastest => 'Shortest time · ${r.turns} turns',
      RouteBadge.fewestTurns => 'Long straight roads · ${r.turns} turns',
      RouteBadge.alternative => '${r.turns} turns',
    };
    return RouteOption(
      points: r.points,
      durationSec: r.durationSec,
      distanceM: r.distanceM,
      turns: r.turns,
      origin: r.origin,
      destination: r.destination,
      startAddress: r.startAddress,
      endAddress: r.endAddress,
      badge: badge,
      description: description,
      maneuvers: r.maneuvers,
    );
  }
}

final directionsServiceProvider =
    Provider<DirectionsService>((ref) => const DirectionsService());
