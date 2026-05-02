import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:safe_stride/config/app_constants.dart';

class GraphHopperApiManager {
  final String _apiKey;

  GraphHopperApiManager(this._apiKey);

  Future<Map<String, dynamic>> getRoute(LatLng start, LatLng end) async {
    final url =
        '${AppConstants.graphHopperBaseUrl}/route?point=${start.latitude},${start.longitude}&point=${end.latitude},${end.longitude}&profile=foot&locale=en&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load route: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load route: $e');
    }
  }
}
