import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  SharedPreferences? _prefs;
  Database? _db;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _initDatabase();
  }

  // SQLite initialization for offline data
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nomad_offline.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Offline routes cache
        await db.execute('''
          CREATE TABLE IF NOT EXISTS offline_routes (
            id TEXT PRIMARY KEY,
            user_id TEXT,
            title TEXT,
            city TEXT,
            country TEXT,
            data TEXT,
            sync_status TEXT DEFAULT 'pending',
            created_at INTEGER,
            updated_at INTEGER
          )
        ''');

        // Offline POI cache
        await db.execute('''
          CREATE TABLE IF NOT EXISTS offline_poi (
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            category TEXT,
            latitude REAL,
            longitude REAL,
            city TEXT,
            data TEXT,
            cached_at INTEGER
          )
        ''');

        // Sync queue for actions performed offline
        await db.execute('''
          CREATE TABLE IF NOT EXISTS sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            body TEXT,
            headers TEXT,
            priority INTEGER DEFAULT 0,
            retry_count INTEGER DEFAULT 0,
            created_at INTEGER
          )
        ''');

        // Notifications cache
        await db.execute('''
          CREATE TABLE IF NOT EXISTS offline_notifications (
            id TEXT PRIMARY KEY,
            title TEXT,
            body TEXT,
            type TEXT,
            data TEXT,
            is_read INTEGER DEFAULT 0,
            created_at INTEGER
          )
        ''');
      },
    );
  }

  // Auth token persistence
  Future<void> saveTokens(AuthTokens tokens) async {
    await _prefs?.setString('auth_tokens', jsonEncode(tokens.toJson()));
  }

  Future<AuthTokens?> getTokens() async {
    final json = _prefs?.getString('auth_tokens');
    if (json == null) return null;
    return AuthTokens.fromJson(jsonDecode(json));
  }

  Future<void> clearTokens() async {
    await _prefs?.remove('auth_tokens');
  }

  // User persistence
  Future<void> saveUser(User user) async {
    await _prefs?.setString('user_data', jsonEncode(user.toJson()));
  }

  Future<User?> getUser() async {
    final json = _prefs?.getString('user_data');
    if (json == null) return null;
    return User.fromJson(jsonDecode(json));
  }

  Future<void> clearUser() async {
    await _prefs?.remove('user_data');
  }

  // Onboarding flag
  Future<bool> hasSeenOnboarding() async {
    return _prefs?.getBool('onboarding_seen') ?? false;
  }

  Future<void> setOnboardingSeen(bool seen) async {
    await _prefs?.setBool('onboarding_seen', seen);
  }

  // FCM Token
  Future<String?> getFcmToken() async {
    return _prefs?.getString('fcm_token');
  }

  Future<void> saveFcmToken(String token) async {
    await _prefs?.setString('fcm_token', token);
  }

  // Offline routes
  Future<void> cacheRoute(String id, Map<String, dynamic> data) async {
    await _db?.insert(
      'offline_routes',
      {
        'id': id,
        'data': jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedRoutes() async {
    final results = await _db?.query('offline_routes');
    return results?.map((r) {
      final data = jsonDecode(r['data'] as String);
      return {...data, 'sync_status': r['sync_status']};
    }).toList() ?? [];
  }

  // Sync queue
  Future<void> queueAction({
    required String action,
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    int priority = 0,
  }) async {
    await _db?.insert('sync_queue', {
      'action': action,
      'endpoint': endpoint,
      'method': method,
      'body': body != null ? jsonEncode(body) : null,
      'headers': headers != null ? jsonEncode(headers) : null,
      'priority': priority,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    return await _db?.query(
          'sync_queue',
          orderBy: 'priority DESC, created_at ASC',
        ) ??
        [];
  }

  Future<void> removeFromSyncQueue(int id) async {
    await _db?.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetryCount(int id) async {
    await _db?.rawUpdate(
      'UPDATE sync_queue SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // Notifications cache
  Future<void> cacheNotification(Map<String, dynamic> notification) async {
    await _db?.insert(
      'offline_notifications',
      {
        'id': notification['id'] ?? DateTime.now().toIso8601String(),
        'title': notification['title'],
        'body': notification['body'],
        'type': notification['type'] ?? 'general',
        'data': notification['data'] != null ? jsonEncode(notification['data']) : null,
        'is_read': notification['is_read'] ?? 0,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    return await _db?.query(
          'offline_notifications',
          orderBy: 'created_at DESC',
        ) ??
        [];
  }

  Future<void> markNotificationRead(String id) async {
    await _db?.update(
      'offline_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await _prefs?.clear();
    await _db?.delete('offline_routes');
    await _db?.delete('sync_queue');
    await _db?.delete('offline_notifications');
  }

  // Close database
  Future<void> close() async {
    await _db?.close();
  }
}
