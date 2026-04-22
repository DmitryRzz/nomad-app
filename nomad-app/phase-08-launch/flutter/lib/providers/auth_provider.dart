import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAuthStatus();
  }

  final ApiService _api = ApiService();
  final LocalStorageService _storage = LocalStorageService();

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);

    try {
      final tokens = await _storage.getTokens();
      final user = await _storage.getUser();

      if (tokens != null && user != null) {
        // Validate token by fetching current user
        final response = await _api.get('/auth/me');
        if (response.success) {
          final freshUser = User.fromJson(response.data['user']);
          await _storage.saveUser(freshUser);
          state = state.copyWith(
            user: freshUser,
            isAuthenticated: true,
            isLoading: false,
          );
        } else {
          // Token invalid, try refresh
          final refreshed = await _api._refreshToken();
          if (refreshed) {
            final retry = await _api.get('/auth/me');
            if (retry.success) {
              final freshUser = User.fromJson(retry.data['user']);
              await _storage.saveUser(freshUser);
              state = state.copyWith(
                user: freshUser,
                isAuthenticated: true,
                isLoading: false,
              );
              return;
            }
          }
          await logout();
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      if (response.success) {
        final tokens = AuthTokens.fromJson(response.data['tokens']);
        final user = User.fromJson(response.data['user']);

        await _storage.saveTokens(tokens);
        await _storage.saveUser(user);

        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Login failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String password, {String? name}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.post('/auth/register', body: {
        'email': email,
        'password': password,
        'name': name,
      });

      if (response.success) {
        final tokens = AuthTokens.fromJson(response.data['tokens']);
        final user = User.fromJson(response.data['user']);

        await _storage.saveTokens(tokens);
        await _storage.saveUser(user);

        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.error ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (e) {
      // Ignore logout API errors
    }

    await _storage.clearAll();
    state = AuthState();
  }

  Future<bool> updateProfile({String? name, String? nativeLanguage}) async {
    try {
      final response = await _api.patch('/auth/me', body: {
        if (name != null) 'name': name,
        if (nativeLanguage != null) 'native_language': nativeLanguage,
      });

      if (response.success) {
        final updatedUser = User.fromJson(response.data['user']);
        await _storage.saveUser(updatedUser);
        state = state.copyWith(user: updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
