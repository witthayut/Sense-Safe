import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_navigation.dart';
import '../../app/theme.dart';
import '../../models/favourite.dart';
import '../../services/auth_controller.dart';
import '../../services/ble_controller.dart';
import '../../services/favourites_controller.dart';
import '../../services/recent_trips_controller.dart';
import '../../widgets/section_label.dart';
import 'widgets/favourite_tile.dart';
import 'widgets/hero_status_card.dart';
import 'widgets/home_search_bar.dart';
import 'widgets/recent_trip_card.dart';
import 'widgets/resume_card.dart';

/// Home tab — design "1a Readiness Hero": hero wristband status card,
/// one-tap Resume last route, search, recent trips, and favourite tiles.
/// Every actionable element hands a destination to the Routes tab via
/// [pendingDestinationProvider] exactly as before.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Hand a destination to the Routes tab and switch to it.
  void _routeTo(String destination) {
    if (destination.trim().isEmpty) return;
    ref.read(pendingDestinationProvider.notifier).state = destination.trim();
    ref.read(homeTabProvider.notifier).state = HomeTab.routes;
    _search.clear();
    FocusScope.of(context).unfocus();
  }

  /// Long-press a favourite → confirm before removing it.
  void _confirmRemove(Favourite favourite) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove "${favourite.label}"?'),
        content: const Text('You can save it again from the Routes tab.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref
                  .read(favouritesControllerProvider.notifier)
                  .removeByDestination(favourite.destination);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final ble = ref.watch(bleControllerProvider);
    final favourites = ref.watch(favouritesControllerProvider);
    final recents = ref.watch(recentTripsControllerProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;
    final lastTrip = recents.isNotEmpty ? recents.first : null;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              Text(
                'Good afternoon, $firstName',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.sageDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready when you are',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 18),

              HeroStatusCard(ble: ble),

              if (lastTrip != null) ...[
                const SizedBox(height: 14),
                ResumeCard(
                  trip: lastTrip,
                  onTap: () => _routeTo(lastTrip.destination),
                ),
              ],

              const SizedBox(height: 12),

              HomeSearchBar(
                controller: _search,
                onSubmit: () => _routeTo(_search.text),
              ),

              if (recents.isNotEmpty) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    const SectionLabel('Recent trips'),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => ref
                          .read(homeTabProvider.notifier)
                          .state = HomeTab.routes,
                      child: const Text(
                        'See all',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final trip in recents.take(2)) ...[
                      Expanded(
                        child: RecentTripCard(
                          trip: trip,
                          onTap: () => _routeTo(trip.destination),
                        ),
                      ),
                      if (trip != recents.take(2).last)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
              ],

              const SizedBox(height: 20),
              const SectionLabel('Favourites'),
              const SizedBox(height: 11),

              if (favourites.isEmpty)
                const NoFavouritesHint()
              else
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.25,
                  children: [
                    for (final favourite in favourites)
                      FavouriteTile(
                        favourite: favourite,
                        onTap: () => _routeTo(favourite.destination),
                        onLongPress: () => _confirmRemove(favourite),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
