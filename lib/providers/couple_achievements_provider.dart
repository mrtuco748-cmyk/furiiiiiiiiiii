import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/couple_achievement.dart';
import '../models/couple_stats.dart';
import '../models/deck_card.dart';
import '../supabase_config.dart';

/// Colección de logros de pareja: carga los ya otorgados desde Supabase,
/// calcula el estado actual de la pareja, y otorga los nuevos. Sin cache local.
class CoupleAchievementsProvider extends ChangeNotifier {
  static const _table = 'couple_achievements';
  static const _moodsTable = 'moods';
  static const _completionsTable = 'workout_completions';
  static const _messagesTable = 'messages';
  static const _deckTable = 'deck_cards';
  static const _locationsTable = 'couple_locations';
  static const _rewardsTable = 'couple_rewards';
  static const _triviaTable = 'question_answers';

  List<EarnedAchievement> _earned = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<EarnedAchievement> get earned => List.unmodifiable(_earned);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  String get myId => AppState.myId ?? '';
  String get partnerId => AppState.partnerId ?? '';

  /// Códigos de logros ya otorgados en la nube.
  Set<String> get earnedCodes =>
      _earned.map((e) => e.code).whereType<String>().toSet();

  /// Los logros ya desbloqueados (con su definición).
  List<CoupleAchievement> get collected =>
      _earned.map((e) => CoupleAchievements.byCode(e.code))
          .whereType<CoupleAchievement>().toList();

  /// Los logros que aún no se desbloquearon.
  List<CoupleAchievement> get remaining {
    final earnedSet = earnedCodes;
    return CoupleAchievements.all
        .where((a) => !earnedSet.contains(a.code))
        .toList();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── CARGA + EVALUACIÓN ───────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _loadEarned();
      final newCodes = await _computeAndAward();
      _loading = false;
      notifyListeners();
      _subscribeRealtime();
      if (newCodes.isNotEmpty) {
        developer.log('CoupleAchievements: otorgados $newCodes');
      }
    } catch (e) {
      _loading = false;
      _error = 'No se pudo cargar los logros';
      developer.log('CoupleAchievementsProvider.load error: $e');
      notifyListeners();
    }
  }

  /// Recalcula el snapshot de la pareja y devuelve los códigos nuevos que
  /// se acaban de otorgar (para feedback de UI).
  Future<Set<String>> _computeAndAward() async {
    final snapshot = await _buildSnapshot();
    final earnedNow = CoupleAchievements.earnedCodes(snapshot);
    final newCodes = earnedNow.difference(earnedCodes);
    for (final code in newCodes) {
      try {
        await SupabaseConfig.client
            .from(_table)
            .insert(EarnedAchievement(code: code).toMap())
            .timeout(const Duration(seconds: 10));
        // Solo marcar como otorgado localmente si la nube lo persiste (así, en
        // un insert fallido por UNIQUE/red el álbum no muestra un desbloqueo
        // que no existe en la nube).
        _earned.add(EarnedAchievement(code: code));
      } catch (e) {
        developer.log('CoupleAchievements insert $code error: $e');
      }
    }
    return newCodes;
  }

  Future<void> _loadEarned() async {
    final data = await SupabaseConfig.client
        .from(_table)
        .select()
        .order('awarded_at', ascending: false)
        .timeout(const Duration(seconds: 10));
    _earned = (data as List)
        .map((r) => EarnedAchievement.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<AchievementSnapshot> _buildSnapshot() async {
    // Cada tabla tiene su propia columna de fecha (moods→date,
    // workout_completions→completed_on); usar un select genérico pedía columnas
    // inexistentes (PGRST204) y tiraba TODO el cálculo de logros.
    final moods = await _loadUserIds(_moodsTable, dateColumn: 'date');
    final completions =
        await _loadUserIds(_completionsTable, dateColumn: 'completed_on');
    final hasDeckMatch = await _hasDeckMatch();
    final totalMessages = await _countMessages();
    final bothSharedLocation = await _bothSharedLocation();
    final hasFulfilledReward = await _hasFulfilledReward();
    final bothAnsweredTrivia = await _bothAnsweredTrivia();

    final activities = <CoupleActivity>[
      ...moods,
      ...completions,
    ];
    final activeByDay = CoupleStats.activeByDay(activities);
    final bothDays = CoupleStats.bothActiveDays(
        activeByDay, members: {myId, partnerId});
    // Racha de ánimo: solo días donde AMBOS registraron mood.
    final moodBothDays = CoupleStats.bothActiveDays(
        CoupleStats.activeByDay(moods), members: {myId, partnerId});

    return AchievementSnapshot(
      coupleStreak: CoupleStats.streakFor(bothDays),
      bestCoupleStreak: CoupleStats.bestStreak(bothDays),
      bothLoggedMood: _hasBoth(moods),
      bothWorkedOut: _hasBoth(completions),
      hasDeckMatch: hasDeckMatch,
      totalMessages: totalMessages,
      moodCoupleStreak: CoupleStats.streakFor(moodBothDays),
      totalWorkouts: completions.length,
      bothSharedLocation: bothSharedLocation,
      hasFulfilledReward: hasFulfilledReward,
      bothAnsweredTrivia: bothAnsweredTrivia,
    );
  }

  Future<List<CoupleActivity>> _loadUserIds(
    String table, {required String dateColumn}) async {
    final data = await SupabaseConfig.client
        .from(table)
        .select('user_id, $dateColumn')
        .timeout(const Duration(seconds: 10));
    return (data as List).map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      return CoupleActivity.fromMap({
        'user_id': m['user_id'],
        'date': m[dateColumn],
      });
    }).where((a) => a.userId.isNotEmpty).toList();
  }

  bool _hasBoth(List<CoupleActivity> acts) {
    final users = acts.map((a) => a.userId).toSet();
    return users.contains(myId) && users.contains(partnerId);
  }

  Future<bool> _hasDeckMatch() async {
    try {
      final data = await SupabaseConfig.client
          .from(_deckTable)
          .select('reactions')
          .timeout(const Duration(seconds: 10));
      for (final r in data as List) {
        final map = Map<String, dynamic>.from(r as Map);
        final reactions = <String, String>{};
        final raw = map['reactions'];
        if (raw is Map) {
          raw.forEach((k, v) {
            if (k is String && v is String) reactions[k] = v;
          });
        }
        if (reactions.length >= 2 &&
            reactions.values.every((v) => v == DeckReaction.encanta)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      developer.log('CoupleAchievements._hasDeckMatch error: $e');
      return false;
    }
  }

  Future<int> _countMessages() async {
    try {
      return await SupabaseConfig.client
          .from(_messagesTable)
          .count()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      developer.log('CoupleAchievements._countMessages error: $e');
      return 0;
    }
  }

  Future<bool> _bothSharedLocation() async {
    try {
      final data = await SupabaseConfig.client
          .from(_locationsTable)
          .select('user_id')
          .timeout(const Duration(seconds: 10));
      final users = (data as List)
          .map((r) => (r as Map)['user_id']?.toString() ?? '')
          .where((u) => u.isNotEmpty)
          .toSet();
      return users.contains(myId) && users.contains(partnerId);
    } catch (e) {
      developer.log('CoupleAchievements._bothSharedLocation error: $e');
      return false;
    }
  }

  Future<bool> _hasFulfilledReward() async {
    try {
      final data = await SupabaseConfig.client
          .from(_rewardsTable)
          .select('fulfilled')
          .eq('fulfilled', true)
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasFulfilledReward error: $e');
      return false;
    }
  }

  Future<bool> _bothAnsweredTrivia() async {
    try {
      final data = await SupabaseConfig.client
          .from(_triviaTable)
          .select('user_id, date')
          .timeout(const Duration(seconds: 10));
      final byDate = <String, Set<String>>{};
      for (final r in data as List) {
        final m = Map<String, dynamic>.from(r as Map);
        final uid = m['user_id']?.toString() ?? '';
        final date = m['date']?.toString() ?? '';
        if (uid.isEmpty || date.isEmpty) continue;
        byDate.putIfAbsent(date, () => <String>{}).add(uid);
      }
      return byDate.values.any((users) =>
          users.contains(myId) && users.contains(partnerId));
    } catch (e) {
      developer.log('CoupleAchievements._bothAnsweredTrivia error: $e');
      return false;
    }
  }

  // ─── REALTIME ─────────────────────────────────────────────────

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('couple_achievements_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          callback: (_) => _loadEarned().then((_) {
            if (hasListeners) notifyListeners();
          }),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}