import 'dart:convert';
import 'local_storage_service.dart';
import 'api_service.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  factory OfflineSyncService() => _instance;
  OfflineSyncService._internal();

  final LocalStorageService _storage = LocalStorageService();
  bool _isSyncing = false;

  Future<void> queueAction({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
  }) async {
    await _storage.queueAction(
      action: '${method}_$endpoint',
      endpoint: endpoint,
      method: method,
      body: body,
      priority: _getPriority(endpoint),
    );
  }

  int _getPriority(String endpoint) {
    // Higher priority for user-initiated actions
    if (endpoint.contains('bookings')) return 10;
    if (endpoint.contains('payments')) return 10;
    if (endpoint.contains('routes')) return 5;
    return 0;
  }

  Future<SyncResult> syncPendingActions() async {
    if (_isSyncing) return SyncResult(nothingToSync: true);
    
    _isSyncing = true;
    int synced = 0;
    int failed = 0;
    List<String> errors = [];

    try {
      final queue = await _storage.getSyncQueue();
      
      if (queue.isEmpty) {
        return SyncResult(nothingToSync: true);
      }

      final api = ApiService();
      final isConnected = await api.hasConnection;

      if (!isConnected) {
        return SyncResult(nothingToSync: true, offline: true);
      }

      for (final item in queue) {
        try {
          final retryCount = item['retry_count'] as int? ?? 0;
          
          if (retryCount > 5) {
            await _storage.removeFromSyncQueue(item['id'] as int);
            failed++;
            errors.add('Max retries exceeded for ${item['action']}');
            continue;
          }

          Map<String, dynamic> response;
          final method = item['method'] as String;
          final endpoint = item['endpoint'] as String;
          final body = item['body'] != null 
            ? jsonDecode(item['body'] as String) as Map<String, dynamic>
            : null;

          switch (method) {
            case 'POST':
              response = await api.post(endpoint, body: body);
              break;
            case 'PATCH':
              response = await api.patch(endpoint, body: body);
              break;
            case 'DELETE':
              response = {'success': await api.delete(endpoint)};
              break;
            default:
              response = await api.get(endpoint);
          }

          if (response['success'] == true) {
            await _storage.removeFromSyncQueue(item['id'] as int);
            synced++;
          } else {
            await _storage.incrementRetryCount(item['id'] as int);
            failed++;
            errors.add(response['error'] ?? 'Unknown error');
          }
        } catch (e) {
          await _storage.incrementRetryCount(item['id'] as int);
          failed++;
          errors.add(e.toString());
        }
      }

      return SyncResult(
        synced: synced,
        failed: failed,
        errors: errors,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Stream<SyncProgress> get syncProgress async* {
    while (_isSyncing) {
      final queue = await _storage.getSyncQueue();
      yield SyncProgress(
        pendingCount: queue.length,
        isSyncing: _isSyncing,
      );
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

class SyncResult {
  final int synced;
  final int failed;
  final List<String> errors;
  final bool nothingToSync;
  final bool offline;

  SyncResult({
    this.synced = 0,
    this.failed = 0,
    this.errors = const [],
    this.nothingToSync = false,
    this.offline = false,
  });

  bool get success => failed == 0 && synced > 0;
}

class SyncProgress {
  final int pendingCount;
  final bool isSyncing;

  SyncProgress({
    required this.pendingCount,
    required this.isSyncing,
  });
}
