import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/route.dart' as route_model;
import '../models/poi.dart';
import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  String? _accessToken;
  String? _refreshToken;

  void setTokens(String accessToken, String refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Map<String, String> get headers {
    final h = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) {
      h['Authorization'] = 'Bearer $_accessToken';
    }
    return h;
  }

  // Auth
  Future<Map<String, dynamic>> register(String email, String password, {String? name}) async {
    return post('/auth/register', body: {
      'email': email,
      'password': password,
      if (name != null) 'name': name,
    });
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return post('/auth/login', body: {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> refresh() async {
    return post('/auth/refresh', body: {
      'refreshToken': _refreshToken,
    });
  }

  Future<Map<String, dynamic>> getMe() async {
    return get('/auth/me');
  }

  // Routes
  Future<List<route_model.Route>> getUserRoutes() async {
    try {
      final data = await get('/routes');
      final routes = data['routes'] as List<dynamic>? ?? [];
      return routes.map((r) => route_model.Route.fromJson(r)).toList();
    } catch (e) {
      print('Error fetching routes: $e');
      return [];
    }
  }

  Future<List<route_model.Route>> getDemoRoutes() async {
    try {
      final data = await get('/routes/demo');
      final routes = data['routes'] as List<dynamic>? ?? [];
      return routes.map((r) => route_model.Route.fromJson(r)).toList();
    } catch (e) {
      print('Error fetching demo routes: $e');
      return [];
    }
  }

  Future<route_model.Route?> getRouteById(String id) async {
    try {
      final data = await get('/routes/$id');
      final route = data['route'];
      if (route != null) {
        return route_model.Route.fromJson(route);
      }
      return null;
    } catch (e) {
      print('Error fetching route: $e');
      return null;
    }
  }

  Future<route_model.Route?> createRoute(dynamic routeData) async {
    try {
      final Map<String, dynamic> body = routeData is Map<String, dynamic> 
          ? routeData 
          : routeData.toJson();
      final data = await post('/routes', body: body);
      final route = data['route'];
      if (route != null) {
        return route_model.Route.fromJson(route);
      }
      return null;
    } catch (e) {
      print('Error creating route: $e');
      return null;
    }
  }

  Future<bool> deleteRoute(String id) async {
    try {
      await delete('/routes/$id');
      return true;
    } catch (e) {
      print('Error deleting route: $e');
      return false;
    }
  }

  // POI
  Future<List<POI>> getPOIByCity(String city) async {
    try {
      final data = await get('/poi/$city');
      final poi = data['poi'] as List<dynamic>? ?? [];
      return poi.map((p) => POI.fromJson(p)).toList();
    } catch (e) {
      print('Error fetching POI: $e');
      return [];
    }
  }

  Future<List<POI>> getAllPOI() async {
    try {
      final data = await get('/poi');
      final poi = data['poi'] as List<dynamic>? ?? [];
      return poi.map((p) => POI.fromJson(p)).toList();
    } catch (e) {
      print('Error fetching POI: $e');
      return [];
    }
  }

  Future<List<POI>> getNearbyPOI(double lat, double lng, {int radius = 500, String? category, List<String> interests = const []}) async {
    try {
      final data = await get('/poi');
      final poi = data['poi'] as List<dynamic>? ?? [];
      return poi.map((p) => POI.fromJson(p)).toList();
    } catch (e) {
      print('Error fetching nearby POI: $e');
      return [];
    }
  }

  // Generic HTTP methods
  Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(body['error'] ?? 'Request failed', response.statusCode);
    }
    return body;
  }

  Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );
    final responseBody = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(responseBody['error'] ?? 'Request failed', response.statusCode);
    }
    return responseBody;
  }

  Future<Map<String, dynamic>> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );
    final responseBody = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(responseBody['error'] ?? 'Request failed', response.statusCode);
    }
    return responseBody;
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    final body = json.decode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(body['error'] ?? 'Request failed', response.statusCode);
    }
    return body;
  }

  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;
    try {
      final data = await post('/auth/refresh', body: {'refreshToken': _refreshToken});
      if (data['accessToken'] != null) {
        _accessToken = data['accessToken'];
        return true;
      }
    } catch (e) {
      print('Token refresh failed: $e');
    }
    return false;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  
  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}
