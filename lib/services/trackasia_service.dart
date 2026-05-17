import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/trackasia_place.dart';

class TrackAsiaService {
  // To avoid --dart-define issues during testing, we add a fallback key
  static const String _fallbackKey = 'dff36ce825dbdb5a17750650297977c46b';
  
  static const String _apiKey = String.fromEnvironment('TRACKASIA_KEY', defaultValue: _fallbackKey);
  static const String _baseUrl = 'https://maps.track-asia.com/api/v1';

  /// Check if the API key is validly provided
  bool get hasValidKey => _apiKey.isNotEmpty && _apiKey != 'null' && _apiKey != '';

  /// Autocomplete addresses based on user input
  Future<List<TrackAsiaPlace>> autocomplete(String input, {double? lat, double? lon}) async {
    if (input.isEmpty || _apiKey.isEmpty) return [];

    // Use broader parameters to ensure we don't filter out house numbers inadvertently
    String urlStr = '$_baseUrl/autocomplete?text=$input&key=$_apiKey&countrycodes=vn&limit=10';
    
    // Add focus point to prioritize local results (crucial for house numbers)
    if (lat != null && lon != null) {
      urlStr += '&focus.point.lat=$lat&focus.point.lon=$lon';
    }

    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        return features.map((f) {
          final properties = f['properties'];
          final coordinates = f['geometry']['coordinates'];
          return TrackAsiaPlace(
            label: properties['label'] ?? '',
            latitude: (coordinates[1] as num).toDouble(),
            longitude: (coordinates[0] as num).toDouble(),
            name: properties['name'],
            houseNumber: properties['housenumber'] ?? properties['house_number'],
            street: properties['street'] ?? properties['road'],
            district: properties['district'] ?? properties['county'] ?? properties['locality'],
            city: properties['city'] ?? properties['region'] ?? properties['state'],
          );
        }).toList();
      } else {
        debugPrint('TrackAsia Autocomplete Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('TrackAsia Autocomplete Exception: $e');
      return [];
    }
  }

  /// Search for a specific address to get precise coordinates
  Future<TrackAsiaPlace?> searchAddress(String text, {double? lat, double? lon}) async {
    if (text.isEmpty || !hasValidKey) return null;

    String urlStr = '$_baseUrl/search?text=$text&key=$_apiKey&countrycodes=vn&limit=1';
    
    if (lat != null && lon != null) {
      urlStr += '&focus.point.lat=$lat&focus.point.lon=$lon';
    }

    final url = Uri.parse(urlStr);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          return TrackAsiaPlace.fromJson(features[0]);
        }
      }
    } catch (e) {
      debugPrint('TrackAsia Search Exception: $e');
    }
    return null;
  }

  /// Reverse geocode coordinates to a human-readable address
  Future<TrackAsiaPlace?> reverseGeocode({required double lat, required double lng}) async {
    if (_apiKey.isEmpty) return null;

    final url = Uri.parse('$_baseUrl/reverse?point.lat=$lat&point.lon=$lng&key=$_apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;
        if (features.isNotEmpty) {
          return TrackAsiaPlace.fromJson(features[0]);
        }
      }
    } catch (e) {
      debugPrint('TrackAsia Reverse Exception: $e');
    }
    return null;
  }

  /// Alias for autocomplete but returning List<Map> for Controller compatibility
  Future<List<Map<String, dynamic>>> searchPlace(String query) async {
    final places = await autocomplete(query);
    return places.map((p) => {
      'display_name': p.label,
      'lat': p.latitude,
      'lon': p.longitude,
      'name': p.name,
    }).toList();
  }

  /// Get routing points and info between two coordinates
  Future<Map<String, dynamic>> getRoute(double startLat, double startLon, double endLat, double endLon) async {
    // 1. Thử dùng TrackAsia trước
    final trackAsiaUrl = Uri.parse('https://maps.track-asia.com/api/v1/routing?point=$startLat,$startLon&point=$endLat,$endLon&key=$_apiKey&vehicle=car&points_encoded=true');

    try {
      final response = await http.get(trackAsiaUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['paths'] != null && (data['paths'] as List).isNotEmpty) {
          final route = data['paths'][0];
          return {
            'points': _decodePolyline(route['points']),
            'distance': (route['distance'] as num).toDouble() / 1000,
            'duration': (route['time'] as num).toDouble() / 60000,
          };
        }
      }
    } catch (e) {
      debugPrint('TrackAsia Route Error, switching to OSRM: $e');
    }

    // 2. Nếu TrackAsia lỗi, dùng OSRM làm dự phòng (Rất ổn định)
    final osrmUrl = Uri.parse('https://router.project-osrm.org/route/v1/driving/$startLon,$startLat;$endLon,$endLat?overview=full&geometries=polyline');
    
    try {
      final response = await http.get(osrmUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          return {
            'points': _decodePolyline(route['geometry']),
            'distance': (route['distance'] as num).toDouble() / 1000,
            'duration': (route['duration'] as num).toDouble() / 60,
          };
        }
      }
    } catch (e) {
      debugPrint('OSRM Route Error: $e');
    }

    return {'points': [], 'distance': 0.0, 'duration': 0.0};
  }

  List<dynamic> _decodePolyline(String encoded) {
    // Basic Polyline Decoder
    List<dynamic> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
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

      // Using generic object for points, usually converted to LatLng in controller
      points.add({'lat': lat / 1E5, 'lon': lng / 1E5});
    }
    return points;
  }
}
