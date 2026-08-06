import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    return openDatabase(path, version: 5, onCreate: _createTables, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS menu_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          date TEXT NOT NULL,
          mealType TEXT NOT NULL,
          recipeId INTEGER,
          recipeName TEXT,
          notes TEXT DEFAULT '',
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE schedules ADD COLUMN userId TEXT DEFAULT ''");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE class_schedules ADD COLUMN endTime TEXT DEFAULT ''");
      await db.execute("ALTER TABLE class_schedules ADD COLUMN professor TEXT DEFAULT ''");
      await db.execute("ALTER TABLE class_schedules ADD COLUMN userId TEXT DEFAULT ''");
      await db.execute("ALTER TABLE class_schedules ADD COLUMN color INTEGER DEFAULT 0xFF7B2D8E");
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS chat_media_local (
          message_id INTEGER PRIMARY KEY,
          local_path TEXT NOT NULL,
          file_name TEXT,
          mime_type TEXT
        )
      ''');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        location TEXT DEFAULT '',
        instructor TEXT DEFAULT '',
        type TEXT DEFAULT 'Clase',
        color INTEGER DEFAULT 0xFF7B2D8E,
        userId TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE event_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL,
        icon TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE class_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dayOfWeek INTEGER NOT NULL,
        classTypeId INTEGER,
        startTime TEXT NOT NULL,
        title TEXT NOT NULL,
        endTime TEXT DEFAULT '',
        professor TEXT DEFAULT '',
        userId TEXT DEFAULT '',
        color INTEGER DEFAULT 0xFF7B2D8E
      )
    ''');
    await db.execute('''
      CREATE TABLE class_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL
      )
    ''');

    await db.insert('event_types', {'name': 'Práctico', 'color': 0xFFFF6B35, 'icon': 'restaurant_menu'});
    await db.insert('event_types', {'name': 'Examen', 'color': 0xFFFF5757, 'icon': 'school'});
    await db.execute('''
      CREATE TABLE menu_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        mealType TEXT NOT NULL,
        recipeId INTEGER,
        recipeName TEXT,
        notes TEXT DEFAULT '',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
    await db.insert('class_types', {'name': 'Gastronomía 1', 'color': 0xFF7000FF});
    await db.insert('class_types', {'name': 'Pastelería 1', 'color': 0xFF39FF14});
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_media_local (
        message_id INTEGER PRIMARY KEY,
        local_path TEXT NOT NULL,
        file_name TEXT,
        mime_type TEXT
      )
    ''');
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

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  Future<int> update(String table, Map<String, dynamic> values, int id) async {
    final db = await database;
    return db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAll(String table, {String? orderBy}) async {
    final db = await database;
    return db.query(table, orderBy: orderBy);
  }

  Future<List<Map<String, dynamic>>> getWhere(String table, String where, List<dynamic> whereArgs, {String? orderBy}) async {
    final db = await database;
    return db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<Map<String, dynamic>?> getById(String table, int id) async {
    final db = await database;
    final res = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }
}
