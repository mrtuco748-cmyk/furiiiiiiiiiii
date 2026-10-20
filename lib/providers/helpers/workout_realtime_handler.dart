import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/workout_challenge.dart';
import '../../models/workout_completion.dart';
import '../../models/workout_log.dart';
import '../../models/workout_routine.dart';
import '../../supabase_config.dart';
import 'workout_database_service.dart';
import 'workout_social_service.dart';

class WorkoutRealtimeHandler {
  RealtimeChannel? _channel;
  bool _realtimeUp = false;

  void subscribe({
    required List<WorkoutLog> Function() getLogs,
    required List<WorkoutRoutine> Function() getRoutines,
    required List<WorkoutCompletion> Function() getCompletions,
    required List<WorkoutChallenge> Function() getChallenges,
    required void Function() onNotify,
  }) {
    if (_realtimeUp) return;
    _realtimeUp = true;
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('workouts_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: WorkoutDatabaseService.logsTable,
          callback: (payload) => _onLogEvent(payload, getLogs(), onNotify),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: WorkoutDatabaseService.routinesTable,
          callback: (payload) => _onRoutineEvent(payload, getRoutines(), onNotify),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: WorkoutDatabaseService.completionsTable,
          callback: (payload) => _onCompletionEvent(payload, getCompletions(), onNotify),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: WorkoutDatabaseService.challengesTable,
          callback: (payload) => _onChallengeEvent(payload, getChallenges(), onNotify),
        )
        .subscribe();
  }

  void _onLogEvent(
    PostgresChangePayload payload,
    List<WorkoutLog> logs,
    void Function() onNotify,
  ) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = _parseId(payload.oldRecord['id']);
        logs.removeWhere((l) => l.id == id);
      } else {
        final cloud = WorkoutLog.fromMap(payload.newRecord);
        final idx = logs.indexWhere((l) => l.id == cloud.id);
        if (idx == -1) {
          logs.insert(0, cloud);
        } else {
          logs[idx] = WorkoutSocialService.mergeLog(logs[idx], cloud);
        }
      }
      onNotify();
    } catch (e) {
      developer.log('WorkoutRealtimeHandler logs: $e');
    }
  }

  void _onRoutineEvent(
    PostgresChangePayload payload,
    List<WorkoutRoutine> routines,
    void Function() onNotify,
  ) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = _parseId(payload.oldRecord['id']);
        routines.removeWhere((r) => r.id == id);
      } else {
        final cloud = WorkoutRoutine.fromMap(payload.newRecord);
        final idx = routines.indexWhere((r) => r.id == cloud.id);
        if (idx == -1) {
          routines.add(cloud);
        } else {
          routines[idx] = WorkoutSocialService.mergeRoutine(routines[idx], cloud);
        }
      }
      onNotify();
    } catch (e) {
      developer.log('WorkoutRealtimeHandler routines: $e');
    }
  }

  void _onCompletionEvent(
    PostgresChangePayload payload,
    List<WorkoutCompletion> completions,
    void Function() onNotify,
  ) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = _parseId(payload.oldRecord['id']);
        completions.removeWhere((c) => c.id == id);
      } else {
        final cloud = WorkoutCompletion.fromMap(payload.newRecord);
        final idx = completions.indexWhere((c) => c.id == cloud.id);
        if (idx == -1) {
          completions.add(cloud);
        } else {
          completions[idx] = cloud;
        }
      }
      onNotify();
    } catch (e) {
      developer.log('WorkoutRealtimeHandler completions: $e');
    }
  }

  void _onChallengeEvent(
    PostgresChangePayload payload,
    List<WorkoutChallenge> challenges,
    void Function() onNotify,
  ) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = _parseId(payload.oldRecord['id']);
        challenges.removeWhere((c) => c.id == id);
      } else {
        final cloud = WorkoutChallenge.fromMap(payload.newRecord);
        final idx = challenges.indexWhere((c) => c.id == cloud.id);
        if (idx == -1) {
          challenges.insert(0, cloud);
        } else {
          challenges[idx] = WorkoutSocialService.mergeChallenge(challenges[idx], cloud);
        }
      }
      onNotify();
    } catch (e) {
      developer.log('WorkoutRealtimeHandler challenges: $e');
    }
  }

  void dispose() {
    _channel?.unsubscribe();
  }

  static int? _parseId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
