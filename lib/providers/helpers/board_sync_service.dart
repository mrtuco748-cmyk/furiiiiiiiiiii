import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/board_element.dart';
import '../../supabase_config.dart';
import 'board_local_storage.dart';

class BoardSyncService {
  static const _tableName = BoardLocalStorage.tableName;

  static Future<void> pushUnsyncedToCloud() async {
    final database = await BoardLocalStorage.db;
    final result = await database.query(_tableName);
    for (final m in result) {
      final element = BoardElement.fromMap(Map<String, dynamic>.from(m));
      if (element.cloudId == null) {
        final cloudId = await insertCloud(element);
        if (cloudId != null && element.id != null) {
          await BoardLocalStorage.markSynced(element.id!, cloudId);
        }
      } else if (m['synced'] == 0) {
        try {
          await SupabaseConfig.client
              .from(_tableName)
              .update(element.toSupabaseMap())
              .eq('id', element.cloudId!);
          if (element.id != null) {
            await BoardLocalStorage.markSynced(element.id!, element.cloudId);
          }
        } catch (e) {
          developer.log('BoardSyncService re-push error: $e');
        }
      }
    }
  }

  static Future<void> pullFromCloud() async {
    final data = await SupabaseConfig.client
        .from(_tableName)
        .select()
        .timeout(const Duration(seconds: 10));
    final cloud = (data as List)
        .map((r) =>
            BoardElement.fromCloudRow(Map<String, dynamic>.from(r as Map)))
        .toList();

    final database = await BoardLocalStorage.db;
    final localRows = await database.query(_tableName);
    final localByCloud = <int, BoardElement>{};
    for (final m in localRows) {
      final el = BoardElement.fromMap(Map<String, dynamic>.from(m));
      if (el.cloudId != null) {
        localByCloud[el.cloudId!] = el;
      }
    }

    final cloudIds = <int>{};
    for (final c in cloud) {
      if (c.cloudId == null) continue;
      cloudIds.add(c.cloudId!);
      final local = localByCloud[c.cloudId!];
      if (local == null) {
        await database.insert(_tableName, c.toMap(includeId: false));
      } else {
        final localUp =
            DateTime.tryParse(local.updatedAt ?? '') ?? DateTime(1970);
        final cloudUp =
            DateTime.tryParse(c.updatedAt ?? '') ?? DateTime(1970);
        if (cloudUp.isAfter(localUp) && local.synced == 1) {
          await database.update(
            _tableName,
            c.toMap(includeId: false),
            where: 'id = ?',
            whereArgs: [local.id],
          );
        }
      }
    }

    for (final local in localByCloud.values) {
      if (!cloudIds.contains(local.cloudId!) && local.synced == 1) {
        await database
            .delete(_tableName, where: 'id = ?', whereArgs: [local.id]);
      }
    }
  }

  static Future<int?> insertCloud(BoardElement el) async {
    try {
      final res = await SupabaseConfig.client
          .from(_tableName)
          .insert(el.toSupabaseMap())
          .select('id')
          .single();
      return (res['id'] as num?)?.toInt();
    } catch (e) {
      developer.log('BoardSyncService insertCloud error: $e');
      return null;
    }
  }

  static Future<void> updateCloud(BoardElement el) async {
    if (el.cloudId == null) return;
    await SupabaseConfig.client
        .from(_tableName)
        .update(el.toSupabaseMap())
        .eq('id', el.cloudId!);
  }

  static Future<void> deleteCloud(int cloudId) async {
    await SupabaseConfig.client
        .from(_tableName)
        .delete()
        .eq('id', cloudId);
  }

  static Future<void> persistGeometryCloud({
    required int cloudId,
    required double x,
    required double y,
    required double width,
    required double height,
    required String updatedAt,
  }) async {
    await SupabaseConfig.client.from(_tableName).update({
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'updated_at': updatedAt,
    }).eq('id', cloudId);
  }

  static Future<void> persistGeometry(BoardElement el) async {
    if (el.id == null) return;
    final now = DateTime.now().toIso8601String();
    try {
      await BoardLocalStorage.updateGeometry(
        el.id!,
        x: el.x,
        y: el.y,
        width: el.width,
        height: el.height,
        now: now,
        synced: 0,
      );
      if (el.cloudId != null) {
        await persistGeometryCloud(
          cloudId: el.cloudId!,
          x: el.x,
          y: el.y,
          width: el.width,
          height: el.height,
          updatedAt: now,
        );
        await BoardLocalStorage.markSynced(el.id!, el.cloudId);
      }
    } catch (e) {
      developer.log('BoardSyncService persistGeometry error: $e');
    }
  }

  static Future<void> persistUpdate(BoardElement withTime) async {
    if (withTime.id == null) return;
    try {
      await BoardLocalStorage.updateElement(withTime);
      if (withTime.cloudId != null) {
        await updateCloud(withTime);
      }
    } catch (e) {
      developer.log('BoardSyncService persistUpdate error: $e');
    }
  }

  static Future<void> persistDelete(BoardElement el) async {
    if (el.id == null) return;
    try {
      await BoardLocalStorage.deleteElement(el.id!);
      if (el.cloudId != null) {
        await deleteCloud(el.cloudId!);
      }
    } catch (e) {
      developer.log('BoardSyncService persistDelete error: $e');
    }
  }

  static RealtimeChannel subscribeRealtime(
    void Function(PostgresChangePayload payload) onPayload,
  ) {
    return SupabaseConfig.client
        .channel('board_elements_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _tableName,
          callback: onPayload,
        )
        .subscribe();
  }
}
