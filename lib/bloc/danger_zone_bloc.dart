import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../services/vibration_service.dart';
import '../services/danger_zone_api_service.dart';
import '../utils/geometry_utils.dart';
import 'danger_zone_event_state.dart';

/// Background notification tap handler.
@pragma('vm:entry-point')
void notificationTapBackground(notificationResponse) {
  debugPrint('Background notification tapped: ${notificationResponse.payload}');
}

/// BLoC responsible for managing danger zone detection and alerting.
/// Coordinates location monitoring, polygon-based danger detection, API-based checks,
/// and multi-modal alerts (notifications, audio, vibration).
class DangerZoneBloc extends Bloc<DangerZoneEvent, DangerZoneState> {
  final NotificationService _notificationService;
  final AudioService _audioService;
  final VibrationService _vibrationService;  final DangerZoneApiService _apiService;

  // Internal state
  StreamSubscription<Position>? _positionSubscription;
  Timer? _dangerCheckTimer;
  List<List<LatLng>> _dangerousPolygons = [];
  Position? _currentPosition;

  // Configuration
  static const Duration _checkInterval = Duration(seconds: 5);
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update every 5 meters
  );

  DangerZoneBloc({
    NotificationService? notificationService,
    AudioService? audioService,
    VibrationService? vibrationService,
    DangerZoneApiService? apiService,
  })  : _notificationService = notificationService ?? NotificationService(),
        _audioService = audioService ?? AudioService(),
        _vibrationService = vibrationService ?? VibrationService(),
        _apiService = apiService ?? DangerZoneApiService(),
        super(DangerZoneInitial()) {
    
    on<InitializeDangerZoneSystem>(_onInitialize);
    on<UserPositionChangedForDangerZone>(_onPositionChanged);
    on<DisposeDangerZoneSystem>(_onDispose);
    on<_PeriodicDangerCheck>(_onPeriodicCheck);
  }

  /// Initializes the danger zone monitoring system.
  Future<void> _onInitialize(
    InitializeDangerZoneSystem event,
    Emitter<DangerZoneState> emit,
  ) async {
    try {
      emit(DangerZoneLoading());

      _dangerousPolygons = event.dangerousPolygons;

      // Initialize all services
      await _initializeServices();

      // Request location permissions
      final hasLocationPermission = await _requestLocationPermission();
      if (!hasLocationPermission) {
        emit(DangerZoneError('Location permission denied'));
        return;
      }

      // Start location monitoring and periodic checks
      _startLocationMonitoring();
      _startPeriodicChecking();

      emit(const DangerZoneMonitoring(
        isInDangerZone: false,
        hasAlertedForCurrentZone: false,
        currentLocation: null, 
      ));
    } catch (e) {
      debugPrint('Failed to initialize danger zone system: $e');
      emit(DangerZoneError('Initialization failed: $e'));
    }
  }

  /// Handles position updates from the location service.
  void _onPositionChanged(
    UserPositionChangedForDangerZone event,
    Emitter<DangerZoneState> emit,
  ) {
    _currentPosition = event.position;
    debugPrint('Position updated: ${event.position.latitude}, ${event.position.longitude}');
  }

  /// Handles periodic danger zone checks.
  Future<void> _onPeriodicCheck(
    _PeriodicDangerCheck event,
    Emitter<DangerZoneState> emit,
  ) async {
    if (state is! DangerZoneMonitoring || _currentPosition == null) {
      return;
    }

    final currentState = state as DangerZoneMonitoring;
    final userLocation = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    try {
      // Check both polygon-based and API-based danger detection
      final bool inDangerPolygon = _checkPolygonDanger(userLocation);
      final bool nearDangerousRoad = await _checkApiDanger(userLocation);
      final bool isInDanger = inDangerPolygon || nearDangerousRoad;

      debugPrint('Danger check - Polygon: $inDangerPolygon, API: $nearDangerousRoad');

      if (isInDanger && !currentState.hasAlertedForCurrentZone) {
        // Entering danger zone - trigger alerts
        await _triggerDangerAlerts();        emit(currentState.copyWith(
          isInDangerZone: true,
          hasAlertedForCurrentZone: true,
          currentLocation: userLocation, 
        ));
      } else if (!isInDanger && currentState.isInDangerZone) {
        // Exiting danger zone - trigger exit feedback
        await _triggerExitFeedback();
        emit(currentState.copyWith(
          isInDangerZone: false,
          hasAlertedForCurrentZone: false,
          currentLocation: userLocation,
        ));
      }
    } catch (e) {
      debugPrint('Error during danger check: $e');
      // Don't emit error state for periodic check failures
    }
  }

  /// Disposes of the danger zone system and cleans up resources.
  Future<void> _onDispose(
    DisposeDangerZoneSystem event,
    Emitter<DangerZoneState> emit,
  ) async {
    await _cleanup();
    emit(DangerZoneInitial());
  }

  /// Initializes all required services.
  Future<void> _initializeServices() async {
    await Future.wait([
      _notificationService.initialize(
        onNotificationTap: _onNotificationTap,
        onBackgroundNotificationTap: notificationTapBackground,
      ),
      _audioService.initialize(),
      _vibrationService.initialize(),
    ]);
    debugPrint('All danger zone services initialized');
  }

  /// Requests location permissions from the user.
  Future<bool> _requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    final isGranted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    
    debugPrint('Location permission status: $permission');
    return isGranted;
  }

  /// Starts monitoring location changes.
  void _startLocationMonitoring() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      (position) => add(UserPositionChangedForDangerZone(position)),
      onError: (error) => debugPrint('Location stream error: $error'),
    );
    debugPrint('Location monitoring started');
  }

  /// Starts periodic danger zone checking.
  void _startPeriodicChecking() {
    _dangerCheckTimer = Timer.periodic(_checkInterval, (_) {
      add(const _PeriodicDangerCheck());
    });
    debugPrint('Periodic danger checking started');
  }

  /// Checks if the user is in a dangerous polygon.
  bool _checkPolygonDanger(LatLng userLocation) {
    return GeometryUtils.isPointInAnyPolygon(userLocation, _dangerousPolygons);
  }

  /// Checks if the user is near dangerous roads via API.
  Future<bool> _checkApiDanger(LatLng userLocation) async {
    try {
      return await _apiService.isDangerousRoadNearby(userLocation);
    } catch (e) {
      debugPrint('API danger check failed: $e');
      return false; // Fail safe
    }
  }
  /// Triggers all danger zone alerts (notification, audio, vibration).
  Future<void> _triggerDangerAlerts() async {
    debugPrint('Triggering danger zone alerts');

    // Trigger all alerts with individual error handling
    try {
      await _notificationService.showDangerZoneAlert(
        title: 'Warnung: Gefahrenzone',
        body: 'Sie befinden sich in der Nähe einer Gefahrenzone!',
      );
    } catch (e) {
      debugPrint('Notification alert failed: $e');
    }

    try {
      await _audioService.playWarningAlarm();
    } catch (e) {
      debugPrint('Audio alert failed: $e');
    }

    try {
      await _vibrationService.vibrateDangerZoneEntry();
    } catch (e) {
      debugPrint('Vibration alert failed: $e');
    }

    debugPrint('Danger zone alerts triggered');
  }  /// Triggers feedback for exiting a danger zone.
  Future<void> _triggerExitFeedback() async {
    debugPrint('Triggering danger zone exit feedback');

    // Only vibration feedback for exit
    try {
      await _vibrationService.vibrateDangerZoneExit();
    } catch (e) {
      debugPrint('Exit vibration failed: $e');
    }
  }

  /// Handles notification tap events.
  void _onNotificationTap(notificationResponse) {
    debugPrint('Foreground notification tapped: ${notificationResponse.payload}');
    // Add navigation logic here if needed
  }

  /// Cleans up all resources and subscriptions.
  Future<void> _cleanup() async {
    _dangerCheckTimer?.cancel();
    await _positionSubscription?.cancel();
    
    await Future.wait([
      _audioService.dispose(),
      // Note: NotificationService and VibrationService don't need explicit disposal
    ]);

    _apiService.dispose();
    debugPrint('Danger zone system resources cleaned up');
  }

  @override
  Future<void> close() async {
    await _cleanup();
    return super.close();
  }
}

/// Internal event for periodic danger zone checks.
class _PeriodicDangerCheck extends DangerZoneEvent {
  const _PeriodicDangerCheck();

  @override
  List<Object?> get props => [];
}
