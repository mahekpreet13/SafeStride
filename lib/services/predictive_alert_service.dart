import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import '../utils/geometry_utils.dart';

/// Alert levels for predictive danger zone proximity.
enum PredictiveAlertLevel {
  /// No danger zone detected along the projected path.
  none,

  /// A danger zone is within 100–200 m along the projected heading.
  approaching,

  /// A danger zone is within 50 m — act immediately.
  imminent,
}

/// Result of a predictive danger analysis.
class PredictiveAlert {
  final PredictiveAlertLevel level;

  /// Estimated distance to the nearest danger zone boundary in metres.
  final double distanceMeters;

  /// Danger score of the impending zone (0 if [level] == none).
  final int dangerScore;

  const PredictiveAlert({
    required this.level,
    required this.distanceMeters,
    required this.dangerScore,
  });

  static const PredictiveAlert none = PredictiveAlert(
    level: PredictiveAlertLevel.none,
    distanceMeters: double.infinity,
    dangerScore: 0,
  );

  String get voiceMessage {
    final dist = distanceMeters.isInfinite
        ? ''
        : '${distanceMeters.toInt()} metres';
    switch (level) {
      case PredictiveAlertLevel.none:
        return '';
      case PredictiveAlertLevel.approaching:
        return 'Caution. Danger zone ahead in approximately $dist. '
            'Accident risk: ${_scoreLabel(dangerScore)}.';
      case PredictiveAlertLevel.imminent:
        return 'Warning. Danger zone imminent — ${distanceMeters < 5 ? "you are entering" : "$dist ahead"}. '
            'Slow down and stay alert.';
    }
  }

  String get uiLabel {
    switch (level) {
      case PredictiveAlertLevel.none:
        return '';
      case PredictiveAlertLevel.approaching:
        return '⚠️  Danger zone ~${distanceMeters.toInt()} m ahead';
      case PredictiveAlertLevel.imminent:
        return '🚨  Danger zone imminent!';
    }
  }

  static String _scoreLabel(int score) {
    if (score >= 10) return 'very high';
    if (score >= 7) return 'high';
    if (score >= 5) return 'moderate';
    return 'low';
  }
}

/// Analyses the user's projected path ahead and returns a [PredictiveAlert].
///
/// Works entirely in-memory using the already-loaded danger zone polygons
/// from [RouteDangerAnalysisService] — no I/O at runtime.
class PredictiveAlertService {
  /// Thresholds (metres) for each alert level.
  static const double _imminentThreshold = 50.0;
  static const double _approachingThreshold = 200.0;

  /// Number of "probe" points projected ahead along the heading.
  static const int _probeCount = 8;

  final Distance _distCalc = const Distance();

  /// Projects [probeCount] points ahead from [position] along [headingDeg]
  /// at intervals up to [maxDistance] metres, checks each against
  /// [dangerCells], and returns the closest [PredictiveAlert].
  ///
  /// [speedMps] — current speed in m/s; if < 0.5, thresholds are halved
  ///              (slow pedestrian needs less look-ahead).
  PredictiveAlert check({
    required LatLng position,
    required double headingDeg,
    required double speedMps,
    required List<List<LatLng>> dangerPolygons,
    required List<int> dangerScores,
  }) {
    if (dangerPolygons.isEmpty) return PredictiveAlert.none;

    // Slow pedestrian: reduce look-ahead
    final factor = speedMps < 0.5 ? 0.5 : 1.0;
    final maxDist = _approachingThreshold * factor;

    double nearestDist = double.infinity;
    int nearestScore = 0;

    final headingRad = headingDeg * math.pi / 180.0;

    for (int i = 1; i <= _probeCount; i++) {
      final probeDist = (maxDist / _probeCount) * i;
      final probe = _projectPoint(position, headingRad, probeDist);

      for (int ci = 0; ci < dangerPolygons.length; ci++) {
        if (GeometryUtils.isPointInPolygon(probe, dangerPolygons[ci])) {
          if (probeDist < nearestDist) {
            nearestDist = probeDist;
            nearestScore = ci < dangerScores.length ? dangerScores[ci] : 5;
          }
        }
      }
    }

    if (nearestDist.isInfinite) return PredictiveAlert.none;

    final adjustedImm = _imminentThreshold * factor;
    final level = nearestDist <= adjustedImm
        ? PredictiveAlertLevel.imminent
        : PredictiveAlertLevel.approaching;

    return PredictiveAlert(
      level: level,
      distanceMeters: nearestDist,
      dangerScore: nearestScore,
    );
  }

  /// Projects a point [distMeters] ahead from [origin] along [headingRad].
  LatLng _projectPoint(LatLng origin, double headingRad, double distMeters) {
    const earthRadius = 6371000.0;
    final lat = origin.latitude * math.pi / 180;
    final lng = origin.longitude * math.pi / 180;
    final d = distMeters / earthRadius;

    final newLat = math.asin(
      math.sin(lat) * math.cos(d) +
          math.cos(lat) * math.sin(d) * math.cos(headingRad),
    );
    final newLng = lng +
        math.atan2(
          math.sin(headingRad) * math.sin(d) * math.cos(lat),
          math.cos(d) - math.sin(lat) * math.sin(newLat),
        );

    return LatLng(newLat * 180 / math.pi, newLng * 180 / math.pi);
  }
}
