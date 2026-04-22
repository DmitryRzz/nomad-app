import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route.dart';
import '../models/poi.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  
  // TODO: Add JWT token from auth
  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<Route>> getUserRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((r) => Route.fromJson(r))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching routes: $e');
      return [];
    }
  }

  Future<Route?> getRouteById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Route.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching route: $e');
      return null;
    }
  }

  Future<Route?> createRoute(RouteGenerationRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/routes'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return Route.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error creating route: $e');
      return null;
    }
  }

  Future<bool> updateStopStatus(String stopId, {bool? visited, bool? skipped}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/routes/stops/$stopId'),
        headers: headers,
        body: json.encode({
          'visited': visited,
          'skipped': skipped,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating stop: $e');
      return false;
    }
  }

  Future<bool> deleteRoute(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/routes/$id'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting route: $e');
      return false;
    }
  }

  // POI services for Smart Compass
  Future<List<POI>> getNearbyPOI(double lat, double lng, {int radius = 500, String? category, List<String> interests = const []}) async {
    try {
      final queryParams = {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radius.toString(),
        if (category != null) 'category': category,
        if (interests.isNotEmpty) 'interests': interests.join(','),
      };

      final response = await http.get(
        Uri.parse('$baseUrl/poi/nearby').replace(queryParameters: queryParams),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((p) => POI.fromJson(p))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching nearby POI: $e');
      return [];
    }
  }
}
