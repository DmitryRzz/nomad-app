class Database {
  Future<List<Map<String, dynamic>>> query(String table, {List<String>? columns, String? where, List<dynamic>? whereArgs, String? orderBy}) async => [];
  Future<int> insert(String table, Map<String, dynamic> values, {dynamic conflictAlgorithm}) async => 0;
  Future<int> update(String table, Map<String, dynamic> values, {String? where, List<dynamic>? whereArgs}) async => 0;
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) async => 0;
  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async => 0;
  Future<void> close() async {}
}

class ConflictAlgorithm {
  static const replace = 1;
}

Future<Database> openDatabase(String path, {int? version, Function? onCreate, Function? onUpgrade}) async => Database();
Future<String> getDatabasesPath() async => '/tmp';
