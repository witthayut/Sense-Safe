import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_navigation.dart';
import '../../app/theme.dart';
import '../../models/favourite.dart';
import '../../models/recent_trip.dart';
import '../../services/auth_controller.dart';
import '../../services/ble_controller.dart';
import '../../services/favourites_controller.dart';
import '../../services/recent_trips_controller.dart';
import '../../widgets/section_label.dart';

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

              _HeroStatusCard(ble: ble),

              if (lastTrip != null) ...[
                const SizedBox(height: 14),
                _ResumeCard(
                  trip: lastTrip,
                  onTap: () => _routeTo(lastTrip.destination),
                ),
              ],

              const SizedBox(height: 12),

              _SearchBar(
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
                        child: _RecentTripCard(
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
                const _NoFavouritesHint()
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
                      _FavouriteTile(
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

// ─── Hero wristband status card ───────────────────────────────────────────────

class _HeroStatusCard extends StatelessWidget {
  const _HeroStatusCard({required this.ble});

  final BleState ble;

  @override
  Widget build(BuildContext context) {
    final connected = ble.bothConnected;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.7, -1),
            end: Alignment(0.7, 1),
            colors: [AppColors.sageDark, AppColors.sageDeep],
          ),
        ),
        child: Stack(
          children: [
            // Decorative flourish circle, clipped top-right.
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                        child: const Icon(Icons.watch,
                            size: 24, color: AppColors.onSage),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              connected
                                  ? 'Wristbands connected'
                                  : 'Wristbands not connected',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              connected
                                  ? 'Both bands · HAPU calibrated'
                                  : 'Go to Devices tab to connect',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        connected ? Icons.verified : Icons.bluetooth_disabled,
                        size: 22,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ],
                  ),
                  if (connected) ...[
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroBatteryChip(
                              label: 'LEFT', pct: ble.left.batteryPct),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HeroBatteryChip(
                              label: 'RIGHT', pct: ble.right.batteryPct),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBatteryChip extends StatelessWidget {
  const _HeroBatteryChip({required this.label, required this.pct});

  final String label;
  final int? pct;

  @override
  Widget build(BuildContext context) {
    final level = pct ?? 0;
    final icon = level >= 80
        ? Icons.battery_5_bar
        : level >= 50
            ? Icons.battery_4_bar
            : level >= 20
                ? Icons.battery_2_bar
                : Icons.battery_alert;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.onSage),
              const SizedBox(width: 6),
              Text(
                pct != null ? '$pct%' : '--',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Resume last route card ───────────────────────────────────────────────────

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.trip, required this.onTap});

  final RecentTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.sageSoft, width: 1.5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.sageSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.replay,
                    size: 24, color: AppColors.sageDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RESUME LAST ROUTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      trip.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sageDark,
                ),
                child: const Icon(Icons.arrow_forward,
                    size: 20, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.inkSoft, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSubmit(),
              decoration: const InputDecoration(
                hintText: 'Search a new destination',
                hintStyle:
                    TextStyle(color: AppColors.inkSoft, fontSize: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          Material(
            color: AppColors.sageDark,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onSubmit,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Recent trip card ─────────────────────────────────────────────────────────

class _RecentTripCard extends StatelessWidget {
  const _RecentTripCard({required this.trip, required this.onTap});

  final RecentTrip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.history, size: 20, color: AppColors.sageDark),
              const SizedBox(height: 8),
              Text(
                trip.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                trip.metaText(DateTime.now()),
                style:
                    const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Favourite tile ───────────────────────────────────────────────────────────

class _FavouriteTile extends StatelessWidget {
  const _FavouriteTile({
    required this.favourite,
    required this.onTap,
    required this.onLongPress,
  });

  final Favourite favourite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  IconData get _icon {
    final l = favourite.label.toLowerCase();
    if (l.contains('home') || l.contains('บ้าน')) return Icons.home_outlined;
    if (l.contains('work') || l.contains('งาน')) return Icons.work_outline;
    if (l.contains('school') ||
        l.contains('university') ||
        l.contains('มอ') ||
        l.contains('โรงเรียน')) {
      return Icons.school_outlined;
    }
    return Icons.place_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon, size: 22, color: AppColors.sageDark),
              const SizedBox(height: 7),
              Text(
                favourite.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Empty favourites hint ────────────────────────────────────────────────────

class _NoFavouritesHint extends StatelessWidget {
  const _NoFavouritesHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.star_border, color: AppColors.inkSoft, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No favourites yet — search a route, then tap the star to '
              'save it here.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
