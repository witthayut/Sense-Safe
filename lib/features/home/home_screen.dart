import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../services/auth_controller.dart';

/// "Where to today?" — search + favourite destinations.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final firstName = (user?.fullName ?? 'there').split(' ').first;

    final favourites = [
      ('Home', '12 km · 18 min', Icons.home_outlined),
      ('Work', '8 km · 21 min', Icons.work_outline),
      ('University', '26 km · 40 min', Icons.school_outlined),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text('Good afternoon, $firstName',
              style: const TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text('Where to today?',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search destination',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.sageDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('FAVOURITES',
              style: TextStyle(
                  color: AppColors.inkSoft,
                  letterSpacing: 1.2,
                  fontSize: 12)),
          const SizedBox(height: 8),
          for (final (name, detail, icon) in favourites)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  leading: Icon(icon, color: AppColors.sageDark),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(detail),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Route preview for "$name" — Phase 4.'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
