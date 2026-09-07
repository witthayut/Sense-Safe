import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme.dart';
import '../../../models/route_option.dart';

/// Full-screen map of the routes — selected one highlighted, alternatives in
/// light grey for context.
class FullRouteMap extends StatefulWidget {
  const FullRouteMap({
    super.key,
    required this.origin,
    required this.options,
    required this.selectedIndex,
  });

  final LatLng origin;
  final List<RouteOption> options;
  final int selectedIndex;

  @override
  State<FullRouteMap> createState() => _FullRouteMapState();
}

class _FullRouteMapState extends State<FullRouteMap> {
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
