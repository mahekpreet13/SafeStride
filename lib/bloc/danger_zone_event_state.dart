import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Base class for all danger zone-related events.
abstract class DangerZoneEvent extends Equatable {
  const DangerZoneEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the danger zone monitoring system with defined polygons.
class InitializeDangerZoneSystem extends DangerZoneEvent {
  /// List of polygonal regions that define the danger zones.
  final List<List<LatLng>> dangerousPolygons;

  const InitializeDangerZoneSystem(this.dangerousPolygons);

  @override
  List<Object?> get props => [dangerousPolygons];
}

/// Event emitted when the user's GPS position changes.
class UserPositionChangedForDangerZone extends DangerZoneEvent {
  /// The updated user position.
  final Position position;

  const UserPositionChangedForDangerZone(this.position);

  @override
  List<Object?> get props => [position];
}

/// Event to dispose of resources and stop monitoring.
class DisposeDangerZoneSystem extends DangerZoneEvent {}

/// Base class for all danger zone-related states.
abstract class DangerZoneState extends Equatable {
  const DangerZoneState();

  @override
  List<Object?> get props => [];
}

/// Initial state before monitoring begins.
class DangerZoneInitial extends DangerZoneState {}

/// State representing the loading phase during danger zone system initialization.
class DangerZoneLoading extends DangerZoneState {}

/// State representing active monitoring of danger zones.
class DangerZoneMonitoring extends DangerZoneState {
  /// Whether the user is currently inside a danger zone.
  final bool isInDangerZone;

  /// Whether an alert has already been issued for the current zone.
  final bool hasAlertedForCurrentZone;

  /// The user's current location.
  final LatLng? currentLocation;

  const DangerZoneMonitoring({
    required this.isInDangerZone,
    required this.hasAlertedForCurrentZone,
     this.currentLocation,
  });

  @override
  List<Object?> get props => [isInDangerZone, hasAlertedForCurrentZone, currentLocation];

  /// Returns a copy of this state with updated properties.
DangerZoneMonitoring copyWith({
  bool? isInDangerZone,
  bool? hasAlertedForCurrentZone,
  LatLng? currentLocation,
}) {
  return DangerZoneMonitoring(
    isInDangerZone: isInDangerZone ?? this.isInDangerZone,
    hasAlertedForCurrentZone:
        hasAlertedForCurrentZone ?? this.hasAlertedForCurrentZone,
    currentLocation: currentLocation ?? this.currentLocation,
  );
}
}

/// State representing an error during danger zone monitoring.
class DangerZoneError extends DangerZoneState {
  /// Description of the error encountered.
  final String message;

  const DangerZoneError(this.message);

  @override
  List<Object?> get props => [message];
}
