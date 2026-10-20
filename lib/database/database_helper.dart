import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'database_migrations.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'furi_calendar.db');
    return openDatabase(
      path,
      version: DatabaseMigrations.currentVersion,
      onCreate: DatabaseMigrations.onCreate,
      onUpgrade: DatabaseMigrations.onUpgrade,
    );
  }

  Future<void> saveChatMediaLocal({
    required int messageId,
    required String localPath,
    String? fileName,
    String? mimeType,
  }) async {
    final db = await database;
    await db.insert(
      'chat_media_local',
      {
        'message_id': messageId,
        'local_path': localPath,
        'file_name': fileName,
        'mime_type': mimeType,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getChatMediaLocalPath(int messageId) async {
    final db = await database;
    final rows = await db.query(
      'chat_media_local',
      columns: ['local_path'],
      where: 'message_id = ?',
      whereArgs: [messageId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['local_path'] as String?;
  }

  Future<Map<int, String>> getAllChatMediaLocalPaths() async {
    final db = await database;
    final rows = await db.query('chat_media_local');
    final map = <int, String>{};
    for (final r in rows) {
      final id = r['message_id'];
      final path = r['local_path'] as String?;
      if (id is int && path != null && path.isNotEmpty) {
        map[id] = path;
      }
    }
    return map;
  }

  Future<int> insert(String table, Map<String, dynamic> values,
      {ConflictAlgorithm? conflictAlgorithm}) async {
    final db = await database;
    return db.insert(table, values, conflictAlgorithm: conflictAlgorithm);
  }

  Future<int> update(String table, Map<String, dynamic> values, int id) async {
    final db = await database;
    return db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAll(String table,
      {String? orderBy}) async {
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<List<Map<String, dynamic>>> getWhere(
      String table, String where, List<dynamic> whereArgs,
      {String? orderBy}) async {
    final db = await database;
    return db.query(table,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<Map<String, dynamic>?> getById(String table, int id) async {
    final db = await database;
    final res = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }
}
