import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for playing audio alerts and managing audio player lifecycle.
/// Handles warning sounds and audio playback for danger zone alerts.
class AudioService {
  static const String _warningAlarmPath = 'sounds/warning_alarm.mp3';
  
  late final AudioPlayer _audioPlayer;
  bool _isInitialized = false;

  /// Initialize the audio service and configure the audio player.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      
      // Set up event listeners for debugging
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        debugPrint('Audio player state changed: $state');
      });
      
      _audioPlayer.onLog.listen((String log) {
        debugPrint('AudioPlayer log: $log');
      });

      _isInitialized = true;
      debugPrint('Audio service initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize audio service: $e');
      rethrow;
    }
  }

  /// Plays the warning alarm sound.
  /// Returns true if playback started successfully, false otherwise.
  Future<bool> playWarningAlarm() async {
    if (!_isInitialized) {
      debugPrint('Audio service not initialized');
      return false;
    }

    try {
      // Stop any currently playing audio
      await _audioPlayer.stop();
      
      // Play the warning alarm
      await _audioPlayer.play(AssetSource(_warningAlarmPath));
      debugPrint('Warning alarm playback started');
      return true;
    } catch (e) {
      debugPrint('Failed to play warning alarm: $e');
      return false;
    }
  }

  /// Stops any currently playing audio.
  Future<void> stopAudio() async {
    if (!_isInitialized) return;

    try {
      await _audioPlayer.stop();
      debugPrint('Audio playback stopped');
    } catch (e) {
      debugPrint('Failed to stop audio: $e');
    }
  }

  /// Pauses any currently playing audio.
  Future<void> pauseAudio() async {
    if (!_isInitialized) return;

    try {
      await _audioPlayer.pause();
      debugPrint('Audio playback paused');
    } catch (e) {
      debugPrint('Failed to pause audio: $e');
    }
  }

  /// Sets the playback volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    if (!_isInitialized) return;

    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(clampedVolume);
      debugPrint('Audio volume set to: $clampedVolume');
    } catch (e) {
      debugPrint('Failed to set audio volume: $e');
    }
  }

  /// Gets the current playback state.
  PlayerState get currentState => _audioPlayer.state;

  /// Gets whether the audio service is initialized.
  bool get isInitialized => _isInitialized;

  /// Disposes of the audio service and releases resources.
  Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      debugPrint('Audio service disposed');
    } catch (e) {
      debugPrint('Failed to dispose audio service: $e');
    }
  }
}
