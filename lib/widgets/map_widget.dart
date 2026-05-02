import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

class MapWidget extends StatelessWidget {
  final fm.MapController mapController;
  final LatLng? userPosition;
  final double currentZoom;
  final List<LatLng>? routePoints;
  final List<fm.Polygon> dangerZonePolygons;
  final double userHeading;
  final LatLng? destinationPosition;
  final Function(fm.MapPosition, bool) onPositionChanged;
  final VoidCallback onMapReady;

  const MapWidget({
    super.key,
    required this.mapController,
    this.userPosition,
    required this.currentZoom,
    this.routePoints,
    required this.dangerZonePolygons,
    required this.userHeading,
    this.destinationPosition,
    required this.onPositionChanged,
    required this.onMapReady,
  });

  @override
  Widget build(BuildContext context) {
    return fm.FlutterMap(
      mapController: mapController,
      options: fm.MapOptions(
        center: userPosition ?? const LatLng(0, 0),
        zoom: currentZoom,
        onPositionChanged: onPositionChanged,
        onMapReady: onMapReady,
      ),
      children: [
        fm.TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        if (routePoints != null)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: routePoints!,
                color: Colors.blue,
                strokeWidth: 5.0,
              ),
            ],
          ),
        if (dangerZonePolygons.isNotEmpty)
          fm.PolygonLayer(polygons: dangerZonePolygons, polygonCulling: true)
        else
          fm.PolygonLayer(
            polygons: [
              fm.Polygon(
                points: [
                  const LatLng(49.010, 12.098),
                  const LatLng(49.019, 12.098),
                  const LatLng(49.019, 12.102),
                  const LatLng(49.010, 12.102),
                  const LatLng(49.010, 12.098),
                ],
                color: Colors.orange.withOpacity(0.3),
                borderColor: Colors.orange,
                borderStrokeWidth: 3.0,
              ),
            ],
          ),
        fm.MarkerLayer(
          markers: [
            if (userPosition != null)
              fm.Marker(
                width: 60.0,
                height: 60.0,
                point: userPosition!,
                builder: (context) => Transform.rotate(
                  angle: (userHeading) * (math.pi / 180),
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ),
            if (destinationPosition != null)
              fm.Marker(
                width: 60.0,
                height: 60.0,
                point: destinationPosition!,
                builder: (context) =>
                    const Icon(Icons.location_on, color: Colors.red, size: 30),
              ),
            if (routePoints != null &&
                routePoints!.isNotEmpty &&
                destinationPosition == null)
              fm.Marker(
                width: 60.0,
                height: 60.0,
                point: routePoints!.last,
                builder: (context) =>
                    const Icon(Icons.flag, color: Colors.red, size: 30),
              ),
          ],
        ),
      ],
    );
  }
}
