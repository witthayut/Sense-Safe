import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/assessment_controller.dart';
import '../../services/auth_controller.dart';

/// Profile / account tab — shows the user, their vibration profile summary,
/// and a logout button.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final profile = ref.watch(assessmentControllerProvider).profile;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text('Account & Settings',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.sageSoft,
                child: Icon(Icons.person, color: AppColors.sageDark),
              ),
              title: Text(user?.fullName ?? 'Guest',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('@${user?.username ?? 'guest'}'),
            ),
          ),
          const SizedBox(height: 20),
          const Text('VIBRATION PROFILE',
              style: TextStyle(
                  color: AppColors.inkSoft,
                  letterSpacing: 1.2,
                  fontSize: 12)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: profile == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('No profile yet'),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/survey'),
                          child: const Text('Take the 6-question assessment'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Spatial type', profile.spatialType),
                        _row('Intensity',
                            '${(profile.intensity * 100).round()}%'),
                        _row('Lead time', '${profile.leadTimeSeconds}s'),
                        _row('Rhythm', profile.rhythm.label),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/results'),
                          child: const Text('View full results'),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: AppColors.inkSoft)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
