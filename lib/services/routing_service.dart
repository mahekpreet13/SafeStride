import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  Future<Map<String, dynamic>> fetchRoute({
    required LatLng start,
    required LatLng end,
  }) async {
    final response = await http.get(
      Uri.parse(
        'https://graphhopper.com/api/1/route?point=${start.latitude},${start.longitude}&point=${end.latitude},${end.longitude}&profile=foot&locale=en&instructions=true&key=39b7b61c-1491-40d7-8937-3cec30abacd0',
      ),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch route: ${response.statusCode}');
    }
  }

  Future<List<String>> fetchSuggestions(String input) async {
    if (input.isEmpty) {
      return [];
    }
    final resp = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(input)}&format=json&addressdetails=1&limit=5',
      ),
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      return [for (final item in data) item['display_name'] as String];
    } else {
      throw Exception('Failed to fetch suggestions');
    }
  }

  Future<LatLng?> geocodeAddress(String address) async {
    if (address.isEmpty) {
      return null;
    }
    final geoResp = await http.get(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1',
      ),
    );
    if (geoResp.statusCode == 200) {
      final geoData = json.decode(geoResp.body);
      if (geoData.isEmpty) {
        return null;
      }
      final lat = double.parse(geoData[0]['lat']);
      final lon = double.parse(geoData[0]['lon']);
      return LatLng(lat, lon);
    } else {
      throw Exception('Geocoding failed');
    }
  }
}
