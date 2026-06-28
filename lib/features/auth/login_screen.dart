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
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  bool get _canSubmit =>
      _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  @override
  void dispose() {
    _email.dispose();
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
        .login(_email.text, _password.text);
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
                  Text(
                    'Welcome to Haptic Drive',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ready for a trip?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: AppColors.inkSoft),
                  ),

                  const SizedBox(height: 28),

                  // ── Wristband Illustration ────────────────────────────────
                  Center(
                    child: Image.asset(
                      'assets/images/wristbands.png',
                      height: 180,
                      fit: BoxFit.contain,
                      semanticLabel:
                          'A pair of haptic wristbands, left and right',
                      // Falls back to the drawn illustration if the image
                      // file is missing at assets/images/wristbands.png.
                      errorBuilder: (context, error, stackTrace) =>
                          const _WristbandIllustration(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Email Field (theme-styled) ────────────────────────────
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

                  // ── Password Field (theme-styled) ─────────────────────────
                  TextField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _login(),
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
                    onPressed: _canSubmit ? _login : null,
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

