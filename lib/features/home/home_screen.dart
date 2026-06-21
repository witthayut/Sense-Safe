import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../services/auth_controller.dart';
import '../../services/ble_controller.dart';

/// "Where to today?" — wristband status, search bar, favourite destinations.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _darkNavy = Color(0xFF0D1B3E);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final ble = ref.watch(bleControllerProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    const favourites = [
      ('Home', '12 km · 18 min', Icons.home_outlined),
      ('Work', '8 km · 21 min', Icons.work_outline),
      ('University', '26 km · 40 min', Icons.school_outlined),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ── Greeting ──────────────────────────────────────────────────────
          Text(
            'Good afternoon, $firstName',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.sageDark,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Where to today?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _darkNavy,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 20),

          // ── Wristband Status Banner (live from BLE controller) ────────────
          _StatusBanner(connected: ble.bothConnected),

          const SizedBox(height: 16),

          // ── Search Bar with mic button ────────────────────────────────────
          const _SearchBar(),

          const SizedBox(height: 28),

          // ── Favourites ────────────────────────────────────────────────────
          const Text(
            'FAVOURITES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          for (final (name, detail, icon) in favourites)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FavouriteCard(name: name, detail: detail, icon: icon),
            ),
        ],
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
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Pulsing indicator dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: connected
                  ? Colors.green.shade600
                  : Colors.grey.shade400,
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
                    color: Color(0xFF0D1B3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  connected
                      ? 'Ready to drive · HAPU calibrated'
                      : 'Go to Devices tab to connect',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            connected
                ? Icons.verified_user_outlined
                : Icons.bluetooth_disabled,
            color: connected ? AppColors.sageDark : Colors.grey,
            size: 22,
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar with mic ──────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search destination',
                hintStyle:
                    TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.sageDark,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 20),
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
  });

  final String name;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(14),
      ),
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
                    color: Color(0xFF0D1B3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Route preview for "$name" — Phase 4.'),
                backgroundColor: AppColors.sageDark,
                duration: const Duration(seconds: 2),
              ),
            ),
            child: const Text(
              'Go',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.sageDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
