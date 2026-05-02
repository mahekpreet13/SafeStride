import 'package:latlong2/latlong.dart';

/// Decodes a Google polyline-encoded string into a list of LatLng coordinates.
/// 
/// Google's polyline encoding algorithm compresses GPS coordinates into a 
/// string format to reduce data size for route transmission. This function
/// reverses that process to extract usable coordinate points.
/// 
/// See: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
List<LatLng> decodePolyline(String encoded) {
  List<LatLng> poly = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;
  int shift = 0, result = 0;
  int b;
  
  // Factor used in Google's encoding algorithm
  const int factor = 100000;
  while (index < len) {
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;
    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;
    poly.add(LatLng(lat / factor, lng / factor));
  }
  return poly;
}
