import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../services/auth_controller.dart';
import '../../widgets/pill_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  static const _darkNavy = Color(0xFF0D1B3E);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await ref
        .read(authControllerProvider.notifier)
        .login(_username.text, _password.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
    if (err == null) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // ── Title ──────────────────────────────────────────────────
                  const Text(
                    'Welcome to Haptic Drive',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _darkNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ready for a trip?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: _textSecondary),
                  ),

                  const SizedBox(height: 28),

                  // ── Wristband Illustration (from Tam branch) ──────────────
                  const Center(child: _WristbandIllustration()),

                  const SizedBox(height: 28),

                  // ── Username Field ────────────────────────────────────────
                  _StyledField(
                    controller: _username,
                    hintText: 'Username',
                    icon: Icons.person_outline,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),

                  // ── Password Field ────────────────────────────────────────
                  _StyledField(
                    controller: _password,
                    hintText: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    onSubmitted: (_) => _login(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Sign up / Forgot password row ─────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Sign up'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/forgot'),
                        child: const Text('forgot password?'),
                      ),
                    ],
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.danger)),
                  ],

                  const SizedBox(height: 16),

                  PillButton(
                    label: 'Login',
                    loading: _loading,
                    onPressed: _login,
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

// ─── Wristband Illustration (L/R pair — from Tam branch) ─────────────────────

class _WristbandIllustration extends StatelessWidget {
  const _WristbandIllustration();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      width: 220,
      child: CustomPaint(painter: _WristbandPainter()),
    );
  }
}

class _WristbandPainter extends CustomPainter {
  const _WristbandPainter();

  static const _band = Color(0xFFA8C9C0);
  static const _outline = Color(0xFF2E4A42);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBand = Paint()..color = _band;
    final paintOutline = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    void drawWristband(double cx, String label) {
      final rect =
          Rect.fromCenter(center: Offset(cx, 60), width: 80, height: 100);
      final rrect =
          RRect.fromRectAndRadius(rect, const Radius.circular(40));
      canvas.drawRRect(rrect, paintBand);
      canvas.drawRRect(rrect, paintOutline);

      final dotPaint = Paint()..color = _outline;
      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(cx - 18, 30 + i * 12.0), 2.5, dotPaint);
      }

      final handPaint = Paint()..color = _outline;
      final path = Path();
      const hy = 95.0;
      path.moveTo(cx - 10, hy + 20);
      path.quadraticBezierTo(cx - 14, hy, cx - 8, hy - 10);
      path.lineTo(cx + 8, hy - 10);
      path.quadraticBezierTo(cx + 14, hy, cx + 10, hy + 20);
      path.close();
      canvas.drawPath(path, handPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(cx - textPainter.width / 2, 18 - textPainter.height / 2),
      );
    }

    drawWristband(size.width * 0.32, 'L');
    drawWristband(size.width * 0.68, 'R');
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Styled Input Field (from Tam branch) ────────────────────────────────────

class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  static const _fieldBg = Color(0xFFF4F6FA);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: _textSecondary, fontSize: 15),
          prefixIcon: Icon(icon, color: _textSecondary, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
