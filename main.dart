import 'package:flutter/material.dart';

void main() {
  runApp(const NavApp());
}

class NavApp extends StatelessWidget {
  const NavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5E20)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Data Models ────────────────────────────────────────────────────────────

class FavoriteDestination {
  final String label;
  final String detail;
  final IconData icon;

  const FavoriteDestination({
    required this.label,
    required this.detail,
    required this.icon,
  });
}

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<FavoriteDestination> _favorites = [
    FavoriteDestination(
      label: 'Home',
      detail: '12 min · 4 turns',
      icon: Icons.home_outlined,
    ),
    FavoriteDestination(
      label: 'Work',
      detail: '18 min · 6 turns',
      icon: Icons.work_outline,
    ),
    FavoriteDestination(
      label: 'Mahidol University',
      detail: '26 min · 9 turns',
      icon: Icons.school_outlined,
    ),
  ];

  static const _green = Color(0xFF1B7A3E);
  static const _lightGreen = Color(0xFF4CAF50);
  static const _darkNavy = Color(0xFF0D1B3E);
  static const _cardBg = Color(0xFFF4F6FA);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting ──────────────────────────────────────────
                    Text(
                      'Good afternoon, Alex',
                      style: TextStyle(
                        fontSize: 14,
                        color: _green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where to today?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _darkNavy,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Wristband Status ──────────────────────────────────
                    _StatusBanner(),

                    const SizedBox(height: 16),

                    // ── Search Bar ────────────────────────────────────────
                    _SearchBar(),

                    const SizedBox(height: 28),

                    // ── Favorites Section ─────────────────────────────────
                    Text(
                      'FAVORITES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._favorites.map(
                      (dest) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FavoriteCard(destination: dest),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Navigation ─────────────────────────────────────────
            _BottomNav(
              selectedIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Wristband Status Banner ─────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  static const _green = Color(0xFF1B7A3E);
  static const _cardBg = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Pulsing green dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Wristbands Connected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D1B3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ready to drive · HAPU calibrated',
                  style: TextStyle(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.verified_user_outlined, color: _green, size: 22),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  static const _green = Color(0xFF1B7A3E);
  static const _cardBg = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: const Color(0xFF9CA3AF), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search destination',
                hintStyle: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 15,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          // Microphone button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Favorite Destination Card ───────────────────────────────────────────────

class _FavoriteCard extends StatelessWidget {
  final FavoriteDestination destination;

  const _FavoriteCard({required this.destination});

  static const _green = Color(0xFF1B7A3E);
  static const _cardBg = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              border: Border.all(color: _green, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(destination.icon, color: _green, size: 22),
          ),
          const SizedBox(width: 14),

          // Label + detail
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destination.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Go button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Navigating to ${destination.label}…'),
                  backgroundColor: _green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              'Go',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ───────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _green = Color(0xFF1B7A3E);
  static const _inactive = Color(0xFF9CA3AF);

  static const _items = [
    (icon: Icons.home_outlined, label: 'Home'),
    (icon: Icons.watch_outlined, label: 'Devices'),
    (icon: Icons.explore_outlined, label: 'Routes'),
    (icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  color: selected ? _green : _inactive,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? _green : _inactive,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}