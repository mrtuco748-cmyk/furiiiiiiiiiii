import 'dart:developer' as developer;
import 'package:sqflite/sqflite.dart';

import '../../app_state.dart';
import '../../database/database_helper.dart';
import '../../models/board_element.dart';

class BoardLocalStorage {
  static const tableName = 'board_elements';

  static Future<Database> get db => DatabaseHelper().database;

  static Future<List<BoardElement>> reloadFromLocal() async {
    final database = await db;
    var result = await database.query(tableName, orderBy: 'id ASC');
    if (result.isEmpty) {
      try {
        final legacy = await database.query('notes');
        if (legacy.isNotEmpty) {
          double curX = 100.0;
          double curY = 100.0;
          for (final n in legacy) {
            final title = n['title']?.toString() ?? 'Nota';
            final content = n['content']?.toString() ?? '';
            final color = n['color']?.toString() ?? '#9D00FF';
            await database.insert(tableName, {
              'board_id': 1,
              'user_id': n['user_id']?.toString() ?? AppState.identity,
              'type': 'note',
              'title': title,
              'content': content,
              'color': color,
              'x': curX,
              'y': curY,
              'width': 220.0,
              'height': 160.0,
              'data': '{}',
              'synced': 0,
              'created_at': n['created_at']?.toString() ??
                  DateTime.now().toIso8601String(),
              'updated_at': n['updated_at']?.toString() ??
                  DateTime.now().toIso8601String(),
            });
            curX += 240.0;
            if (curX > 800) {
              curX = 100.0;
              curY += 180.0;
            }
          }
          result = await database.query(tableName, orderBy: 'id ASC');
        }
      } catch (e) {
        developer.log('Error al migrar notas legacy: $e');
      }
    }
    return result.map((m) {
      final map = Map<String, dynamic>.from(m);
      return BoardElement.fromMap(map);
    }).toList();
  }

  static Future<int> insertElement(BoardElement el) async {
    final database = await db;
    return await database.insert(tableName, el.toMap());
  }

  static Future<void> updateGeometry(
    int localId, {
    required double x,
    required double y,
    required double width,
    required double height,
    required String now,
    int synced = 0,
  }) async {
    final database = await db;
    await database.update(
      tableName,
      {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'updated_at': now,
        'synced': synced,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<void> markSynced(int localId, int? cloudId) async {
    final database = await db;
    await database.update(
      tableName,
      {
        'cloud_id': ?cloudId,
        'synced': 1,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  static Future<void> updateElement(BoardElement el) async {
    if (el.id == null) return;
    final database = await db;
    await database.update(
      tableName,
      el.toMap(includeId: false),
      where: 'id = ?',
      whereArgs: [el.id],
    );
  }

  static Future<void> deleteElement(int localId) async {
    final database = await db;
    await database.delete(tableName, where: 'id = ?', whereArgs: [localId]);
  }

  static Future<void> deleteByCloudId(int cloudId) async {
    final database = await db;
    await database
        .delete(tableName, where: 'cloud_id = ?', whereArgs: [cloudId]);
  }

  static Future<int> insertFromCloud(BoardElement incoming) async {
    final database = await db;
    return await database.insert(
      tableName,
      incoming.toMap(includeId: false),
    );
  }
}
