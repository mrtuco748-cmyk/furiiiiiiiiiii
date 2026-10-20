import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../app_state.dart';
import '../../database/database_helper.dart';
import '../../models/music_playlist.dart';
import '../../models/music_track.dart';
import '../../supabase_config.dart';

class MusicPlaylistsManager {
  final VoidCallback onNotify;

  MusicPlaylistsManager({required this.onNotify});

  List<MusicPlaylist> _playlists = [];
  MusicPlaylist? _currentPlaylist;

  List<MusicPlaylist> get playlists => _playlists;
  MusicPlaylist? get currentPlaylist => _currentPlaylist;
  set currentPlaylist(MusicPlaylist? p) {
    _currentPlaylist = p;
    onNotify();
  }

  Future<void> pullPlaylistsFromCloud() async {
    try {
      final data = await SupabaseConfig.client
          .from('music_playlists')
          .select()
          .order('id', ascending: false)
          .timeout(const Duration(seconds: 10));
      final cloud = (data as List)
          .map((r) => MusicPlaylist.fromCloudRow(Map<String, dynamic>.from(r as Map)))
          .toList();

      final db = await DatabaseHelper().database;
      for (final p in cloud) {
        if (p.cloudId == null) continue;
        final existing = await db.query('music_playlists', where: 'cloud_id = ?', whereArgs: [p.cloudId]);
        if (existing.isEmpty) {
          await db.insert('music_playlists', p.toMap());
        } else {
          await db.update('music_playlists', p.toMap(), where: 'cloud_id = ?', whereArgs: [p.cloudId]);
        }
      }
    } catch (e) {
      developer.log('pullPlaylistsFromCloud error: $e');
    }
  }

  Future<void> reloadPlaylistsFromLocal() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('music_playlists', orderBy: 'id DESC');
    _playlists = rows.map((r) => MusicPlaylist.fromMap(Map<String, dynamic>.from(r))).toList();
    onNotify();
  }

  Future<MusicPlaylist?> createPlaylist(String title, [String description = '']) async {
    if (title.trim().isEmpty) return null;
    final rawIdentity = AppState.identity;
    final user = (rawIdentity != null && rawIdentity.isNotEmpty) ? rawIdentity : 'Facu';
    final now = DateTime.now().toIso8601String();

    try {
      final res = await SupabaseConfig.client
          .from('music_playlists')
          .insert({
            'title': title.trim(),
            'description': description.trim(),
            'created_by': user,
            'track_ids': [],
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      final playlist = MusicPlaylist.fromCloudRow(Map<String, dynamic>.from(res));
      final db = await DatabaseHelper().database;
      final localId = await db.insert('music_playlists', playlist.toMap());
      final saved = playlist.copyWith(id: localId);

      _playlists.insert(0, saved);
      onNotify();
      return saved;
    } catch (e) {
      developer.log('createPlaylist error: $e');
      return null;
    }
  }

  Future<void> toggleTrackInPlaylist(MusicPlaylist playlist, int trackIdentifier) async {
    final nextIds = List<int>.from(playlist.trackIds);
    if (nextIds.contains(trackIdentifier)) {
      nextIds.remove(trackIdentifier);
    } else {
      nextIds.add(trackIdentifier);
    }

    final updated = playlist.copyWith(trackIds: nextIds);
    final idx = _playlists.indexWhere((p) => p.id == playlist.id || (p.cloudId != null && p.cloudId == playlist.cloudId));
    if (idx != -1) {
      _playlists[idx] = updated;
      onNotify();
    }

    try {
      final db = await DatabaseHelper().database;
      if (playlist.id != null) {
        await db.update('music_playlists', updated.toMap(), where: 'id = ?', whereArgs: [playlist.id]);
      }

      if (playlist.cloudId != null) {
        await SupabaseConfig.client
            .from('music_playlists')
            .update({
              'track_ids': nextIds,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', playlist.cloudId!);
      }
    } catch (e) {
      developer.log('toggleTrackInPlaylist error: $e');
    }
  }

  Future<void> deletePlaylist(MusicPlaylist playlist) async {
    _playlists.removeWhere((p) => p.id == playlist.id && p.cloudId == playlist.cloudId);
    if (_currentPlaylist?.cloudId == playlist.cloudId || _currentPlaylist?.id == playlist.id) {
      _currentPlaylist = null;
    }
    onNotify();

    try {
      final db = await DatabaseHelper().database;
      if (playlist.id != null) {
        await db.delete('music_playlists', where: 'id = ?', whereArgs: [playlist.id]);
      }
      if (playlist.cloudId != null) {
        await SupabaseConfig.client.from('music_playlists').delete().eq('id', playlist.cloudId!);
      }
    } catch (e) {
      developer.log('deletePlaylist error: $e');
    }
  }

  List<MusicTrack> getTracksForPlaylist(MusicPlaylist playlist, List<MusicTrack> allTracks) {
    return allTracks.where((t) {
      final cid = t.cloudId;
      final lid = t.id;
      return (cid != null && playlist.trackIds.contains(cid)) ||
             (lid != null && playlist.trackIds.contains(lid));
    }).toList();
  }
}
