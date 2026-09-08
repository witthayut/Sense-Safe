import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/vibration_profile.dart';
import '../../models/wristband.dart';
import '../../services/assessment_controller.dart';
import '../../services/ble_controller.dart';
import '../../services/cue_scheduler.dart';
import '../../services/haptic_cue_player.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/section_label.dart';

/// Phase 2 — fine-tune the vibration profile the assessment chose:
/// intensity, lead time, and rhythm, with a live preview on the (mock)
/// wristbands. Saving persists to Firestore via the assessment controller,
/// so the next drive immediately uses the new values.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late double _intensity;
  late int _leadTimeSeconds;
  late HapticRhythm _rhythm;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(assessmentControllerProvider).profile;
    _intensity = profile?.intensity ?? 0.6;
    _leadTimeSeconds = profile?.leadTimeSeconds ?? 5;
    _rhythm = profile?.rhythm ?? HapticRhythm.medium;
  }

  /// Play the ALERT pattern with the CURRENT (unsaved) slider values on both
  /// wrists, so the user feels what they're choosing before committing.
  Future<void> _preview() async {
    setState(() => _previewing = true);
    final player = HapticCuePlayer(ref.read(bleControllerProvider.notifier));
    final trial = VibrationProfile(
      scores: const {},
      intensity: _intensity,
      leadTimeSeconds: _leadTimeSeconds,
      rhythm: _rhythm,
      spatialType: '',
    );
    await Future.wait([
      player.playCue(CueStage.alert, Wrist.left, trial),
      player.playCue(CueStage.alert, Wrist.right, trial),
    ]);
    if (mounted) setState(() => _previewing = false);
  }

  void _save() {
    ref.read(assessmentControllerProvider.notifier).updateTuning(
          intensity: _intensity,
          leadTimeSeconds: _leadTimeSeconds,
          rhythm: _rhythm,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Haptic settings saved')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(bleControllerProvider).bothConnected;
    final spatialType =
        ref.watch(assessmentControllerProvider).profile?.spatialType;

    return Scaffold(
      appBar: AppBar(title: const Text('Haptic settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                if (spatialType != null) ...[
                  Text(
                    'Your profile: $spatialType',
                    style: const TextStyle(
                        color: AppColors.inkSoft, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Intensity ─────────────────────────────────────────────
                const SectionLabel('Vibration strength'),
                Row(
                  children: [
                    const Icon(Icons.vibration,
                        color: AppColors.sageDark, size: 20),
                    Expanded(
                      child: Slider(
                        value: _intensity,
                        min: 0.1,
                        max: 1.0,
                        divisions: 18,
                        activeColor: AppColors.sageDark,
                        label: '${(_intensity * 100).round()}%',
                        onChanged: (v) => setState(() => _intensity = v),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${(_intensity * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Lead time ─────────────────────────────────────────────
                const SectionLabel('Warn me before a turn'),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        color: AppColors.sageDark, size: 20),
                    Expanded(
                      child: Slider(
                        value: _leadTimeSeconds.toDouble(),
                        min: 2,
                        max: 10,
                        divisions: 8,
                        activeColor: AppColors.sageDark,
                        label: '$_leadTimeSeconds s',
                        onChanged: (v) =>
                            setState(() => _leadTimeSeconds = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        '${_leadTimeSeconds}s',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 32),
                  child: Text(
                    'Earlier warnings give you more time to prepare.',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Rhythm ────────────────────────────────────────────────
                const SectionLabel('Pulse rhythm'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final rhythm in HapticRhythm.values) ...[
                      Expanded(
                        child: ChoiceChip(
                          label: SizedBox(
                            width: double.infinity,
                            child: Text(
                              rhythm.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _rhythm == rhythm
                                    ? AppColors.sageDark
                                    : AppColors.inkSoft,
                              ),
                            ),
                          ),
                          selected: _rhythm == rhythm,
                          selectedColor: AppColors.sageSoft,
                          backgroundColor: AppColors.surfaceMuted,
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _rhythm = rhythm),
                        ),
                      ),
                      if (rhythm != HapticRhythm.values.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),

                const SizedBox(height: 28),

                // ── Preview + save ────────────────────────────────────────
                PillButton(
                  label: connected
                      ? 'Preview on wristbands'
                      : 'Connect wristbands to preview',
                  icon: Icons.play_arrow_rounded,
                  filled: false,
                  loading: _previewing,
                  onPressed: connected && !_previewing ? _preview : null,
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: 'Save settings',
                  icon: Icons.check_rounded,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
