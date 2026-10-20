import '../../models/workout_challenge.dart';
import '../../models/workout_completion.dart';
import '../../models/workout_log.dart';
import '../../models/workout_routine.dart';
import '../../supabase_config.dart';

class WorkoutDatabaseService {
  static const logsTable = 'workout_logs';
  static const routinesTable = 'workout_routines';
  static const completionsTable = 'workout_completions';
  static const challengesTable = 'workout_challenges';

  static Future<List<WorkoutLog>> fetchLogs() async {
    final data = await SupabaseConfig.client
        .from(logsTable)
        .select()
        .order('logged_on', ascending: false)
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((r) => WorkoutLog.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> insertLog(WorkoutLog log) async {
    await SupabaseConfig.client
        .from(logsTable)
        .insert(log.toMap())
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> updateLog(WorkoutLog log) async {
    await SupabaseConfig.client
        .from(logsTable)
        .update(log.toMap())
        .eq('id', log.id!)
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> deleteLog(int id) async {
    await SupabaseConfig.client
        .from(logsTable)
        .delete()
        .eq('id', id)
        .timeout(const Duration(seconds: 10));
  }

  static Future<List<WorkoutRoutine>> fetchRoutines() async {
    final data = await SupabaseConfig.client
        .from(routinesTable)
        .select()
        .order('day_of_week', ascending: true)
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((r) => WorkoutRoutine.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> insertRoutine(WorkoutRoutine routine) async {
    await SupabaseConfig.client
        .from(routinesTable)
        .insert(routine.toMap())
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> updateRoutine(WorkoutRoutine routine) async {
    await SupabaseConfig.client
        .from(routinesTable)
        .update(routine.toMap())
        .eq('id', routine.id!)
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> deleteRoutine(int id) async {
    await SupabaseConfig.client
        .from(routinesTable)
        .delete()
        .eq('id', id)
        .timeout(const Duration(seconds: 10));
  }

  static Future<List<WorkoutCompletion>> fetchCompletions() async {
    final data = await SupabaseConfig.client
        .from(completionsTable)
        .select()
        .order('completed_on', ascending: false)
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((r) => WorkoutCompletion.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> upsertCompletion(WorkoutCompletion completion) async {
    await SupabaseConfig.client
        .from(completionsTable)
        .upsert(completion.toMap(), onConflict: 'user_id,completed_on,routine_id')
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> deleteCompletion(int id) async {
    await SupabaseConfig.client
        .from(completionsTable)
        .delete()
        .eq('id', id)
        .timeout(const Duration(seconds: 10));
  }

  static Future<List<WorkoutChallenge>> fetchChallenges() async {
    final data = await SupabaseConfig.client
        .from(challengesTable)
        .select()
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((r) => WorkoutChallenge.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  static Future<void> insertChallenge(WorkoutChallenge challenge) async {
    await SupabaseConfig.client
        .from(challengesTable)
        .insert(challenge.toMap())
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> updateChallenge(WorkoutChallenge challenge) async {
    await SupabaseConfig.client
        .from(challengesTable)
        .update(challenge.toMap())
        .eq('id', challenge.id!)
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> deleteChallenge(int id) async {
    await SupabaseConfig.client
        .from(challengesTable)
        .delete()
        .eq('id', id)
        .timeout(const Duration(seconds: 10));
  }
}
