import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/learning_difference.dart';
import '../../services/assessment_controller.dart';
import '../../services/auth_controller.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/section_label.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final Set<LearningDifference> _selected = {};
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  bool get _canSubmit =>
      _fullName.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref.read(authControllerProvider.notifier).register(
          fullName: _fullName.text,
          email: _email.text,
          password: _password.text,
          learningDifferences: _selected,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err != null) return;

    // "Not sure" → take the survey to discover a profile.
    // Knows their type → build the profile straight from it (no survey).
    if (_selected.contains(LearningDifference.notSure) || _selected.isEmpty) {
      context.go('/survey');
    } else {
      ref
          .read(assessmentControllerProvider.notifier)
          .applyFromLearningDifferences(_selected);
      context.go('/onboarding');
    }
  }

  void _toggle(LearningDifference d) {
    setState(() {
      _selected.contains(d) ? _selected.remove(d) : _selected.add(d);
      _selected.remove(LearningDifference.notSure);
    });
  }

  @override
  Widget build(BuildContext context) {
    const pickable = [
      LearningDifference.dyslexia,
      LearningDifference.adhd,
      LearningDifference.dyscalculia,
      LearningDifference.dyspraxia,
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.sageSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_alt_1,
                          color: AppColors.sageDark, size: 30),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A few details to personalise your haptic guidance.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 28),

                  // ── Fields ────────────────────────────────────────────────
                  TextField(
                    controller: _fullName,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _email,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.inkSoft,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Learning difference ───────────────────────────────────
                  const SectionLabel('Learning difference'),
                  const SizedBox(height: 4),
                  const Text(
                    'Select any that apply — or tap below if you’re unsure.',
                    style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final d in pickable)
                        _ChoiceChip(
                          label: d.label,
                          selected: _selected.contains(d),
                          onTap: () => _toggle(d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _NotSureCard(
                    selected: _selected.contains(LearningDifference.notSure),
                    onTap: () => setState(() {
                      _selected
                        ..clear()
                        ..add(LearningDifference.notSure);
                    }),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style:
                                  const TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),
                  PillButton(
                    label: 'Register',
                    icon: Icons.arrow_forward,
                    loading: _loading,
                    onPressed: _canSubmit ? _register : null,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Already have an account? Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selectable pill for a learning-difference option. Shows a check when picked.
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(
          left: selected ? 14 : 20,
          right: 20,
          top: 12,
          bottom: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageDark : AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.sageDark : AppColors.line,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, color: Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotSureCard extends StatelessWidget {
  const _NotSureCard({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageSoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.sageDark : AppColors.line,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.sageSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline,
                  color: AppColors.sageDark, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("I'm not sure which fits",
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text("Answer 6 quick questions & we'll suggest one",
                      style:
                          TextStyle(color: AppColors.inkSoft, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}
