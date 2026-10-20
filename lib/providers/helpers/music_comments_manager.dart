import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

import '../../app_state.dart';
import '../../database/database_helper.dart';
import '../../models/music_comment.dart';
import '../../supabase_config.dart';

class MusicCommentsManager {
  final VoidCallback onNotify;

  MusicCommentsManager({required this.onNotify});

  final Map<int, List<MusicComment>> _commentsByTrack = {};
  final Set<int> _loadingCommentsForTrack = {};

  Map<int, List<MusicComment>> get commentsByTrack => _commentsByTrack;

  List<MusicComment> getCommentsForTrack(int trackId) {
    return _commentsByTrack[trackId] ?? [];
  }

  Future<void> loadComments(int trackId) async {
    if (_loadingCommentsForTrack.contains(trackId)) return;
    _loadingCommentsForTrack.add(trackId);

    try {
      final db = await DatabaseHelper().database;
      final local = await db.query('music_comments', where: 'track_id = ?', whereArgs: [trackId], orderBy: 'id ASC');
      _commentsByTrack[trackId] = local.map((m) => MusicComment.fromMap(m)).toList();
      onNotify();

      final cloudData = await SupabaseConfig.client
          .from('music_comments')
          .select()
          .eq('track_id', trackId)
          .order('id', ascending: true);

      final cloudComments = (cloudData as List)
          .map((r) => MusicComment.fromCloudRow(Map<String, dynamic>.from(r as Map)))
          .toList();

      _commentsByTrack[trackId] = cloudComments;
      onNotify();
    } catch (e) {
      developer.log('loadComments error: $e');
    } finally {
      _loadingCommentsForTrack.remove(trackId);
    }
  }

  Future<void> addComment(int trackId, String content) async {
    if (content.trim().isEmpty) return;
    final rawIdentity = AppState.identity;
    final user = (rawIdentity != null && rawIdentity.isNotEmpty) ? rawIdentity : 'Facu';
    final now = DateTime.now().toIso8601String();

    try {
      final res = await SupabaseConfig.client
          .from('music_comments')
          .insert({
            'track_id': trackId,
            'user_id': user,
            'content': content.trim(),
            'created_at': now,
          })
          .select()
          .single();

      final comment = MusicComment.fromCloudRow(Map<String, dynamic>.from(res));
      final list = _commentsByTrack[trackId] ?? [];
      _commentsByTrack[trackId] = [...list, comment];
      onNotify();

      final db = await DatabaseHelper().database;
      await db.insert('music_comments', comment.toMap());
    } catch (e) {
      developer.log('addComment error: $e');
    }
  }

  Future<void> deleteComment(MusicComment comment) async {
    try {
      final list = _commentsByTrack[comment.trackId] ?? [];
      _commentsByTrack[comment.trackId] = list
          .where((c) => (comment.cloudId != null ? c.cloudId != comment.cloudId : c.id != comment.id))
          .toList();
      onNotify();

      if (comment.cloudId != null) {
        await SupabaseConfig.client.from('music_comments').delete().eq('id', comment.cloudId!);
      }
      final db = await DatabaseHelper().database;
      if (comment.id != null) {
        await db.delete('music_comments', where: 'id = ?', whereArgs: [comment.id]);
      } else if (comment.cloudId != null) {
        await db.delete('music_comments', where: 'cloud_id = ?', whereArgs: [comment.cloudId]);
      }
    } catch (e) {
      developer.log('deleteComment error: $e');
    }
  }
}
