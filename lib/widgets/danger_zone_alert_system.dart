import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/danger_zone_bloc.dart';
import '../bloc/danger_zone_event_state.dart';
import 'package:audioplayers/audioplayers.dart';

class DangerZoneAlertSystem extends StatefulWidget {
  final List<List<LatLng>> dangerousPolygons;
  final Widget? child;
  final bool showDebugInfo;
  /// Optional danger reason string from the route analysis, spoken aloud
  /// when the user enters a danger zone.
  final String? dangerReason;

  const DangerZoneAlertSystem({
    super.key,
    required this.dangerousPolygons,
    this.child,
    this.showDebugInfo = false,
    this.dangerReason,
  });

  @override
  State<DangerZoneAlertSystem> createState() => _DangerZoneAlertSystemState();
}

class _DangerZoneAlertSystemState extends State<DangerZoneAlertSystem> {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  final Distance _distance = Distance();

  DateTime? _lastSpokenTime;
  bool _wasInDanger = false;
  bool _audioInitialized = false;


  double _getNearestDangerDistance(LatLng current) {
    double minDistance = double.infinity;

    for (var polygon in widget.dangerousPolygons) {
      for (var point in polygon) {
        final dist = _distance(current, point);
        if (dist < minDistance) {
          minDistance = dist;
        }
      }
    }

    return minDistance;
  }

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _audioInitialized = true;
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DangerZoneBloc()..add(InitializeDangerZoneSystem(widget.dangerousPolygons)),
      child: BlocListener<DangerZoneBloc, DangerZoneState>(
        listener: (context, state) {
          _handleStateChanges(context, state);
        },
        child: widget.showDebugInfo
            ? _buildDebugView()
            : (widget.child ?? const SizedBox.shrink()),
      ),
    );
  }

  void _handleStateChanges(BuildContext context, DangerZoneState state) {
    switch (state) {
      case DangerZoneError error:
        _showErrorFeedback(context, error.message);
        break;

      case DangerZoneMonitoring monitoring:
        _handleMonitoringState(context, monitoring);
        break;

      case DangerZoneLoading():
        break;

      case DangerZoneInitial():
        break;
    }
  }

  void _showErrorFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Danger Zone Error: $message'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _handleMonitoringState(
      BuildContext context, DangerZoneMonitoring state) async {

    // Continuous navigation voice
    await _speakNavigationUpdate(state.isInDangerZone,
  state.currentLocation,
  );

    if (state.isInDangerZone && !_wasInDanger) {
      _wasInDanger = true;

      debugPrint("🚨 AUTO ALERT TRIGGERED");

      await _playDangerAlert();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Gefahrenzone erkannt!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } else if (!state.isInDangerZone && _wasInDanger) {
      _wasInDanger = false;

      debugPrint("✅ SAFE ZONE ENTERED");

      await _playSafeAlert();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Gefahrenzone verlassen'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

Future<void> _playDangerAlert() async {
  try {
    debugPrint("🔊 Playing danger sound");
    await _player.play(AssetSource('sounds/warning_alarm.mp3'));
    await Future.delayed(const Duration(milliseconds: 500));

    if (_audioInitialized) {
      debugPrint("🗣️ Speaking danger message");
      await _tts.stop();
      final reason = widget.dangerReason;
      if (reason != null && reason.isNotEmpty) {
        await _tts.speak(
          'Warning. You are entering a dangerous zone. $reason',
        );
      } else {
        await _tts.speak('Warning. You are entering a dangerous zone.');
      }
    }
  } catch (e) {
    debugPrint("Danger alert error: $e");
  }
}

Future<void> _playSafeAlert() async {
  try {
    debugPrint("🗣️ Speaking safe message");

    if (_audioInitialized) {
      await _tts.stop(); // ✅ prevent overlap
      await _tts.speak("You are now in a safe area.");
    }
  } catch (e) {
    debugPrint("Safe alert error: $e");
  }
}

Future<void> _speakNavigationUpdate(
  bool isDanger,
  LatLng? currentLocation,
) async {
  if (!_audioInitialized || currentLocation == null) return;

  final now = DateTime.now();

  // ⛔ prevent spam talking every second
  if (_lastSpokenTime != null &&
      now.difference(_lastSpokenTime!).inSeconds < 8) {
    return;
  }

  _lastSpokenTime = now;

  try {
    await _tts.stop(); // ✅ stop previous speech FIRST

    if (isDanger) {
      await _tts.speak("Caution. You are inside a dangerous area.");
    } else {
      final distance = _getNearestDangerDistance(currentLocation);

      // ✅ fix weird “2 meters ahead” issue
      final safeDistance = distance < 5 ? 0 : distance.toInt();

      if (distance < 50) {
        await _tts.speak(
          "Danger very close. $safeDistance meters ahead.",
        );
      } else if (distance < 150) {
        await _tts.speak(
          "Caution. Dangerous area ahead in $safeDistance meters.",
        );
      } else {
        await _tts.speak("You are in a safe area.");
      }
    }
  } catch (e) {
    debugPrint("Navigation speech error: $e");
  }
}

  Widget _buildDebugView() {
    return BlocBuilder<DangerZoneBloc, DangerZoneState>(
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone Debug',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildStatusIndicator(state),
                if (widget.child != null) ...[
                  const SizedBox(height: 8),
                  widget.child!,
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(DangerZoneState state) {
    switch (state) {
      case DangerZoneInitial():
        return const _StatusChip('Initialized', Colors.grey);

      case DangerZoneLoading():
        return const _StatusChip('Loading...', Colors.blue);

      case DangerZoneMonitoring monitoring:
        return monitoring.isInDangerZone
            ? const _StatusChip('IN DANGER ZONE', Colors.red)
            : const _StatusChip('Safe', Colors.green);

      case DangerZoneError error:
        return _StatusChip('Error: ${error.message}', Colors.red);
    }
    return const _StatusChip('Unknown State', Colors.black);
  }
}

// ✅ OUTSIDE the main class (this was your big mistake)
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}