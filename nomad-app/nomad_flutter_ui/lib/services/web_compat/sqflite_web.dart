// Web-compatible SQLite stub using SharedPreferences
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Database {
  final String _name;
  SharedPreferences? _prefs;
  
  Database(this._name);
  
  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  Future<List<Map<String, dynamic>>> query(String table, {List<String>? columns, String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    await _init();
    final data = _prefs?.getStringList('db_$_name\_$table') ?? [];
    return data.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }
  
  Future<int> insert(String table, Map<String, dynamic> values, {dynamic conflictAlgorithm}) async {
    await _init();
    final data = _prefs?.getStringList('db_$_name\_$table') ?? [];
    data.add(jsonEncode(values));
    await _prefs?.setStringList('db_$_name\_$table', data);
    return values['id']?.hashCode ?? DateTime.now().millisecondsSinceEpoch;
  }
  
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs}) async {
    await _init();
    // Simplified - just append for demo
    return insert(table, values);
  }
  
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async {
    await _init();
    await _prefs?.remove('db_$_name\_$table');
    return 0;
  }
  
  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async => 0;
  Future<void> close() async {}
}

class ConflictAlgorithm {
  static const replace = 1;
}

Future<Database> openDatabase(String path, {int? version, Function? onCreate, Function? onUpgrade}) async {
  final db = Database('nomad');
  if (onCreate != null) {
    // Simulate table creation
  }
  return db;
}

Future<String> getDatabasesPath() async => 'web_db';

class Batch {
  final List<Map<String, dynamic>> _operations = [];
  void insert(String table, Map<String, dynamic> values) => _operations.add(values);
  Future<List<Object?>> commit() async => [];
}
