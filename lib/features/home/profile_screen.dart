import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/assessment_controller.dart';
import '../../services/auth_controller.dart';

/// Profile / account tab — user card, vibration profile, confirm style, logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _darkNavy = Color(0xFF0D1B3E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _cardBg = Color(0xFFF4F6FA);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final profile = ref.watch(assessmentControllerProvider).profile;

    final name = user?.fullName ?? 'Guest';
    final username = user?.username ?? 'guest';
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          const Text(
            'Account & Settings',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _darkNavy,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 20),

          // ── Profile card with initials avatar ─────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _cardBg,
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
                          color: _darkNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _textSecondary),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // ── Vibration Profile (from assessment) ───────────────────────────
          const _SectionLabel(label: 'VIBRATION PROFILE'),
          const SizedBox(height: 12),

          profile == null
              ? Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No profile yet',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: _darkNavy),
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
              onPressed: () => context.go('/results'),
              child: const Text('View full results'),
            ),
          ],

          const SizedBox(height: 26),

          // ── Confirm Style ─────────────────────────────────────────────────
          const _SectionLabel(label: 'CONFIRM STYLE'),
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
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
        letterSpacing: 1.2,
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
        color: const Color(0xFFF4F6FA),
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
                          color: Color(0xFF0D1B3E),
                        ),
                      ),
                    ),
                    Text(
                      row.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: Colors.grey.shade300),
                ),
            ],
          );
        }),
      ),
    );
  }
}
