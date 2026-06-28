import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/assessment/survey_screen.dart';
import '../features/assessment/results_screen.dart';
import '../features/calibration/test_vibration_screen.dart';
import '../features/home/home_shell.dart';
import '../models/wristband.dart';
import '../services/auth_controller.dart';

/// Auth-aware router. Unauthenticated users are bounced to /login;
/// the survey/onboarding/results flow is reachable while signed in.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final signedIn = ref.read(authControllerProvider) != null;
      final loc = state.matchedLocation;
      const authRoutes = {'/login', '/register', '/forgot'};
      final onAuthRoute = authRoutes.contains(loc);

      // Not signed in → only auth screens are allowed.
      if (!signedIn && !onAuthRoute) return '/login';
      // Signed in → only bounce away from /login (so returning users land on
      // home). Register intentionally continues to /survey or /onboarding, so
      // we must NOT redirect it to /home here.
      if (signedIn && loc == '/login') return '/home';
      return null;
    },
    refreshListenable: _AuthListenable(ref),
    routes: [
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/forgot', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const WelcomeScreen()),
      GoRoute(path: '/survey', builder: (c, s) => const SurveyScreen()),
      GoRoute(
        path: '/results',
        builder: (c, s) =>
            ResultsScreen(viewOnly: s.uri.queryParameters['view'] == 'true'),
      ),
      GoRoute(
        path: '/calibrate/:wrist',
        builder: (c, s) {
          final wrist =
              s.pathParameters['wrist'] == 'left' ? Wrist.left : Wrist.right;
          return TestVibrationScreen(wrist: wrist);
        },
      ),
      GoRoute(path: '/home', builder: (c, s) => const HomeShell()),
    ],
  );
});

/// Bridges Riverpod auth changes to go_router's refresh mechanism.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}
