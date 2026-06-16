import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/learning_difference.dart';
import '../../services/auth_controller.dart';
import '../../widgets/pill_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final Set<LearningDifference> _selected = {};
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
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
          username: _username.text,
          password: _password.text,
          learningDifferences: _selected,
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err != null) return;

    // "Not sure" → take the survey; otherwise head to device onboarding.
    if (_selected.contains(LearningDifference.notSure) || _selected.isEmpty) {
      context.go('/survey');
    } else {
      context.go('/onboarding');
    }
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
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _fullName,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Full name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _username,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Username'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'Password'),
                ),
                const SizedBox(height: 24),
                Text('Learning Difference',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final d in pickable)
                      _ChoiceChip(
                        label: d.label,
                        selected: _selected.contains(d),
                        onTap: () => setState(() {
                          _selected.contains(d)
                              ? _selected.remove(d)
                              : _selected.add(d);
                          _selected.remove(LearningDifference.notSure);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _NotSureCard(
                  selected: _selected.contains(LearningDifference.notSure),
                  onTap: () => setState(() {
                    _selected
                      ..clear()
                      ..add(LearningDifference.notSure);
                  }),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 24),
                PillButton(
                  label: 'Register',
                  loading: _loading,
                  onPressed: _register,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Already have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageDark : AppColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.sageDark : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.sageSoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.sageDark : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.help_outline, color: AppColors.sageDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("I'm not sure which fits",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text("Answer 6 quick questions & we'll suggest one",
                      style: TextStyle(
                          color: AppColors.inkSoft, fontSize: 13)),
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
