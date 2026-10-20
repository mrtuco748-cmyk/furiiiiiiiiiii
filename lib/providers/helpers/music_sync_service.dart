import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/database_helper.dart';
import '../../models/music_track.dart';
import '../../supabase_config.dart';

class MusicSyncService {
  static const String tableName = 'music_tracks';

  static Future<List<MusicTrack>> reloadFromLocal() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(tableName, orderBy: 'id DESC');
    return result.map((m) => MusicTrack.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  static Future<void> pullFromCloud() async {
    final data = await SupabaseConfig.client
        .from(tableName)
        .select()
        .timeout(const Duration(seconds: 10));
    final cloud = (data as List)
        .map((r) => MusicTrack.fromCloudRow(Map<String, dynamic>.from(r as Map)))
        .toList();

    final db = await DatabaseHelper().database;
    final localRows = await db.query(tableName);
    final localByCloud = <int, MusicTrack>{};
    for (final m in localRows) {
      final t = MusicTrack.fromMap(Map<String, dynamic>.from(m));
      if (t.cloudId != null) localByCloud[t.cloudId!] = t;
    }

    for (final c in cloud) {
      if (c.cloudId == null) continue;
      final local = localByCloud[c.cloudId!];
      if (local == null) {
        await db.insert(tableName, c.toMap());
      }
    }
  }

  static RealtimeChannel subscribeRealtime({
    required void Function(MusicTrack track) onInsertTrack,
    required void Function(int cloudId) onDeleteTrack,
    required void Function() onPlaylistsChanged,
    required void Function(int trackId) onCommentsChanged,
  }) {
    return SupabaseConfig.client
        .channel('music_realtime_sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            final rec = payload.newRecord;
            if (payload.eventType == PostgresChangeEvent.insert && rec.isNotEmpty) {
              final incoming = MusicTrack.fromCloudRow(rec);
              if (incoming.cloudId != null) {
                onInsertTrack(incoming);
                DatabaseHelper().database.then((db) {
                  db.insert(tableName, incoming.toMap());
                });
              }
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              final oldRec = payload.oldRecord;
              final cloudId = (oldRec['id'] as num?)?.toInt();
              if (cloudId != null) {
                onDeleteTrack(cloudId);
                DatabaseHelper().database.then((db) {
                  db.delete(tableName, where: 'cloud_id = ?', whereArgs: [cloudId]);
                });
              }
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'music_playlists',
          callback: (_) => onPlaylistsChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'music_comments',
          callback: (payload) {
            final trackId = (payload.newRecord['track_id'] ?? payload.oldRecord['track_id']) as num?;
            if (trackId != null) {
              onCommentsChanged(trackId.toInt());
            }
          },
        )
        .subscribe();
  }
}
