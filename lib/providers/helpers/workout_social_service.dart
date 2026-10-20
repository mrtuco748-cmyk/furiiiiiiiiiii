import 'dart:developer' as developer;
import '../../models/workout_challenge.dart';
import '../../models/workout_log.dart';
import '../../models/workout_routine.dart';
import '../../models/workout_social.dart';
import '../../supabase_config.dart';

class WorkoutSocialService {
  static Future<Map<String, List<String>>?> reactViaRpc({
    required String table,
    required int id,
    required String key,
    required String userId,
  }) async {
    try {
      final res = await SupabaseConfig.client
          .rpc('toggle_reaction', params: {
            'target_table': table,
            'target_col': 'social',
            'row_id': id,
            'reaction_key': key,
            'user_id': userId,
          })
          .timeout(const Duration(seconds: 10));
      if (res == null) return null;
      return WorkoutSocial.fromMap({'reactions': res}).reactions;
    } catch (e) {
      developer.log('WorkoutSocialService.reactViaRpc error: $e');
      return null;
    }
  }

  static Future<WorkoutSocial?> commentViaRpc({
    required String table,
    required int id,
    required String action,
    Map<String, dynamic>? comment,
    String? commentId,
  }) async {
    try {
      final fn = action == 'add'
          ? 'add_workout_comment'
          : 'delete_workout_comment';
      final res = await SupabaseConfig.client
          .rpc(fn, params: {
            'target_table': table,
            'row_id': id,
            'comment': ?comment,
            'comment_id': ?commentId,
          })
          .timeout(const Duration(seconds: 10));
      if (res == null) return null;
      return WorkoutSocial.fromMap(res);
    } catch (e) {
      developer.log('WorkoutSocialService.commentViaRpc error: $e');
      return null;
    }
  }

  static WorkoutLog mergeLog(WorkoutLog local, WorkoutLog cloud) =>
      cloud.copyWith(
        social: WorkoutSocial(
          reactions: WorkoutSocial.mergeReactions(
              local.social.reactions, cloud.social.reactions),
          comments: WorkoutSocial.mergeComments(
              local.social.comments, cloud.social.comments),
        ),
      );

  static WorkoutRoutine mergeRoutine(
          WorkoutRoutine local, WorkoutRoutine cloud) =>
      cloud.copyWith(
        social: WorkoutSocial(
          reactions: WorkoutSocial.mergeReactions(
              local.social.reactions, cloud.social.reactions),
          comments: WorkoutSocial.mergeComments(
              local.social.comments, cloud.social.comments),
        ),
      );

  static WorkoutChallenge mergeChallenge(
    WorkoutChallenge local,
    WorkoutChallenge cloud,
  ) =>
      cloud.copyWith(
        social: WorkoutSocial(
          reactions: WorkoutSocial.mergeReactions(
              local.social.reactions, cloud.social.reactions),
          comments: WorkoutSocial.mergeComments(
              local.social.comments, cloud.social.comments),
        ),
      );
}
