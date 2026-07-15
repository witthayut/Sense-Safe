import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/app_navigation.dart';
import '../../app/maps_config.dart';
import '../../app/theme.dart';
import '../../models/favourite.dart';
import '../../models/place_prediction.dart';
import '../../models/recent_trip.dart';
import '../../models/route_option.dart';
import '../../services/ble_controller.dart';
import '../../services/directions_service.dart';
import '../../services/favourites_controller.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../services/recent_trips_controller.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/section_label.dart';
import 'widgets/full_route_map.dart';
import 'widgets/hints.dart';
import 'widgets/map_preview.dart';
import 'widgets/predictions_list.dart';
import 'widgets/route_card.dart';
import 'widgets/route_search.dart';

/// Routes tab — "Pick your route". Type a destination, fetch alternative
/// driving routes, and choose between the LD-friendly / fastest / fewest-turns
/// options. Origin is the device's current location (with a fallback).
class RouteScreen extends ConsumerStatefulWidget {
  const RouteScreen({super.key});

  @override
  ConsumerState<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends ConsumerState<RouteScreen> {
  final _origin = TextEditingController();
  final _destination = TextEditingController();

  GoogleMapController? _map;
  LatLng _originLatLng = LocationService.fallback;
  bool _useCurrentLocation = true; // origin = device location unless overridden
  bool _locating = true;

  List<RouteOption> _options = const [];
  int _selected = 0;
  bool _loading = false;

  // Autocomplete (shared between the From + To fields).
  List<PlacePrediction> _predictions = const [];
  bool _predictionsForOrigin = false;
  Timer? _debounce;
  bool _suppressNextQuery = false;
  String? _placesError;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _origin.dispose();
    _destination.dispose();
    _map?.dispose();
    super.dispose();
  }

  void _onQuery({required bool forOrigin, required String value}) {
    _predictionsForOrigin = forOrigin;
    if (forOrigin) _useCurrentLocation = false; // typing a custom start
    setState(() {});
    _debounce?.cancel();
    if (_suppressNextQuery) {
      _suppressNextQuery = false;
      return;
    }
    if (value.trim().length < 3) {
      setState(() {
        _predictions = const [];
        _placesError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final preds = await ref.read(placesServiceProvider).autocomplete(value);
        if (mounted) {
          setState(() {
            _predictions = preds;
            _placesError = null;
          });
        }
      } catch (e) {
        // Show a single quiet inline hint instead of a snackbar per keystroke.
        if (mounted) {
          setState(() {
            _predictions = const [];
            _placesError = e.toString().replaceFirst('Exception: ', '');
          });
        }
      }
    });
  }

  void _selectPrediction(PlacePrediction p) {
    _suppressNextQuery = true;
    if (_predictionsForOrigin) {
      _origin.text = p.description;
      _useCurrentLocation = false;
      setState(() => _predictions = const []);
    } else {
      _destination.text = p.description;
      setState(() => _predictions = const []);
      _search();
    }
  }

  void _useMyLocation() {
    setState(() {
      _useCurrentLocation = true;
      _origin.clear();
      _predictions = const [];
    });
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    final result = await ref.read(locationServiceProvider).currentOrFallback();
    if (!mounted) return;
    setState(() {
      _originLatLng = result.latLng;
      _locating = false;
    });
    _moveCamera(CameraUpdate.newLatLngZoom(_originLatLng, 12));
  }

  /// Camera moves are best-effort: the map may be mid-rebuild, so never let a
  /// disposed-controller error bubble up to the user.
  Future<void> _moveCamera(CameraUpdate update) async {
    final map = _map;
    if (map == null) return;
    try {
      await map.animateCamera(update);
    } catch (_) {
      // Map controller not ready / was rebuilt — ignore.
    }
  }

  Future<void> _search() async {
    final dest = _destination.text.trim();
    if (dest.isEmpty || _loading) return;
    if (!_useCurrentLocation && _origin.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    _debounce?.cancel();
    setState(() {
      _loading = true;
      _predictions = const [];
    });
    final originArg = _useCurrentLocation
        ? '${_originLatLng.latitude},${_originLatLng.longitude}'
        : _origin.text.trim();
    try {
      final options = await ref.read(directionsServiceProvider).getRouteOptions(
            origin: originArg,
            destination: dest,
          );
      if (!mounted) return;
      setState(() {
        _options = options;
        _selected = 0;
      });
      await _fitSelected();
    } on DirectionsException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong getting routes.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fitSelected() async {
    if (_options.isEmpty) return;
    await _moveCamera(
      CameraUpdate.newLatLngBounds(_options[_selected].bounds, 50),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  void _cancel() {
    setState(() {
      _options = const [];
      _predictions = const [];
      _placesError = null;
      _destination.clear();
      _origin.clear();
      _useCurrentLocation = true;
    });
  }

  /// Remember this drive for the Home tab's Resume / Recent trips.
  void _recordTrip(RouteOption option) {
    final destination = _destination.text.trim();
    if (destination.isEmpty) return;
    ref.read(recentTripsControllerProvider.notifier).record(RecentTrip(
          destination: destination,
          durationSec: option.durationSec,
          at: DateTime.now(),
        ));
  }

  void _startDrive() {
    final option = _options[_selected];
    final ble = ref.read(bleControllerProvider);
    if (ble.bothConnected) {
      _recordTrip(option);
      context.push('/drive', extra: option);
      return;
    }
    // Haptic guidance needs both bands: offer to connect right here rather
    // than silently starting a drive that can't buzz.
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Wristbands not connected'),
        content: const Text(
          'The drive uses your wristbands to signal turns. '
          'Connect them to start.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sageDark,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(bleControllerProvider.notifier).scanAndConnect();
              if (!mounted) return;
              if (ref.read(bleControllerProvider).bothConnected) {
                _recordTrip(option);
                context.push('/drive', extra: option);
              }
            },
            child: const Text('Connect & start'),
          ),
        ],
      ),
    );
  }

  /// ⭐ on the results header: save the just-searched destination as a
  /// favourite (guaranteed routable — we found routes for it seconds ago),
  /// or remove it if it's already saved.
  void _toggleFavourite() {
    final destination = _destination.text.trim();
    if (destination.isEmpty) return;
    final notifier = ref.read(favouritesControllerProvider.notifier);

    if (notifier.contains(destination)) {
      notifier.removeByDestination(destination);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favourites')),
      );
      return;
    }

    // Suggest a short label from the first part of the place description.
    final labelController =
        TextEditingController(text: destination.split(',').first.trim());
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Save favourite'),
        content: TextField(
          controller: labelController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Short name (e.g. Home, Work)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.sageDark),
            onPressed: () {
              final label = labelController.text.trim();
              if (label.isEmpty) return;
              Navigator.of(dialogContext).pop();
              ref.read(favouritesControllerProvider.notifier).add(
                    Favourite(label: label, destination: destination),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved "$label" to favourites')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openFullMap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullRouteMap(
          origin: _originLatLng,
          options: _options,
          selectedIndex: _selected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // A destination handed over from Home (search / favourite): fill it in,
    // route from current location, and clear the request so it fires once.
    ref.listen<String?>(pendingDestinationProvider, (prev, next) {
      if (next == null || next.trim().isEmpty) return;
      _destination.text = next.trim();
      _useCurrentLocation = true;
      _origin.clear();
      Future.microtask(
          () => ref.read(pendingDestinationProvider.notifier).state = null);
      _search();
    });

    final hasRoutes = _options.isNotEmpty;
    final selected = hasRoutes ? _options[_selected] : null;
    final isFavourite = ref
        .watch(favouritesControllerProvider)
        .any((f) => f.destination == _destination.text.trim());

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              Text('Pick your route',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              const Text(
                'We recommend the LD-Friendly option by default.',
                style: TextStyle(color: AppColors.inkSoft),
              ),
              const SizedBox(height: 16),

              RouteSearch(
                originController: _origin,
                destinationController: _destination,
                useCurrentLocation: _useCurrentLocation,
                loading: _loading,
                onOriginChanged: (v) => _onQuery(forOrigin: true, value: v),
                onDestChanged: (v) => _onQuery(forOrigin: false, value: v),
                onUseMyLocation: _useMyLocation,
                onSearch: _search,
              ),

              if (_predictions.isNotEmpty) ...[
                const SizedBox(height: 8),
                PredictionsList(
                  predictions: _predictions,
                  onSelect: _selectPrediction,
                ),
              ],

              if (_placesError != null) ...[
                const SizedBox(height: 8),
                InlineHint(message: _placesError!),
              ],

              if (!hasMapsApiKey) ...[
                const SizedBox(height: 10),
                const ApiKeyHint(),
              ],

              const SizedBox(height: 14),
              MapPreview(
                origin: _originLatLng,
                options: _options,
                selectedIndex: _selected,
                onCreated: (c) {
                  _map = c;
                  if (!_locating) _fitSelected();
                },
                onExpand: _openFullMap,
              ),

              const SizedBox(height: 20),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasRoutes) ...[
                Row(
                  children: [
                    const SectionLabel('Choose a route'),
                    IconButton(
                      tooltip: isFavourite
                          ? 'Remove from favourites'
                          : 'Save as favourite',
                      visualDensity: VisualDensity.compact,
                      onPressed: _toggleFavourite,
                      icon: Icon(
                        isFavourite ? Icons.star : Icons.star_border,
                        color: isFavourite
                            ? AppColors.warn
                            : AppColors.inkSoft,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Text('${_options.length} options',
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _options.length; i++) ...[
                  RouteCard(
                    option: _options[i],
                    selected: i == _selected,
                    onTap: () {
                      setState(() => _selected = i);
                      _fitSelected();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ] else
                const EmptyHint(),

              const SizedBox(height: 8),
              PillButton(
                label: hasRoutes
                    ? 'Start drive · ${selected!.durationText}'
                    : 'Start drive & Dashcam',
                icon: Icons.navigation,
                onPressed: hasRoutes ? _startDrive : null,
              ),
              const SizedBox(height: 4),
              if (hasRoutes)
                Center(
                  child: TextButton(
                    onPressed: _cancel,
                    child: const Text('Clear'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
