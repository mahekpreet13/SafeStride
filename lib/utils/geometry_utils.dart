import 'package:latlong2/latlong.dart';
import 'dart:math' as math;

/// Utility class for geometric calculations related to danger zones.
/// Provides methods for point-in-polygon detection and distance calculations.
class GeometryUtils {
  /// Checks if a given point is inside any of the provided polygons.
  /// Uses the ray casting algorithm for point-in-polygon detection.
  static bool isPointInAnyPolygon(LatLng point, List<List<LatLng>> polygons) {
    for (final polygon in polygons) {
      if (isPointInPolygon(point, polygon)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if a point is inside a polygon using the ray casting algorithm.
  /// Returns true if the point is inside the polygon, false otherwise.
  static bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.isEmpty) return false;

    int intersectionCount = 0;
    final int polygonLength = polygon.length;

    // Check intersections with polygon edges
    for (int i = 0; i < polygonLength; i++) {
      final LatLng vertex1 = polygon[i];
      final LatLng vertex2 = polygon[(i + 1) % polygonLength];

      if (_doesRayIntersectEdge(point, vertex1, vertex2)) {
        intersectionCount++;
      }
    }

    // If polygon isn't explicitly closed, check the closing edge
    if (polygon.first != polygon.last && polygonLength > 2) {
      if (_doesRayIntersectEdge(point, polygon.last, polygon.first)) {
        intersectionCount++;
      }
    }

    // Point is inside if intersection count is odd
    return intersectionCount % 2 == 1;
  }

  /// Determines if a horizontal ray from the point intersects with a polygon edge.
  /// Uses the ray casting algorithm implementation.
  static bool _doesRayIntersectEdge(LatLng point, LatLng edgeStart, LatLng edgeEnd) {
    final double pointY = point.latitude;
    final double pointX = point.longitude;
    final double startY = edgeStart.latitude;
    final double startX = edgeStart.longitude;
    final double endY = edgeEnd.latitude;
    final double endX = edgeEnd.longitude;

    // Check if edge is horizontal (no intersection possible)
    if (startY == endY) return false;

    // Check if point is outside the edge's y-range
    if (pointY < math.min(startY, endY) || pointY >= math.max(startY, endY)) {
      return false;
    }

    // Calculate intersection point's x-coordinate
    final double intersectionX = startX + 
        (pointY - startY) / (endY - startY) * (endX - startX);

    // Ray extends to the right, so intersection is valid if x > point's x
    return intersectionX > pointX;
  }

  /// Calculates the distance between two points in meters using the Haversine formula.
  static double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = _degreesToRadians(point1.latitude);
    final double lat2Rad = _degreesToRadians(point2.latitude);
    final double deltaLatRad = _degreesToRadians(point2.latitude - point1.latitude);
    final double deltaLngRad = _degreesToRadians(point2.longitude - point1.longitude);

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Finds the closest point on a polygon to the given point.
  /// Returns both the closest point and the distance to it.
  static ({LatLng point, double distance}) findClosestPointOnPolygon(
    LatLng point, 
    List<LatLng> polygon,
  ) {
    if (polygon.isEmpty) {
      throw ArgumentError('Polygon cannot be empty');
    }

    LatLng closestPoint = polygon.first;
    double minDistance = calculateDistance(point, polygon.first);

    // Check distance to each vertex
    for (final vertex in polygon) {
      final double distance = calculateDistance(point, vertex);
      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = vertex;
      }
    }

    // Check distance to each edge
    for (int i = 0; i < polygon.length; i++) {
      final LatLng edgeStart = polygon[i];
      final LatLng edgeEnd = polygon[(i + 1) % polygon.length];
      
      final result = _findClosestPointOnEdge(point, edgeStart, edgeEnd);
      if (result.distance < minDistance) {
        minDistance = result.distance;
        closestPoint = result.point;
      }
    }

    return (point: closestPoint, distance: minDistance);
  }

  /// Finds the closest point on a line segment to the given point.
  static ({LatLng point, double distance}) _findClosestPointOnEdge(
    LatLng point,
    LatLng edgeStart,
    LatLng edgeEnd,
  ) {
    final double edgeLength = calculateDistance(edgeStart, edgeEnd);
    if (edgeLength == 0) {
      return (point: edgeStart, distance: calculateDistance(point, edgeStart));
    }

    // Calculate the projection parameter
    final double t = math.max(0, math.min(1, 
        _dotProduct(
          _subtractPoints(point, edgeStart),
          _subtractPoints(edgeEnd, edgeStart)
        ) / (edgeLength * edgeLength)));

    // Calculate the closest point on the edge
    final LatLng closestPoint = LatLng(
      edgeStart.latitude + t * (edgeEnd.latitude - edgeStart.latitude),
      edgeStart.longitude + t * (edgeEnd.longitude - edgeStart.longitude),
    );

    return (point: closestPoint, distance: calculateDistance(point, closestPoint));
  }

  /// Calculates the dot product of two 2D vectors represented as LatLng points.
  static double _dotProduct(LatLng vector1, LatLng vector2) {
    return vector1.latitude * vector2.latitude + vector1.longitude * vector2.longitude;
  }

  /// Subtracts two LatLng points to create a vector.
  static LatLng _subtractPoints(LatLng point1, LatLng point2) {
    return LatLng(
      point1.latitude - point2.latitude,
      point1.longitude - point2.longitude,
    );
  }

  /// Converts degrees to radians.
  static double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  /// Gets the bounding box of a polygon.
  /// Returns the minimum and maximum latitude and longitude.
  static ({double minLat, double maxLat, double minLng, double maxLng}) getPolygonBounds(
    List<LatLng> polygon,
  ) {
    if (polygon.isEmpty) {
      throw ArgumentError('Polygon cannot be empty');
    }

    double minLat = polygon.first.latitude;
    double maxLat = polygon.first.latitude;
    double minLng = polygon.first.longitude;
    double maxLng = polygon.first.longitude;

    for (final point in polygon) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return (minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng);
  }
}
