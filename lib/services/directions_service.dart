import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  // ✅ Client এর API Key

  /// Get directions between two points
  Future<Map<String, dynamic>?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      // ✅ OSRM Public API (No key needed for low volume)
      final String url =
          'https://router.project-osrm.org/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=polyline';

      debugPrint('🗺️ Fetching directions from OSRM API...');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = _decodePolyline(route['geometry']);

          // OSRM returns distance in meters and duration in seconds
          final double distanceInKm = (route['distance'] ?? 0) / 1000.0;
          final double durationInMin = (route['duration'] ?? 0) / 60.0;

          return {
            'polylinePoints': polylinePoints,
            'distance': '${distanceInKm.toStringAsFixed(1)} km',
            'duration': '${durationInMin.toStringAsFixed(0)} min',
            'steps': route['legs']?[0]['steps'] ?? [],
          };
        } else {
          debugPrint('❌ OSRM API Status: ${data['code']}');
          return null;
        }
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error fetching directions: $e');
      return null;
    }
  }

  /// Decode Google polyline to LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

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

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}
