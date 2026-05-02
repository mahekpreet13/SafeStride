import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Priority levels for the voice queue — higher number = higher priority.
enum VoicePriority {
  info(0),
  navigation(1),
  safety(2),
  critical(3);

  final int level;
  const VoicePriority(this.level);
}

/// A queued speech item.
class _VoiceItem {
  final String text;
  final VoicePriority priority;
  _VoiceItem(this.text, this.priority);
}

/// Singleton-style service that owns a single [FlutterTts] instance and manages
/// a priority-aware speech queue.
///
/// Higher-priority items interrupt lower-priority speech immediately.
/// Use [speak] to enqueue / pre-empt, and [flush] to clear everything.
class NavigationVoiceService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _speaking = false;
  final List<_VoiceItem> _queue = [];
  VoicePriority _currentPriority = VoicePriority.info;

  // Cool-down: don't repeat the same message within this window.
  final Map<VoicePriority, DateTime> _lastSpoken = {};
  static const Map<VoicePriority, Duration> _cooldowns = {
    VoicePriority.info: Duration(seconds: 20),
    VoicePriority.navigation: Duration(seconds: 8),
    VoicePriority.safety: Duration(seconds: 10),
    VoicePriority.critical: Duration(seconds: 5),
  };

  String? _lastCriticalText;

  Future<void> initialize() async {
    if (_ready) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.46);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _tts.setCompletionHandler(_onComplete);
      _ready = true;
      debugPrint('[Voice] NavigationVoiceService ready');
    } catch (e) {
      debugPrint('[Voice] Init error: $e');
    }
  }

  void _onComplete() {
    _speaking = false;
    _processQueue();
  }

  /// Enqueue [text] at [priority].
  ///
  /// If [priority] > current speaking priority, interrupts immediately.
  void speak(String text, VoicePriority priority) {
    if (!_ready || text.trim().isEmpty) return;

    // Suppress duplicates for critical (prevents spam on every position tick)
    if (priority == VoicePriority.critical && text == _lastCriticalText) {
      final last = _lastSpoken[priority];
      if (last != null &&
          DateTime.now().difference(last) < _cooldowns[priority]!) return;
    }

    // Enforce cool-down per priority
    final last = _lastSpoken[priority];
    if (priority != VoicePriority.critical && last != null) {
      if (DateTime.now().difference(last) < _cooldowns[priority]!) return;
    }

    final item = _VoiceItem(text, priority);

    if (_speaking && priority.level > _currentPriority.level) {
      // Pre-empt: stop current, put new item at front
      _tts.stop();
      _queue.insert(0, item);
      _speaking = false;
    } else {
      // Insert in priority order
      final idx = _queue.indexWhere((i) => i.priority.level < priority.level);
      if (idx == -1) {
        _queue.add(item);
      } else {
        _queue.insert(idx, item);
      }
    }

    _processQueue();
  }

  void _processQueue() {
    if (_speaking || _queue.isEmpty) return;
    final item = _queue.removeAt(0);
    _speaking = true;
    _currentPriority = item.priority;
    _lastSpoken[item.priority] = DateTime.now();
    if (item.priority == VoicePriority.critical) {
      _lastCriticalText = item.text;
    }
    _tts.speak(item.text).catchError((e) {
      debugPrint('[Voice] TTS speak error: $e');
      _speaking = false;
    });
  }

  /// Clear all pending speech and stop current playback.
  Future<void> flush() async {
    _queue.clear();
    _speaking = false;
    await _tts.stop();
  }

  /// Dispose TTS resources.
  Future<void> dispose() async {
    await flush();
  }
}

/// Global shared instance — initialise once in main or at bloc creation.
final navigationVoice = NavigationVoiceService();
