import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';

class DangerZoneService {
  Future<List<fm.Polygon>> loadDangerZones() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'Unfallatlas/regensburg_tiles.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      return jsonData['features'].map<fm.Polygon>((feature) {
        final coordinates = feature['geometry']['coordinates'][0];
        final points = coordinates
            .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
            .toList();

        final dangerScore = feature['properties']['danger_score'] ?? 0;
        if (dangerScore < 3) {
          return fm.Polygon(
            points: [],
            color: Colors.transparent,
            borderColor: Colors.transparent,
          );
        }

        return fm.Polygon(
          points: points,
          color: Colors.red.withAlpha((0.3 * 255).toInt()),
          borderColor: Colors.red,
          borderStrokeWidth: 2.0,
          isFilled: true,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load danger zones: $e');
    }
  }
}
