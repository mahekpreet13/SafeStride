import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for managing device vibration patterns for alerts.
/// Handles different vibration types for various danger zone scenarios.
class VibrationService {
  /// Pattern for danger zone entry alert: immediate, strong vibration with pattern.
  static const List<int> _dangerZonePattern = [0, 500, 200, 500];
  
  /// Intensities for Android vibration (iOS ignores this).
  static const List<int> _dangerZoneIntensities = [0, 128, 0, 128];
  
  /// Short vibration duration for exiting danger zones.
  static const int _exitVibrationDuration = 500;

  bool? _hasVibrator;

  /// Initialize the vibration service and check device capabilities.
  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator();
      debugPrint('Vibration service initialized. Has vibrator: $_hasVibrator');
    } catch (e) {
      debugPrint('Failed to initialize vibration service: $e');
      _hasVibrator = false;
    }
  }

  /// Triggers a danger zone entry vibration pattern.
  /// Uses a complex pattern on Android and default vibration on iOS.
  Future<bool> vibrateDangerZoneEntry() async {
    if (_hasVibrator != true) {
      debugPrint('Device does not have vibrator capabilities');
      return false;
    }

    try {
      await Vibration.vibrate(
        pattern: _dangerZonePattern,
        intensities: _dangerZoneIntensities,
      );
      debugPrint('Danger zone entry vibration triggered');
      return true;
    } catch (e) {
      debugPrint('Failed to trigger danger zone vibration: $e');
      return false;
    }
  }

  /// Triggers a short vibration for exiting a danger zone.
  Future<bool> vibrateDangerZoneExit() async {
    if (_hasVibrator != true) {
      debugPrint('Device does not have vibrator capabilities');
      return false;
    }

    try {
      await Vibration.vibrate(duration: _exitVibrationDuration);
      debugPrint('Danger zone exit vibration triggered');
      return true;
    } catch (e) {
      debugPrint('Failed to trigger exit vibration: $e');
      return false;
    }
  }

  /// Triggers a custom vibration with specified duration.
  Future<bool> vibrateCustom({
    int? duration,
    List<int>? pattern,
    List<int>? intensities,
  }) async {
    if (_hasVibrator != true) {
      debugPrint('Device does not have vibrator capabilities');
      return false;
    }

    try {
      if (pattern != null) {
        await Vibration.vibrate(
          pattern: pattern,
          intensities: intensities ?? List.filled(pattern.length, 128),
        );
      } else {
        await Vibration.vibrate(duration: duration ?? 1000);
      }
      debugPrint('Custom vibration triggered');
      return true;
    } catch (e) {
      debugPrint('Failed to trigger custom vibration: $e');
      return false;
    }
  }

  /// Cancels any ongoing vibration.
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
      debugPrint('Vibration canceled');
    } catch (e) {
      debugPrint('Failed to cancel vibration: $e');
    }
  }

  /// Gets whether the device has vibration capabilities.
  bool get hasVibrator => _hasVibrator == true;

  /// Gets whether the vibration service has been initialized.
  bool get isInitialized => _hasVibrator != null;
}
