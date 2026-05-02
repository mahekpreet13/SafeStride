import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:latlong2/latlong.dart';
import 'package:rxdart/rxdart.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  Future<void> initializeLocationAndCompass({
    required Function(LatLng) onPositionUpdate,
    required Function(String) onError,
    required Function(double?) onCompassUpdate,
  }) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onError('Location services disabled');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onError('Location permissions denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      onError('Location permissions permanently denied');
      return;
    }

    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      onPositionUpdate(
        LatLng(initialPosition.latitude, initialPosition.longitude),
      );
    } catch (e) {
      debugPrint("Error getting initial position: $e");
      onError('Error getting initial location: $e');
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                distanceFilter: 5,
              ),
            )
            .transform(
              ThrottleStreamTransformer(
                (_) => Stream<void>.periodic(const Duration(seconds: 1)),
              ),
            )
            .listen(
              (Position position) {
                onPositionUpdate(LatLng(position.latitude, position.longitude));
              },
              onError: (error) {
                debugPrint("Error in location stream: $error");
                onError('Error in location stream: $error');
              },
            );

    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      onCompassUpdate(event.heading);
    });
  }

  void dispose() {
    _positionStreamSubscription?.cancel();
    _compassSubscription?.cancel();
  }
}
