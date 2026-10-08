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
    return openDatabase(path, version: 12, onCreate: _createTables, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ORDEN DE MIGRACIÓN: los bloques corren en orden ASCENDENTE de versión
    // para que columnas/tablas existan cuando las referencian. (Antes el bloque
    // <8 creaba el índice de class_schedules.cloudId ANTES de agregar la
    // columna en <6 → excepción en upgrades v2..v5.)
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
    if (oldVersion < 6) {
      await db.execute("ALTER TABLE class_schedules ADD COLUMN cloudId INTEGER");
    }
    if (oldVersion < 8) {
      await db.execute("ALTER TABLE schedules ADD COLUMN cloudId INTEGER");
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_schedules_cloudId
        ON schedules(cloudId) WHERE cloudId IS NOT NULL
      ''');
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_class_schedules_cloudId
        ON class_schedules(cloudId) WHERE cloudId IS NOT NULL
      ''');
    }
    if (oldVersion < 9) {
      // Dirty flag para re-push de ediciones offline en calendario.
      await db.execute("ALTER TABLE schedules ADD COLUMN synced INTEGER NOT NULL DEFAULT 1");
      await db.execute("ALTER TABLE class_schedules ADD COLUMN synced INTEGER NOT NULL DEFAULT 1");
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL DEFAULT '',
          content TEXT DEFAULT '',
          color TEXT NOT NULL DEFAULT '#FFF9C4',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 11) {
      // Sync de notas con Supabase: cloudId (PK cloud) + author + dirty flag.
      await db.execute("ALTER TABLE notes ADD COLUMN cloud_id INTEGER");
      await db.execute("ALTER TABLE notes ADD COLUMN synced INTEGER NOT NULL DEFAULT 1");
      await db.execute("ALTER TABLE notes ADD COLUMN user_id TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 12) {
      // updatedAt para el merge local<->cloud de clases (mismo patrón que
      // schedules): evita que una edición offline pierda contra la cloud vieja.
      await db.execute("ALTER TABLE class_schedules ADD COLUMN updatedAt TEXT DEFAULT ''");
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
        cloudId INTEGER,
        synced INTEGER NOT NULL DEFAULT 1,
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
        color INTEGER DEFAULT 0xFF7B2D8E,
        cloudId INTEGER,
        synced INTEGER NOT NULL DEFAULT 1,
        updatedAt TEXT DEFAULT ''
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
    await db.insert('class_types', {'name': 'Clase', 'color': 0xFF00D4FF});
    await db.insert('class_types', {'name': 'Práctico', 'color': 0xFF39FF14});
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_media_local (
        message_id INTEGER PRIMARY KEY,
        local_path TEXT NOT NULL,
        file_name TEXT,
        mime_type TEXT
      )
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_schedules_cloudId
      ON schedules(cloudId) WHERE cloudId IS NOT NULL
    ''');
    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_class_schedules_cloudId
      ON class_schedules(cloudId) WHERE cloudId IS NOT NULL
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cloud_id INTEGER,
        synced INTEGER NOT NULL DEFAULT 1,
        user_id TEXT NOT NULL DEFAULT '',
        title TEXT NOT NULL DEFAULT '',
        content TEXT DEFAULT '',
        color TEXT NOT NULL DEFAULT '#FFF9C4',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
