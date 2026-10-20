import 'package:sqflite/sqflite.dart';

/// Manejador de creación y actualización del esquema de base de datos SQLite local (v16).
class DatabaseMigrations {
  static const int currentVersion = 16;

  static Future<void> onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // ORDEN DE MIGRACIÓN: los bloques corren en orden ASCENDENTE de versión
    // para que columnas/tablas existan cuando las referencian.
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE schedules ADD COLUMN userId TEXT DEFAULT ''");
    }
    if (oldVersion < 4) {
      await db.execute(
          "ALTER TABLE class_schedules ADD COLUMN endTime TEXT DEFAULT ''");
      await db.execute(
          "ALTER TABLE class_schedules ADD COLUMN professor TEXT DEFAULT ''");
      await db.execute(
          "ALTER TABLE class_schedules ADD COLUMN userId TEXT DEFAULT ''");
      await db.execute(
          "ALTER TABLE class_schedules ADD COLUMN color INTEGER DEFAULT 0xFF7B2D8E");
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
      await db.execute(
          "ALTER TABLE class_schedules ADD COLUMN cloudId INTEGER");
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
      await db.execute(
          "ALTER TABLE schedules ADD COLUMN synced INTEGER NOT NULL DEFAULT 1");
      await db.execute(
          "ALTER TABLE class_schedules ADD COLUMN synced INTEGER NOT NULL DEFAULT 1");
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
      await db.execute("ALTER TABLE notes ADD COLUMN cloud_id INTEGER");
      await db.execute(
          "ALTER TABLE notes ADD COLUMN synced INTEGER NOT NULL DEFAULT 1");
      await db.execute(
          "ALTER TABLE notes ADD COLUMN user_id TEXT NOT NULL DEFAULT ''");
    }
    if (oldVersion < 12) {
      await db.execute(
          "ALTER TABLE class_schedules ADD COLUMN updatedAt TEXT DEFAULT ''");
    }
    if (oldVersion < 13) {
      await db.execute(
          "ALTER TABLE schedules ADD COLUMN recurrence TEXT DEFAULT ''");
    }
    if (oldVersion < 14) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS board_elements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cloud_id INTEGER,
          board_id INTEGER NOT NULL DEFAULT 1,
          user_id TEXT NOT NULL DEFAULT '',
          type TEXT NOT NULL DEFAULT 'note',
          title TEXT NOT NULL DEFAULT '',
          content TEXT DEFAULT '',
          color TEXT NOT NULL DEFAULT '#9D00FF',
          x REAL NOT NULL DEFAULT 0.0,
          y REAL NOT NULL DEFAULT 0.0,
          width REAL NOT NULL DEFAULT 200.0,
          height REAL NOT NULL DEFAULT 160.0,
          data TEXT DEFAULT '{}',
          synced INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 15) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS music_tracks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cloud_id INTEGER,
          youtube_id TEXT NOT NULL,
          title TEXT NOT NULL,
          artist TEXT DEFAULT '',
          duration_seconds INTEGER DEFAULT 0,
          thumbnail_url TEXT DEFAULT '',
          audio_url TEXT DEFAULT '',
          local_path TEXT DEFAULT '',
          added_by TEXT DEFAULT '',
          size_bytes INTEGER DEFAULT 0,
          is_favorite INTEGER DEFAULT 0,
          synced INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 16) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS music_comments (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cloud_id INTEGER,
          track_id INTEGER NOT NULL,
          user_id TEXT NOT NULL DEFAULT '',
          content TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS music_playlists (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cloud_id INTEGER,
          title TEXT NOT NULL,
          description TEXT DEFAULT '',
          created_by TEXT NOT NULL DEFAULT '',
          track_ids TEXT DEFAULT '[]',
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  static Future<void> onCreate(Database db, int version) async {
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
        recurrence TEXT DEFAULT '',
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

    await db.insert('event_types',
        {'name': 'Práctico', 'color': 0xFFFF6B35, 'icon': 'restaurant_menu'});
    await db.insert('event_types',
        {'name': 'Examen', 'color': 0xFFFF5757, 'icon': 'school'});
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
    await db.execute('''
      CREATE TABLE IF NOT EXISTS board_elements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cloud_id INTEGER,
        board_id INTEGER NOT NULL DEFAULT 1,
        user_id TEXT NOT NULL DEFAULT '',
        type TEXT NOT NULL DEFAULT 'note',
        title TEXT NOT NULL DEFAULT '',
        content TEXT DEFAULT '',
        color TEXT NOT NULL DEFAULT '#9D00FF',
        x REAL NOT NULL DEFAULT 0.0,
        y REAL NOT NULL DEFAULT 0.0,
        width REAL NOT NULL DEFAULT 200.0,
        height REAL NOT NULL DEFAULT 160.0,
        data TEXT DEFAULT '{}',
        synced INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS music_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cloud_id INTEGER,
        youtube_id TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT DEFAULT '',
        duration_seconds INTEGER DEFAULT 0,
        thumbnail_url TEXT DEFAULT '',
        audio_url TEXT DEFAULT '',
        local_path TEXT DEFAULT '',
        added_by TEXT DEFAULT '',
        size_bytes INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        synced INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS music_comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cloud_id INTEGER,
        track_id INTEGER NOT NULL,
        user_id TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS music_playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cloud_id INTEGER,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        created_by TEXT NOT NULL DEFAULT '',
        track_ids TEXT DEFAULT '[]',
        created_at TEXT NOT NULL
      )
    ''');
  }
}
