import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import '../widgets/danger_zone_alert_system.dart';
import '../widgets/destination_nav_panel.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_stride/bloc/navigation_bloc.dart';
import 'package:safe_stride/bloc/navigation_event.dart';
import 'package:safe_stride/bloc/navigation_state.dart';
import 'package:safe_stride/services/location_service.dart';
import 'package:safe_stride/services/routing_service.dart';
import 'package:safe_stride/services/danger_zone_service.dart';
import 'package:safe_stride/services/predictive_alert_service.dart';

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavigationBloc(
        locationService: LocationService(),
        routingService: RoutingService(),
        dangerZoneService: DangerZoneService(),
      )..add(InitializeNavigation()),
      child: const _NavigationPageView(),
    );
  }
}

class _NavigationPageView extends StatefulWidget {
  const _NavigationPageView();

  @override
  State<_NavigationPageView> createState() => _NavigationPageViewState();
}

class _NavigationPageViewState extends State<_NavigationPageView> {
  final fm.MapController _mapController = fm.MapController();
  double _currentZoom = 15.0;

  // Danger zone polygons passed to the alert system (fixed test area).
  static const List<List<LatLng>> _dangerousPolygons = [
    [
      LatLng(49.010, 12.098),
      LatLng(49.019, 12.098),
      LatLng(49.019, 12.102),
      LatLng(49.010, 12.102),
      LatLng(49.010, 12.098),
    ],
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF4FC3F7), size: 20),
            SizedBox(width: 8),
            Text(
              'Safe Navigation',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<NavigationBloc, NavigationState>(
            builder: (context, state) {
              if (!state.isNavigating) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Chip(
                  backgroundColor: const Color(0xFF00C853),
                  label: const Text(
                    'NAVIGATING',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                  avatar: const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 14),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<NavigationBloc, NavigationState>(
        listener: (context, state) {
          if (state.error != null && state.error!.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          if (state.isMapReady && state.userPosition != null) {
            try {
              _mapController.move(
                  state.userPosition!, _mapController.zoom);
            } catch (_) {}
          }
        },
        builder: (context, state) {
          if (state.pageLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Initialising…',
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          final dangerReport = state.routeDangerReport;
          final dangerReason = dangerReport?.isDangerous == true
              ? dangerReport!.reason
              : null;

          return Column(
            children: [
              // ── Danger alert system (hidden debug strip) ───────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: DangerZoneAlertSystem(
                  showDebugInfo: true,
                  dangerousPolygons: _dangerousPolygons,
                  dangerReason: dangerReason,
                ),
              ),

              // ── Predictive alert ribbon ────────────────────────────────
              if (state.predictiveAlert.level != PredictiveAlertLevel.none)
                _PredictiveRibbon(alert: state.predictiveAlert),

              // ── Destination nav panel (search + banner + step card) ────
              const DestinationNavPanel(),

              // ── Map ────────────────────────────────────────────────────
              Expanded(
                child: _buildMap(context, state),
              ),
            ],
          );
        },
      ),
      floatingActionButton: BlocBuilder<NavigationBloc, NavigationState>(
        builder: (context, state) {
          if (state.userPosition == null) return const SizedBox.shrink();
          return FloatingActionButton(
            heroTag: 'reset_map_view',
            onPressed: () {
              if (state.userPosition != null) {
                _mapController.move(state.userPosition!, _currentZoom);
              }
            },
            tooltip: 'Centre map on my location',
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.my_location_rounded, color: Colors.white),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildMap(BuildContext context, NavigationState state) {
    if (state.userPosition == null && !state.pageLoading) {
      return const Center(
        child: Text('Waiting for GPS…',
            style: TextStyle(color: Colors.white54)),
      );
    }

    // Danger segments from the route analysis
    final dangerSegments = state.routeDangerReport?.dangerSegments ?? [];

    return fm.FlutterMap(
      mapController: _mapController,
      options: fm.MapOptions(
        center: state.userPosition ?? const LatLng(49.014, 12.100),
        zoom: _currentZoom,
        maxZoom: 18,
        interactiveFlags: fm.InteractiveFlag.all,
        onMapReady: () {
          context.read<NavigationBloc>().add(MapReady());
        },
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && position.zoom != null) {
            _currentZoom = position.zoom!;
          }
        },
      ),
      children: [
        // Base tile layer
        fm.TileLayer(
          urlTemplate:
              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),

        // Safe route (blue)
        if (state.routePoints != null && state.routePoints!.isNotEmpty)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: state.routePoints!,
                strokeWidth: 5.0,
                color: const Color(0xFF1E88E5),
              ),
            ],
          ),

        // Dangerous segments (red, thicker, on top)
        if (dangerSegments.isNotEmpty)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: dangerSegments,
                strokeWidth: 7.0,
                color: Colors.red.withOpacity(0.85),
              ),
            ],
          ),

        // Danger zone polygons loaded from asset
        if (state.dangerZonePolygons.isNotEmpty)
          fm.PolygonLayer(polygons: state.dangerZonePolygons),

        // Danger zone markers
        if (state.dangerZoneMarkers.isNotEmpty)
          fm.MarkerLayer(markers: state.dangerZoneMarkers),

        // User location marker
        if (state.userPosition != null)
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                width: 56,
                height: 56,
                point: state.userPosition!,
                builder: (ctx) => Transform.rotate(
                  angle: state.compassHeading != null
                      ? state.compassHeading! * (3.14159265359 / 180)
                      : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E88E5).withOpacity(0.15),
                      border: Border.all(
                          color: const Color(0xFF1E88E5), width: 2),
                    ),
                    child: const Icon(Icons.navigation_rounded,
                        color: Color(0xFF1E88E5), size: 26),
                  ),
                ),
              ),
            ],
          ),

        // Destination marker
        if (state.destinationPosition != null)
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                width: 60,
                height: 60,
                point: state.destinationPosition!,
                builder: (ctx) => Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        state.destinationAddress ?? 'Destination',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.location_on_rounded,
                        color: Colors.red, size: 28),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Predictive Ribbon – shown below the app bar when a danger zone is ahead
// ─────────────────────────────────────────────────────────────────────────────

class _PredictiveRibbon extends StatefulWidget {
  final PredictiveAlert alert;
  const _PredictiveRibbon({required this.alert});

  @override
  State<_PredictiveRibbon> createState() => _PredictiveRibbonState();
}

class _PredictiveRibbonState extends State<_PredictiveRibbon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.7, end: 1.0).animate(_pulse);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isImminent =
        widget.alert.level == PredictiveAlertLevel.imminent;

    final Color bg =
        isImminent ? const Color(0xFFB71C1C) : const Color(0xFFE65100);

    return FadeTransition(
      opacity: _opacity,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: bg.withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              isImminent
                  ? Icons.warning_rounded
                  : Icons.sensors_rounded,
              color: Colors.amberAccent,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.alert.uiLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
