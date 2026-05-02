import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/polyline_decoder.dart';
import '../config/app_constants.dart';

class GraphHopperApiService {
  Future<Map<String, dynamic>> fetchRoute({
    required LatLng start,
    required LatLng end,
    String profile = 'foot',
    String locale = 'en',
    bool instructions = true,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${AppConstants.graphHopperBaseUrl}/route?point=${start.latitude},${start.longitude}&point=${end.latitude},${end.longitude}&profile=$profile&locale=$locale&instructions=$instructions',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['paths'] != null && data['paths'].isNotEmpty) {
        final path = data['paths'][0];
        final points = path['points'] as String;
        final decodedPoints = decodePolyline(points);
        final instructionsList = path['instructions'] as List<dynamic>? ?? [];
        return {'points': decodedPoints, 'instructions': instructionsList};
      } else {
        throw Exception('No paths found in GraphHopper response');
      }
    } else {
      throw Exception(
        'Failed to fetch route from GraphHopper: ${response.statusCode}',
      );
    }
  }
}
