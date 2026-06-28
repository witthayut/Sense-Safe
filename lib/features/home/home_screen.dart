import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_navigation.dart';
import '../../app/theme.dart';
import '../../services/auth_controller.dart';
import '../../services/ble_controller.dart';
import '../../widgets/section_label.dart';

/// "Where to today?" — wristband status, search bar, favourite destinations.
/// The search and favourites hand a destination to the Routes tab.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();

  static const _favourites = [
    ('Home', '12 km · 18 min', Icons.home_outlined),
    ('Work', '8 km · 21 min', Icons.work_outline),
    ('University', '26 km · 40 min', Icons.school_outlined),
  ];

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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    final ble = ref.watch(bleControllerProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;

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
                'Where to today?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 20),

              _StatusBanner(connected: ble.bothConnected),

              const SizedBox(height: 16),

              _SearchBar(
                controller: _search,
                onSubmit: () => _routeTo(_search.text),
              ),

              const SizedBox(height: 28),

              const SectionLabel('Favourites'),
              const SizedBox(height: 12),

              for (final (name, detail, icon) in _favourites)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FavouriteCard(
                    name: name,
                    detail: detail,
                    icon: icon,
                    onTap: () => _routeTo(name),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wristband Status Banner ──────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: connected ? Colors.green.shade600 : Colors.grey.shade400,
              shape: BoxShape.circle,
              boxShadow: connected
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected
                      ? 'Wristbands Connected'
                      : 'Wristbands Not Connected',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? 'Ready to drive · HAPU calibrated'
                      : 'Go to Devices tab to connect',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            connected ? Icons.verified_user_outlined : Icons.bluetooth_disabled,
            color: connected ? AppColors.sageDark : Colors.grey,
            size: 22,
          ),
        ],
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
                hintText: 'Search destination',
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

// ─── Favourite Destination Card ───────────────────────────────────────────────

class _FavouriteCard extends StatelessWidget {
  const _FavouriteCard({
    required this.name,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.sageDark, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.sageDark, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style:
                          const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.sageDark),
            ],
          ),
        ),
      ),
    );
  }
}
