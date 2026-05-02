import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for checking danger zone status via external API.
/// Handles API communication for real-time danger zone detection.
class DangerZoneApiService {
  static const String _baseUrl = 'http://localhost:5001';
  static const String _dangerCheckEndpoint = '/is_dangerous_road_nearby';
  static const Duration _defaultTimeout = Duration(seconds: 10);

  final http.Client _httpClient;

  DangerZoneApiService({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// Checks if the given coordinates are near a dangerous road.
  /// Returns true if dangerous roads are nearby, false otherwise.
  /// Throws [DangerZoneApiException] on API errors.
  Future<bool> isDangerousRoadNearby(LatLng coordinates) async {
     debugPrint("API URL: $_baseUrl");
    final uri = Uri.parse(
      '$_baseUrl$_dangerCheckEndpoint?coord=${coordinates.latitude},${coordinates.longitude}',
    );

    debugPrint('Checking danger status at: ${coordinates.latitude}, ${coordinates.longitude}');

    try {
      final response = await _httpClient
          .get(uri)
          .timeout(_defaultTimeout);
      debugPrint("RAW RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('API response: $data');

        // Check if the API call was successful
        if (data['success'] == true && data.containsKey('dangerous_roads_nearby')) {
          final isDangerous = data['dangerous_roads_nearby'] == true;
          debugPrint('Danger status: $isDangerous');
          return isDangerous;
        } else {
          final errorMessage = data['message'] ?? 'Unknown API error';
          debugPrint('API call failed: $errorMessage');
          throw DangerZoneApiException('API operation failed: $errorMessage');
        }
      } else {
        final errorMessage = 'HTTP ${response.statusCode}: ${response.body}';
        debugPrint('API request failed: $errorMessage');
        throw DangerZoneApiException('API request failed: $errorMessage');
      }
    } on FormatException catch (e) {
      debugPrint('Failed to parse API response: $e');
      throw DangerZoneApiException('Invalid API response format: $e');
    } catch (e) {
      debugPrint('Danger zone API error: $e');
      if (e is DangerZoneApiException) rethrow;
      throw DangerZoneApiException('Network or API error: $e');
    }
  }

  /// Checks danger status for multiple coordinates at once.
  /// Returns a map of coordinates to their danger status.
  Future<Map<LatLng, bool>> checkMultipleLocations(List<LatLng> coordinates) async {
    final results = <LatLng, bool>{};
    
    // Process coordinates concurrently for better performance
    final futures = coordinates.map((coord) async {
      try {
        final isDangerous = await isDangerousRoadNearby(coord);
        return MapEntry(coord, isDangerous);
      } catch (e) {
        debugPrint('Failed to check danger status for $coord: $e');
        // Return false as default for failed checks
        return MapEntry(coord, false);
      }
    });

    final responses = await Future.wait(futures);
    for (final entry in responses) {
      results[entry.key] = entry.value;
    }

    return results;
  }

  /// Disposes of the HTTP client resources.
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown when danger zone API operations fail.
class DangerZoneApiException implements Exception {
  final String message;
  
  const DangerZoneApiException(this.message);
  
  @override
  String toString() => 'DangerZoneApiException: $message';
}
