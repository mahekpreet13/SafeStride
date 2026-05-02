import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';
import '../utils/geometry_utils.dart';

/// Describes the danger level of a planned route.
class RouteDangerReport {
  /// Whether any part of the route passes through a danger zone.
  final bool isDangerous;

  /// The highest danger score encountered along the route (0 = safe).
  final int maxDangerScore;

  /// Human-readable explanation, e.g. "Route passes through 3 high-risk zones
  /// (max danger score: 12/19)."
  final String reason;

  /// Subset of route points that lie inside danger zones.
  final List<LatLng> dangerSegments;

  const RouteDangerReport({
    required this.isDangerous,
    required this.maxDangerScore,
    required this.reason,
    required this.dangerSegments,
  });

  /// A safe, empty report.
  static const RouteDangerReport safe = RouteDangerReport(
    isDangerous: false,
    maxDangerScore: 0,
    reason: 'Your route does not pass through any recorded danger zones.',
    dangerSegments: [],
  );
}

/// Holds one danger zone cell loaded from JSON.
class _DangerCell {
  final List<LatLng> polygon;
  final int score;
  const _DangerCell(this.polygon, this.score);
}

/// Analyses a list of route [LatLng] points against the local danger-zone data
/// and returns a [RouteDangerReport].
class RouteDangerAnalysisService {
  List<_DangerCell>? _cells;

  /// Loads danger zone data from the bundled asset (cached after first call).
  Future<void> _ensureLoaded() async {
    if (_cells != null) return;
    final jsonString =
        await rootBundle.loadString('Unfallatlas/regensburg_tiles.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    _cells = (jsonData['features'] as List)
        .where((f) => (f['properties']['danger_score'] as int) >= 3)
        .map((f) {
      final coords = f['geometry']['coordinates'][0] as List;
      final polygon =
          coords.map<LatLng>((c) => LatLng(c[1] as double, c[0] as double)).toList();
      final score = f['properties']['danger_score'] as int;
      return _DangerCell(polygon, score);
    }).toList();
  }

  /// Analyses [routePoints] and returns a [RouteDangerReport].
  ///
  /// [sampleEveryN] controls how many route points to skip between checks
  /// (keeps performance acceptable for long routes).
  Future<RouteDangerReport> analyse(
    List<LatLng> routePoints, {
    int sampleEveryN = 3,
  }) async {
    if (routePoints.isEmpty) return RouteDangerReport.safe;

    await _ensureLoaded();

    final List<LatLng> dangerSegments = [];
    int maxScore = 0;
    int dangerZoneCount = 0;
    final Set<int> hitCellIndices = {};

    for (int i = 0; i < routePoints.length; i += sampleEveryN) {
      final point = routePoints[i];
      for (int ci = 0; ci < _cells!.length; ci++) {
        final cell = _cells![ci];
        if (GeometryUtils.isPointInPolygon(point, cell.polygon)) {
          dangerSegments.add(point);
          if (cell.score > maxScore) maxScore = cell.score;
          if (!hitCellIndices.contains(ci)) {
            hitCellIndices.add(ci);
            dangerZoneCount++;
          }
        }
      }
    }

    if (dangerSegments.isEmpty) return RouteDangerReport.safe;

    final String severity = maxScore >= 10
        ? 'very high'
        : maxScore >= 7
            ? 'high'
            : maxScore >= 5
                ? 'moderate'
                : 'low';

    final reason =
        'Your route passes through $dangerZoneCount danger zone${dangerZoneCount > 1 ? "s" : ""} '
        'with a $severity accident risk (score $maxScore/19). '
        'Stay alert and follow the highlighted sections carefully.';

    return RouteDangerReport(
      isDangerous: true,
      maxDangerScore: maxScore,
      reason: reason,
      dangerSegments: dangerSegments,
    );
  }
}
