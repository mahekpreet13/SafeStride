import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:safe_stride/bloc/navigation_event.dart';
import 'package:safe_stride/bloc/navigation_state.dart';
import 'package:safe_stride/services/location_service.dart';
import 'package:safe_stride/services/routing_service.dart';
import 'package:safe_stride/services/danger_zone_service.dart';
import 'package:safe_stride/services/route_danger_analysis_service.dart';
import 'package:safe_stride/services/predictive_alert_service.dart';
import 'package:safe_stride/services/navigation_voice_service.dart';
import 'package:safe_stride/utils/polyline_decoder.dart';

/// BLoC responsible for handling navigation, routing, and danger zone logic.
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  final LocationService _locationService;
  final RoutingService _routingService;
  final DangerZoneService _dangerZoneService;
  final RouteDangerAnalysisService _dangerAnalysisService;
  final PredictiveAlertService _predictiveService;

  // Danger polygons + scores cached for predictive checks
  List<List<LatLng>> _rawDangerPolygons = [];
  List<int> _rawDangerScores = [];

  NavigationBloc({
    required LocationService locationService,
    required RoutingService routingService,
    required DangerZoneService dangerZoneService,
    RouteDangerAnalysisService? dangerAnalysisService,
    PredictiveAlertService? predictiveAlertService,
  }) : _locationService = locationService,
       _routingService = routingService,
       _dangerZoneService = dangerZoneService,
       _dangerAnalysisService =
           dangerAnalysisService ?? RouteDangerAnalysisService(),
       _predictiveService =
           predictiveAlertService ?? PredictiveAlertService(),
       super(const NavigationState()) {
    // Initialise shared voice service
    navigationVoice.initialize();
    on<InitializeNavigation>(_onInitializeNavigation);
    on<UpdateUserPosition>(_onUpdateUserPosition);
    on<UpdateCompassHeading>(_onUpdateCompassHeading);
    on<SearchAddress>(_onSearchAddress);
    on<SelectSuggestion>(_onSelectSuggestion);
    on<FetchRoute>(_onFetchRoute);
    on<ToggleCompassMode>(_onToggleCompassMode);
    on<UpdateSuggestions>(_onUpdateSuggestions);
    on<PageLoaded>(_onPageLoaded);
    on<RouteLoadingChanged>(_onRouteLoadingChanged);
    on<ErrorOccurred>(_onErrorOccurred);
    on<RoutePointsUpdated>(_onRoutePointsUpdated);
    on<InstructionsUpdated>(_onInstructionsUpdated);
    on<DestinationPositionUpdated>(_onDestinationPositionUpdated);
    on<DangerZonesLoaded>(_onDangerZonesLoaded);
    on<DangerZoneMarkersUpdated>(_onDangerZoneMarkersUpdated);
    on<ShowSuggestionsChanged>(_onShowSuggestionsChanged);
    on<SuggestionsUpdated>(_onSuggestionsUpdated);
    on<MapReady>(_onMapReady);
    on<RouteDangerReportUpdated>(_onRouteDangerReportUpdated);
    on<StartNavigation>(_onStartNavigation);
    on<StopNavigation>(_onStopNavigation);
    on<DestinationAddressChanged>(_onDestinationAddressChanged);
    on<PredictiveAlertUpdated>(_onPredictiveAlertUpdated);
    on<UserSpeedUpdated>(_onUserSpeedUpdated);
  }

  /// Initializes navigation system, location listeners, and danger zones.
  Future<void> _onInitializeNavigation(
    InitializeNavigation event,
    Emitter<NavigationState> emit,
  ) async {
    emit(state.copyWith(pageLoading: true, error: null));
    await _locationService.initializeLocationAndCompass(
      onPositionUpdate: (position) => add(UpdateUserPosition(position)),
      onCompassUpdate: (heading) => add(UpdateCompassHeading(heading)),
      onError: (error) => add(ErrorOccurred(error)),
    );
    try {
      final dangerZones = await _dangerZoneService.loadDangerZones();
      add(DangerZonesLoaded(dangerZones));

      if (state.userPosition != null) {
        await _fetchInitialRoute(emit);
      }
    } catch (e) {
      add(ErrorOccurred('Failed to load danger zones: $e'));
    }
    add(PageLoaded());
  }

  /// Sets state indicating the map is ready for interaction.
  void _onMapReady(MapReady event, Emitter<NavigationState> emit) {
    emit(state.copyWith(isMapReady: true));
  }

  /// Updates state with new user position and runs predictive alert check.
  void _onUpdateUserPosition(
    UpdateUserPosition event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(userPosition: event.userPosition));

    // Run predictive check if we have heading and danger polygons
    if (_rawDangerPolygons.isNotEmpty) {
      final heading = state.compassHeading ?? 0.0;
      final alert = _predictiveService.check(
        position: event.userPosition,
        headingDeg: heading,
        speedMps: state.userSpeedMps,
        dangerPolygons: _rawDangerPolygons,
        dangerScores: _rawDangerScores,
      );
      add(PredictiveAlertUpdated(alert));

      // Voice the predictive alert through the shared service
      if (alert.level != PredictiveAlertLevel.none) {
        final priority = alert.level == PredictiveAlertLevel.imminent
            ? VoicePriority.critical
            : VoicePriority.safety;
        navigationVoice.speak(alert.voiceMessage, priority);
      }
    }
  }

  /// Updates state with new compass heading.
  void _onUpdateCompassHeading(
    UpdateCompassHeading event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(compassHeading: event.heading));
  }

  /// Handles address search, geocoding, and route fetching to result.
  Future<void> _onSearchAddress(
    SearchAddress event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.userPosition == null) {
      add(
        ErrorOccurred(
          "Current location not available. Cannot search for a route.",
        ),
      );
      return;
    }
    add(RouteLoadingChanged(true));
    add(ErrorOccurred(null));
    add(RoutePointsUpdated(null));
    add(InstructionsUpdated([]));

    try {
      final destination = await _routingService.geocodeAddress(event.address);
      if (destination == null) {
        add(ErrorOccurred('Address not found.'));
        add(RouteLoadingChanged(false));
        return;
      }
      add(DestinationPositionUpdated(destination));
      await _fetchRouteInternal(state.userPosition!, destination, emit);
    } catch (e) {
      add(ErrorOccurred('Error: $e'));
    }
    add(RouteLoadingChanged(false));
  }

  /// Handles selection of a suggestion (auto-completes search).
  Future<void> _onSelectSuggestion(
    SelectSuggestion event,
    Emitter<NavigationState> emit,
  ) async {
    add(ShowSuggestionsChanged(false));
    add(SearchAddress(event.suggestion));
  }

  /// Fetches a route between user and selected destination.
  Future<void> _onFetchRoute(
    FetchRoute event,
    Emitter<NavigationState> emit,
  ) async {
    if (state.userPosition == null || state.destinationPosition == null) {
      add(ErrorOccurred("User location or destination not available."));
      return;
    }
    add(RouteLoadingChanged(true));
    await _fetchRouteInternal(
      state.userPosition!,
      state.destinationPosition!,
      emit,
    );
    add(RouteLoadingChanged(false));
  }

  /// Fetches the initial route from user position to default destination.
  Future<void> _fetchInitialRoute(Emitter<NavigationState> emit) async {
    if (state.userPosition == null) {
      add(ErrorOccurred("User location not available to fetch initial route."));
      return;
    }

    const initialDestination = LatLng(49.019, 12.102);
    add(DestinationPositionUpdated(initialDestination));
    await _fetchRouteInternal(state.userPosition!, initialDestination, emit);
  }

  /// Fetches route data between [start] and [end] and updates state.
  Future<void> _fetchRouteInternal(
    LatLng start,
    LatLng end,
    Emitter<NavigationState> emit,
  ) async {
    try {
      final routeData = await _routingService.fetchRoute(
        start: start,
        end: end,
      );
      final path = routeData['paths'][0];
      final points = path['points'];
      final decoded = decodePolyline(points);
      add(RoutePointsUpdated(decoded));
      add(InstructionsUpdated(path['instructions'] ?? []));

      // Analyse the route for danger zones
      try {
        final report = await _dangerAnalysisService.analyse(decoded);
        add(RouteDangerReportUpdated(report));
      } catch (e) {
        debugPrint('Danger analysis failed (non-fatal): $e');
      }
    } catch (e) {
      add(ErrorOccurred('Failed to fetch route: $e'));
    }
  }

  /// Toggles compass mode for navigation.
  void _onToggleCompassMode(
    ToggleCompassMode event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(compassMode: !state.compassMode));
  }

  /// Updates address suggestions based on user input.
  Future<void> _onUpdateSuggestions(
    UpdateSuggestions event,
    Emitter<NavigationState> emit,
  ) async {
    if (event.input.isEmpty) {
      add(SuggestionsUpdated([]));
      add(ShowSuggestionsChanged(false));
      return;
    }
    try {
      final suggestions = await _routingService.fetchSuggestions(event.input);
      add(SuggestionsUpdated(suggestions));
      add(ShowSuggestionsChanged(suggestions.isNotEmpty));
    } catch (e) {
      debugPrint("Error fetching suggestions: $e");
    }
  }

  /// Marks that the page has finished loading.
  void _onPageLoaded(PageLoaded event, Emitter<NavigationState> emit) {
    emit(state.copyWith(pageLoading: false));
  }

  /// Updates route loading state.
  void _onRouteLoadingChanged(
    RouteLoadingChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(routeLoading: event.isLoading));
  }

  /// Sets an error state with message.
  void _onErrorOccurred(ErrorOccurred event, Emitter<NavigationState> emit) {
    emit(state.copyWith(error: event.error, status: NavigationStatus.error));
  }

  /// Updates state with new route points for display.
  void _onRoutePointsUpdated(
    RoutePointsUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(routePoints: event.routePoints));
  }

  /// Updates navigation instructions.
  void _onInstructionsUpdated(
    InstructionsUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(instructions: event.instructions));
  }

  /// Updates selected destination position.
  void _onDestinationPositionUpdated(
    DestinationPositionUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(destinationPosition: event.destinationPosition));
  }

  /// Loads danger zone polygons into state and caches raw data for predictive checks.
  void _onDangerZonesLoaded(
    DangerZonesLoaded event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(dangerZonePolygons: event.dangerZonePolygons));
    // The raw polygon points are extracted from the fm.Polygon objects
    // so the predictive service (which uses LatLng lists) can access them.
    _rawDangerPolygons =
        event.dangerZonePolygons.map((p) => List<LatLng>.from(p.points)).toList();
    _rawDangerScores = List.filled(_rawDangerPolygons.length, 5);
    debugPrint('[NavBloc] Cached ${_rawDangerPolygons.length} danger polygons for predictive alerts');
  }

  /// Updates state with new danger zone markers for the map.
  void _onDangerZoneMarkersUpdated(
    DangerZoneMarkersUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(dangerZoneMarkers: event.dangerZoneMarkers));
  }

  /// Updates whether address suggestions should be shown.
  void _onShowSuggestionsChanged(
    ShowSuggestionsChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(showSuggestions: event.showSuggestions));
  }

  /// Updates suggestions in the UI.
  void _onSuggestionsUpdated(
    SuggestionsUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(suggestions: event.suggestions));
  }

  /// Stores the computed danger report in state.
  void _onRouteDangerReportUpdated(
    RouteDangerReportUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(routeDangerReport: event.report));
  }

  /// Starts active turn-by-turn navigation and speaks the opening announcement.
  void _onStartNavigation(
    StartNavigation event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(isNavigating: true));

    // Fused announcement: navigation start + first instruction + danger context
    final dangerPart = state.routeDangerReport?.isDangerous == true
        ? ' Note: ${state.routeDangerReport!.reason}'
        : ' Your route is clear.';
    final firstStep = state.instructions.isNotEmpty
        ? ' First: ${state.instructions.first['text'] ?? ''}'
        : '';
    navigationVoice.speak(
      'Navigation started.$firstStep$dangerPart',
      VoicePriority.navigation,
    );
  }

  /// Stops active navigation, clears the route, and flushes the voice queue.
  void _onStopNavigation(
    StopNavigation event,
    Emitter<NavigationState> emit,
  ) {
    navigationVoice.flush();
    emit(state.copyWith(
      isNavigating: false,
      clearRoutePoints: true,
      clearDangerReport: true,
      instructions: [],
      destinationAddress: '',
      predictiveAlert: PredictiveAlert.none,
    ));
    navigationVoice.speak('Navigation stopped.', VoicePriority.info);
  }

  /// Stores the destination address text.
  void _onDestinationAddressChanged(
    DestinationAddressChanged event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(destinationAddress: event.address));
  }

  /// Stores the latest predictive alert in state.
  void _onPredictiveAlertUpdated(
    PredictiveAlertUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(predictiveAlert: event.alert));
  }

  /// Updates the user's speed used by the predictive service.
  void _onUserSpeedUpdated(
    UserSpeedUpdated event,
    Emitter<NavigationState> emit,
  ) {
    emit(state.copyWith(userSpeedMps: event.speedMps));
  }

  @override
  /// Disposes of the location service and flushes voice when bloc is closed.
  Future<void> close() async {
    _locationService.dispose();
    await navigationVoice.flush();
    return super.close();
  }
}
