import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route.dart' as route_model;
import '../services/api_service.dart';
import 'auth_provider.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final routesProvider = StateNotifierProvider<RoutesNotifier, AsyncValue<List<route_model.Route>>>((ref) {
  return RoutesNotifier(ref.read(apiServiceProvider), ref.read(authProvider));
});

class RoutesNotifier extends StateNotifier<AsyncValue<List<route_model.Route>>> {
  final ApiService _apiService;
  final AuthState _authState;

  RoutesNotifier(this._apiService, this._authState) : super(const AsyncValue.loading()) {
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    state = const AsyncValue.loading();
    try {
      if (_authState.isAuthenticated) {
        final routes = await _apiService.getUserRoutes();
        state = AsyncValue.data(routes);
      } else {
        // Load demo routes for guests
        final routes = await _apiService.getDemoRoutes();
        state = AsyncValue.data(routes);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<route_model.Route?> createRoute(dynamic routeData) async {
    try {
      final route = await _apiService.createRoute(routeData);
      if (route != null) {
        await loadRoutes();
      }
      return route;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteRoute(String id) async {
    final success = await _apiService.deleteRoute(id);
    if (success) {
      await loadRoutes();
    }
    return success;
  }
}

final selectedRouteProvider = StateProvider<route_model.Route?>((ref) => null);
