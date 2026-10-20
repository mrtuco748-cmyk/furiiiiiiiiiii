import 'package:flutter/foundation.dart';
import '../../models/gallery_item.dart';
import '../../supabase_config.dart';

/// Servicio de persistencia y red para los comentarios de fotos de la galería.
class GalleryCommentsService {
  static Future<GalleryComment?> addComment({
    required int galleryId,
    required String userId,
    required String content,
  }) async {
    try {
      final row = await SupabaseConfig.client
          .from('gallery_comments')
          .insert({
            'gallery_id': galleryId,
            'user_id': userId,
            'content': content,
          })
          .select()
          .single()
          .timeout(const Duration(seconds: 10));
      return GalleryComment.fromMap(Map<String, dynamic>.from(row as Map));
    } catch (e) {
      debugPrint('GalleryCommentsService.addComment error: $e');
      return null;
    }
  }

  static Future<void> deleteComment(int id) async {
    try {
      await SupabaseConfig.client
          .from('gallery_comments')
          .delete()
          .eq('id', id)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('GalleryCommentsService.deleteComment error: $e');
    }
  }

  static Future<List<GalleryComment>> loadComments(int galleryId) async {
    try {
      final res = await SupabaseConfig.client
          .from('gallery_comments')
          .select()
          .eq('gallery_id', galleryId)
          .order('created_at', ascending: true)
          .timeout(const Duration(seconds: 10));
      return (res as List)
          .map((e) => GalleryComment.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('GalleryCommentsService.loadComments error: $e');
      return [];
    }
  }
}
