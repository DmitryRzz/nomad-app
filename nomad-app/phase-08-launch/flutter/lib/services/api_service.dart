import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_storage_service.dart';
import 'offline_sync_service.dart';

class ApiService {
  static const String baseUrl = 'https://api.nomad.app'; // Replace with your API URL
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final LocalStorageService _storage = LocalStorageService();
  final OfflineSyncService _syncService = OfflineSyncService();
  bool _isRefreshing = false;

  // Check connectivity
  Future<bool> get hasConnection async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    final tokens = await _storage.getTokens();
    return {
      'Content-Type': 'application/json',
      if (tokens != null) 'Authorization': 'Bearer ${tokens.accessToken}',
    };
  }

  // Refresh token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh
      await Future.delayed(const Duration(milliseconds: 500));
      final tokens = await _storage.getTokens();
      return tokens != null;
    }

    _isRefreshing = true;
    try {
      final tokens = await _storage.getTokens();
      if (tokens == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': tokens.refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newTokens = AuthTokens.fromJson(data['tokens']);
        await _storage.saveTokens(newTokens);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // Generic HTTP methods with retry and offline support
  Future<ApiResponse> get(String endpoint) async {
    return _request('GET', endpoint);
  }

  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    return _request('POST', endpoint, body: body);
  }

  Future<ApiResponse> patch(String endpoint, {Map<String, dynamic>? body}) async {
    return _request('PATCH', endpoint, body: body);
  }

  Future<ApiResponse> delete(String endpoint) async {
    return _request('DELETE', endpoint);
  }

  Future<ApiResponse> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    int retryCount = 0,
  }) async {
    final isConnected = await hasConnection;

    if (!isConnected) {
      // Queue for sync
      await _syncService.queueAction(
        endpoint: endpoint,
        method: method,
        body: body,
      );
      return ApiResponse(
        success: false,
        error: 'No internet connection. Action queued for sync.',
        statusCode: 0,
      );
    }

    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('$baseUrl$endpoint');

      late final http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw UnsupportedError('HTTP method $method not supported');
      }

      // Handle token expiration
      if (response.statusCode == 401 && retryCount == 0) {
        final refreshed = await _refreshToken();
        if (refreshed) {
          return _request(method, endpoint, body: body, retryCount: 1);
        }
      }

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          data: data,
          statusCode: response.statusCode,
        );
      } else {
        return ApiResponse(
          success: false,
          error: data['error'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      // Queue for sync on network error
      await _syncService.queueAction(
        endpoint: endpoint,
        method: method,
        body: body,
      );
      return ApiResponse(
        success: false,
        error: 'Network error. Action queued for sync.',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
        statusCode: 500,
      );
    }
  }
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });
}
