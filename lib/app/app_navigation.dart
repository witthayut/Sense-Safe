import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected bottom-nav tab in the home shell (0 Home · 1 Devices · 2 Routes ·
/// 3 Profile). Held in a provider so other screens (e.g. Home) can switch tabs.
final homeTabProvider = StateProvider<int>((ref) => 0);

/// Tab indices, named for clarity.
class HomeTab {
  static const home = 0;
  static const devices = 1;
  static const routes = 2;
  static const profile = 3;
}

/// A destination requested from elsewhere (Home search / favourites) for the
/// Routes tab to pick up, fill in, and route to. Cleared once consumed.
final pendingDestinationProvider = StateProvider<String?>((ref) => null);
