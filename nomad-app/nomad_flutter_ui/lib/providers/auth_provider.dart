import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  final bool isDemoMode;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.isDemoMode = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    bool? isDemoMode,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isDemoMode: isDemoMode ?? this.isDemoMode,
    );
  }
}

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
        _api.setTokens(tokens.accessToken, tokens.refreshToken);
        try {
          final response = await _api.getMe();
          if (response['user'] != null) {
            final freshUser = User.fromJson(response['user']);
            await _storage.saveUser(freshUser);
            state = state.copyWith(
              user: freshUser,
              isAuthenticated: true,
              isLoading: false,
            );
          } else {
            await logout();
          }
        } catch (e) {
          // Token invalid, try refresh
          final refreshed = await _api.refreshToken();
          if (refreshed) {
            try {
              final retry = await _api.getMe();
              if (retry['user'] != null) {
                final freshUser = User.fromJson(retry['user']);
                await _storage.saveUser(freshUser);
                state = state.copyWith(
                  user: freshUser,
                  isAuthenticated: true,
                  isLoading: false,
                );
                return;
              }
            } catch (_) {}
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
      final response = await _api.login(email, password);

      if (response['accessToken'] != null) {
        final tokens = AuthTokens(
          accessToken: response['accessToken'],
          refreshToken: response['refreshToken'],
        );
        final user = User.fromJson(response['user']);

        _api.setTokens(tokens.accessToken, tokens.refreshToken);
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
          error: response['error'] ?? 'Login failed',
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
      final response = await _api.register(email, password, name: name);

      if (response['accessToken'] != null) {
        final tokens = AuthTokens(
          accessToken: response['accessToken'],
          refreshToken: response['refreshToken'],
        );
        final user = User.fromJson(response['user']);

        _api.setTokens(tokens.accessToken, tokens.refreshToken);
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
          error: response['error'] ?? 'Registration failed',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void enableDemoMode() {
    state = state.copyWith(
      isDemoMode: true,
      isAuthenticated: false,
      isLoading: false,
    );
  }

  Future<void> logout() async {
    _api.clearTokens();
    await _storage.clearAll();
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> updateProfile({String? name, String? nativeLanguage}) async {
    try {
      // For demo, just update local state
      if (state.user != null) {
        final updatedUser = state.user!.copyWith(
          name: name,
          nativeLanguage: nativeLanguage,
        );
        await _storage.saveUser(updatedUser);
        state = state.copyWith(user: updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
