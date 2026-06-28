import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/assessment_controller.dart';
import '../../services/auth_controller.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/section_label.dart';

/// Profile / account tab — user card, vibration profile, confirm style, logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final profile = ref.watch(assessmentControllerProvider).profile;

    final name = user?.fullName ?? 'Guest';
    final email = user?.email ?? '';
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text(
                'Account & Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),

          const SizedBox(height: 20),

          // ── Profile card with initials avatar ─────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.sageDark,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.inkSoft),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // ── Vibration Profile (from assessment) ───────────────────────────
          const SectionLabel('Vibration profile'),
          const SizedBox(height: 12),

          profile == null
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No profile yet',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.ink),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => context.go('/survey'),
                        child: const Text('Take the 6-question assessment'),
                      ),
                    ],
                  ),
                )
              : _SettingsGroup(
                  rows: [
                    _SettingsRowData(
                      icon: Icons.vibration,
                      label: 'Intensity',
                      value: '${(profile.intensity * 100).round()}%',
                    ),
                    _SettingsRowData(
                      icon: Icons.timer_outlined,
                      label: 'Lead time',
                      value: '${profile.leadTimeSeconds}s',
                    ),
                    _SettingsRowData(
                      icon: Icons.graphic_eq,
                      label: 'Rhythm',
                      value: profile.rhythm.label,
                    ),
                    _SettingsRowData(
                      icon: Icons.psychology_outlined,
                      label: 'Spatial type',
                      value: profile.spatialType,
                    ),
                  ],
                ),

          if (profile != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.push('/results?view=true'),
              child: const Text('View full results'),
            ),
          ],

          const SizedBox(height: 26),

          // ── Confirm Style ─────────────────────────────────────────────────
          const SectionLabel('Confirm style'),
          const SizedBox(height: 12),
          const _SettingsGroup(
            rows: [
              _SettingsRowData(
                icon: Icons.back_hand_outlined,
                label: 'Left turn confirm',
                value: 'Double tap',
              ),
              _SettingsRowData(
                icon: Icons.front_hand_outlined,
                label: 'Right turn confirm',
                value: 'Long buzz',
              ),
              _SettingsRowData(
                icon: Icons.replay,
                label: 'Recalculate',
                value: 'Triple short',
              ),
            ],
          ),

          const SizedBox(height: 32),

          PillButton(
            label: 'Log out',
            icon: Icons.logout,
            filled: false,
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go('/login');
            },
          ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─── Settings Group ───────────────────────────────────────────────────────────

class _SettingsRowData {
  const _SettingsRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.rows});

  final List<_SettingsRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          final isLast = i == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Icon(row.icon, color: AppColors.sageDark, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        row.label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: AppColors.line),
                ),
            ],
          );
        }),
      ),
    );
  }
}
