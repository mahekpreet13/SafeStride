import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../config/app_constants.dart';

class NominatimApiService {
  Future<List<String>> fetchSuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final response = await http.get(
      Uri.parse(
        '${AppConstants.nominatimBaseUrl}/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map((item) => item['display_name'] as String).toList();
    } else {
      throw Exception('Failed to load suggestions from Nominatim');
    }
  }

  Future<LatLng?> geocodeAddress(String address) async {
    if (address.isEmpty) {
      return null;
    }
    final response = await http.get(
      Uri.parse(
        '${AppConstants.nominatimBaseUrl}/search?q=${Uri.encodeComponent(address)}&format=json&limit=1',
      ),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      if (data.isEmpty) {
        return null;
      }
      final lat = double.parse(data[0]['lat']);
      final lon = double.parse(data[0]['lon']);
      return LatLng(lat, lon);
    } else {
      throw Exception('Failed to geocode address with Nominatim');
    }
  }
}
