import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/couple_achievement.dart';
import '../services/local_cache.dart';
import '../supabase_config.dart';
import 'helpers/achievement_snapshot_service.dart';

class CoupleAchievementsProvider extends ChangeNotifier {
  static const _table = 'couple_achievements';

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

  Set<String> get earnedCodes =>
      _earned.map((e) => e.code).whereType<String>().toSet();

  List<CoupleAchievement> get collected => _earned
      .map((e) => CoupleAchievements.byCode(e.code))
      .whereType<CoupleAchievement>()
      .toList();

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

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    final cached = await LocalCache.getList('cache_logros');
    if (cached.isNotEmpty) {
      _earned = cached.map((m) => EarnedAchievement.fromMap(m)).toList();
      _loading = false;
      notifyListeners();
    }
    try {
      await _loadEarned();
      await LocalCache.setList(
          'cache_logros', _earned.map((e) => e.toMap()).toList());
      final newCodes = await _computeAndAward();
      _loading = false;
      notifyListeners();
      _subscribeRealtime();
      if (newCodes.isNotEmpty) {
        developer.log('CoupleAchievements: otorgados $newCodes');
      }
    } catch (e) {
      _loading = false;
      if (_earned.isEmpty) _error = 'No se pudo cargar los logros';
      developer.log('CoupleAchievementsProvider.load error: $e');
      notifyListeners();
    }
  }

  Future<Set<String>> _computeAndAward() async {
    final snapshot = await AchievementSnapshotService.buildSnapshot(
      myId: myId,
      partnerId: partnerId,
    );
    final earnedNow = CoupleAchievements.earnedCodes(snapshot);
    final newCodes = earnedNow.difference(earnedCodes);
    for (final code in newCodes) {
      try {
        await SupabaseConfig.client
            .from(_table)
            .insert(EarnedAchievement(code: code).toMap())
            .timeout(const Duration(seconds: 10));
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
        .map((r) =>
            EarnedAchievement.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
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
