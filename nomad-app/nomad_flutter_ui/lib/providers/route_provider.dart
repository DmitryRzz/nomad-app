import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/route.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final routesProvider = StateNotifierProvider<RoutesNotifier, AsyncValue<List<Route>>>((ref) {
  return RoutesNotifier(ref.read(apiServiceProvider));
});

class RoutesNotifier extends StateNotifier<AsyncValue<List<Route>>> {
  final ApiService _apiService;

  RoutesNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadRoutes();
  }

  Future<void> loadRoutes() async {
    state = const AsyncValue.loading();
    try {
      final routes = await _apiService.getUserRoutes();
      state = AsyncValue.data(routes);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<Route?> createRoute(RouteGenerationRequest request) async {
    try {
      final route = await _apiService.createRoute(request);
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

final selectedRouteProvider = StateProvider<Route?>((ref) => null);
