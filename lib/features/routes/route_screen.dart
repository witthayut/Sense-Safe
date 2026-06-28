import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/app_navigation.dart';
import '../../app/maps_config.dart';
import '../../app/theme.dart';
import '../../models/place_prediction.dart';
import '../../models/route_option.dart';
import '../../services/directions_service.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../widgets/pill_button.dart';
import '../../widgets/section_label.dart';

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

  void _startDrive() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guided drive + dashcam arrive in a later phase.'),
      ),
    );
  }

  void _openFullMap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _FullRouteMap(
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

              _RouteSearch(
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
                _PredictionsList(
                  predictions: _predictions,
                  onSelect: _selectPrediction,
                ),
              ],

              if (_placesError != null) ...[
                const SizedBox(height: 8),
                _InlineHint(message: _placesError!),
              ],

              if (!hasMapsApiKey) ...[
                const SizedBox(height: 10),
                const _ApiKeyHint(),
              ],

              const SizedBox(height: 14),
              _MapPreview(
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
                    const Spacer(),
                    Text('${_options.length} options',
                        style: const TextStyle(
                            color: AppColors.inkSoft, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _options.length; i++) ...[
                  _RouteCard(
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
                const _EmptyHint(),

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

/// From + To search card. "From" defaults to the device's current location
/// (shown as a hint) but can be typed/picked, with a button to reset it back.
class _RouteSearch extends StatelessWidget {
  const _RouteSearch({
    required this.originController,
    required this.destinationController,
    required this.useCurrentLocation,
    required this.loading,
    required this.onOriginChanged,
    required this.onDestChanged,
    required this.onUseMyLocation,
    required this.onSearch,
  });

  final TextEditingController originController;
  final TextEditingController destinationController;
  final bool useCurrentLocation;
  final bool loading;
  final ValueChanged<String> onOriginChanged;
  final ValueChanged<String> onDestChanged;
  final VoidCallback onUseMyLocation;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Connector rail: origin dot ┊ destination pin ──────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.sageDark, width: 2.5),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.line,
                    ),
                  ),
                  const Icon(Icons.place, color: AppColors.danger, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 14),
            // ── The two fields ────────────────────────────────────────────
            Expanded(
              child: Column(
                children: [
                  _FieldRow(
                    field: TextField(
                      controller: originController,
                      onChanged: onOriginChanged,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: useCurrentLocation
                            ? 'Current location'
                            : 'Start location',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Use my current location',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.gps_fixed,
                        color: useCurrentLocation
                            ? AppColors.sageDark
                            : AppColors.inkSoft,
                        size: 20,
                      ),
                      onPressed: onUseMyLocation,
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  _FieldRow(
                    field: TextField(
                      controller: destinationController,
                      onChanged: onDestChanged,
                      onSubmitted: (_) => onSearch(),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Where to?',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                    trailing: Material(
                      color: AppColors.sageDark,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onSearch,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: loading
                              ? const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row inside the From/To card: a field + a trailing action, with a
/// consistent height so both rows line up with the connector rail.
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field, required this.trailing});

  final Widget field;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Expanded(child: field),
          const SizedBox(width: 4),
          trailing,
        ],
      ),
    );
  }
}

/// Small warn hint shown under the search bar (e.g. autocomplete unavailable).
class _InlineHint extends StatelessWidget {
  const _InlineHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warn, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.ink, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

/// Dropdown of destination suggestions shown under the search bar.
class _PredictionsList extends StatelessWidget {
  const _PredictionsList({required this.predictions, required this.onSelect});

  final List<PlacePrediction> predictions;
  final ValueChanged<PlacePrediction> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < predictions.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.line, indent: 48),
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.place_outlined, color: AppColors.sageDark),
              title: Text(
                predictions[i].description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              onTap: () => onSelect(predictions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// Map preview showing every alternative (selected highlighted in sage, the
/// rest in light grey) with a fullscreen button.
class _MapPreview extends StatelessWidget {
  const _MapPreview({
    required this.origin,
    required this.options,
    required this.selectedIndex,
    required this.onCreated,
    required this.onExpand,
  });

  final LatLng origin;
  final List<RouteOption> options;
  final int selectedIndex;
  final void Function(GoogleMapController) onCreated;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final selected = options.isEmpty
        ? null
        : options[selectedIndex.clamp(0, options.length - 1)];

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 210,
        child: Stack(
          children: [
            GoogleMap(
              key: const ValueKey('route-preview-map'),
              initialCameraPosition: CameraPosition(target: origin, zoom: 12),
              onMapCreated: onCreated,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: {
                if (selected != null)
                  Marker(
                      markerId: const MarkerId('start'),
                      position: selected.origin),
                if (selected != null)
                  Marker(
                      markerId: const MarkerId('dest'),
                      position: selected.destination),
              },
              polylines: {
                // Unselected alternatives, light grey underneath.
                for (var i = 0; i < options.length; i++)
                  if (i != selectedIndex)
                    Polyline(
                      polylineId: PolylineId('alt_$i'),
                      points: options[i].points,
                      color: AppColors.line,
                      width: 5,
                    ),
                if (selected != null)
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: selected.points,
                    color: AppColors.sageDark,
                    width: 6,
                  ),
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: AppColors.card,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onExpand,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.fullscreen,
                        color: AppColors.ink, size: 22),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen map of the routes — selected one highlighted, alternatives in
/// light grey for context.
class _FullRouteMap extends StatefulWidget {
  const _FullRouteMap({
    required this.origin,
    required this.options,
    required this.selectedIndex,
  });

  final LatLng origin;
  final List<RouteOption> options;
  final int selectedIndex;

  @override
  State<_FullRouteMap> createState() => _FullRouteMapState();
}

class _FullRouteMapState extends State<_FullRouteMap> {
  GoogleMapController? _map;

  RouteOption? get _selected => widget.options.isEmpty
      ? null
      : widget.options[widget.selectedIndex.clamp(0, widget.options.length - 1)];

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(
        title: Text(selected != null
            ? '${selected.durationText} · ${selected.distanceText}'
            : 'Map'),
      ),
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: widget.origin, zoom: 12),
        onMapCreated: (c) {
          _map = c;
          if (selected != null) {
            c.animateCamera(CameraUpdate.newLatLngBounds(selected.bounds, 60));
          }
        },
        markers: {
          if (selected != null)
            Marker(
                markerId: const MarkerId('start'), position: selected.origin),
          if (selected != null)
            Marker(
                markerId: const MarkerId('dest'),
                position: selected.destination),
        },
        polylines: {
          // Alternatives in light grey underneath.
          for (var i = 0; i < widget.options.length; i++)
            if (i != widget.selectedIndex)
              Polyline(
                polylineId: PolylineId('alt_$i'),
                points: widget.options[i].points,
                color: AppColors.line,
                width: 5,
              ),
          // Selected route on top.
          if (selected != null)
            Polyline(
              polylineId: const PolylineId('selected'),
              points: selected.points,
              color: AppColors.sageDark,
              width: 7,
            ),
        },
      ),
    );
  }
}

/// Per-badge accent colour + icon for the route cards.
({Color color, IconData icon}) _badgeStyle(RouteBadge badge) => switch (badge) {
      RouteBadge.ldFriendly =>
        (color: AppColors.sageDark, icon: Icons.accessibility_new),
      RouteBadge.fastest => (color: AppColors.warn, icon: Icons.bolt),
      RouteBadge.fewestTurns =>
        (color: AppColors.chartBlue, icon: Icons.turn_slight_right),
      RouteBadge.alternative =>
        (color: AppColors.inkSoft, icon: Icons.alt_route),
    };

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final RouteOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _badgeStyle(option.badge);
    final recommended = option.badge == RouteBadge.ldFriendly;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sageSoft.withValues(alpha: 0.45)
              : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.sageDark : AppColors.line,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0F000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            // Accent icon chip.
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: style.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(style.icon, color: style.color, size: 24),
            ),
            const SizedBox(width: 12),
            // Label + description + metrics.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          option.badge.label.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: style.color,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        const _RecommendedTag(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(option.description,
                      style: const TextStyle(
                          color: AppColors.inkSoft, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.straighten,
                          size: 14, color: AppColors.inkSoft),
                      const SizedBox(width: 4),
                      Text(option.distanceText,
                          style: const TextStyle(
                              color: AppColors.inkSoft, fontSize: 12.5)),
                      const SizedBox(width: 12),
                      const Icon(Icons.turn_slight_right,
                          size: 14, color: AppColors.inkSoft),
                      const SizedBox(width: 4),
                      Text('${option.turns} turns',
                          style: const TextStyle(
                              color: AppColors.inkSoft, fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Duration + selection state.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  option.durationText,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.sageDark : AppColors.line,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedTag extends StatelessWidget {
  const _RecommendedTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.sageDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'RECOMMENDED',
        style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.alt_route, color: AppColors.inkSoft, size: 32),
          SizedBox(height: 10),
          Text(
            'Enter a destination to compare routes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// Shown when no API key is configured yet, so the map appears blank.
class _ApiKeyHint extends StatelessWidget {
  const _ApiKeyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warn.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.key_off_outlined, color: AppColors.warn, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Add your Google Maps API key to load the map and routes.',
              style: TextStyle(color: AppColors.ink, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
