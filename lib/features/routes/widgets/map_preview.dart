import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/theme.dart';
import '../../../models/route_option.dart';

/// Map preview showing every alternative (selected highlighted in sage, the
/// rest in light grey) with a fullscreen button.
class MapPreview extends StatelessWidget {
  const MapPreview({
    super.key,
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
