import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/couple_achievement.dart';
import '../models/couple_stats.dart';
import '../models/deck_card.dart';
import '../supabase_config.dart';
import '../services/local_cache.dart';

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

  Set<String> get earnedCodes =>
      _earned.map((e) => e.code).whereType<String>().toSet();

  List<CoupleAchievement> get collected =>
      _earned.map((e) => CoupleAchievements.byCode(e.code))
          .whereType<CoupleAchievement>().toList();

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
    final snapshot = await _buildSnapshot();
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
        .map((r) => EarnedAchievement.fromMap(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<AchievementSnapshot> _buildSnapshot() async {
    final moods = await _loadUserIds(_moodsTable, dateColumn: 'date');
    final completions =
        await _loadUserIds(_completionsTable, dateColumn: 'completed_on');
    final hasDeckMatch = await _hasDeckMatch();
    final totalMessages = await _countMessages();
    final bothSharedLocation = await _bothSharedLocation();
    final hasFulfilledReward = await _hasFulfilledReward();
    final bothAnsweredTrivia = await _bothAnsweredTrivia();
    final totalLetters = await _countLetters();
    final totalChallengesCompleted = await _countChallengesCompleted();
    final totalGoalsCompleted = await _countGoalsCompleted();
    final totalGalleryItems = await _countGalleryItems();
    final totalFavorites = await _countFavorites();
    final totalTriviaAnswers = await _countTriviaAnswers();
    final totalRewardsFulfilled = await _countRewardsFulfilled();
    final totalCouplePoints = await _countCouplePoints();
    final matchCount = await _countMatches();
    final distanceKm = await _maxDistanceKm();
    final hasCompletedChallenge = await _hasCompletedChallenge();
    final hasCompletedGoal = await _hasCompletedGoal();
    final hasSentLetter = await _hasSentLetter();
    final hasGalleryPhoto = await _hasGalleryPhoto();

    final activities = <CoupleActivity>[
      ...moods,
      ...completions,
    ];
    final activeByDay = CoupleStats.activeByDay(activities);
    final bothDays = CoupleStats.bothActiveDays(
        activeByDay, members: {myId, partnerId});
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
      totalLetters: totalLetters,
      totalChallengesCompleted: totalChallengesCompleted,
      totalGoalsCompleted: totalGoalsCompleted,
      totalGalleryItems: totalGalleryItems,
      totalFavorites: totalFavorites,
      totalTriviaAnswers: totalTriviaAnswers,
      totalRewardsFulfilled: totalRewardsFulfilled,
      totalCouplePoints: totalCouplePoints,
      matchCount: matchCount,
      distanceKm: distanceKm,
      hasCompletedChallenge: hasCompletedChallenge,
      hasCompletedGoal: hasCompletedGoal,
      hasSentLetter: hasSentLetter,
      hasGalleryPhoto: hasGalleryPhoto,
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

  // ═══════════ NUEVAS CONSULTAS PARA LOGROS AMPLIADOS ═══════════

  Future<int> _countLetters() async {
    try {
      final data = await SupabaseConfig.client
          .from('letters')
          .select('id')
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countLetters error: $e');
      return 0;
    }
  }

  Future<int> _countChallengesCompleted() async {
    try {
      final data = await SupabaseConfig.client
          .from('challenges')
          .select('id')
          .eq('completed', true)
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countChallengesCompleted error: $e');
      return 0;
    }
  }

  Future<int> _countGoalsCompleted() async {
    try {
      final data = await SupabaseConfig.client
          .from('goals')
          .select('id')
          .eq('completed', true)
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countGoalsCompleted error: $e');
      return 0;
    }
  }

  Future<int> _countGalleryItems() async {
    try {
      final data = await SupabaseConfig.client
          .from('gallery')
          .select('id')
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countGalleryItems error: $e');
      return 0;
    }
  }

  Future<int> _countFavorites() async {
    try {
      final data = await SupabaseConfig.client
          .from('favorites')
          .select('id')
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countFavorites error: $e');
      return 0;
    }
  }

  Future<int> _countTriviaAnswers() async {
    try {
      final data = await SupabaseConfig.client
          .from(_triviaTable)
          .select('id')
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countTriviaAnswers error: $e');
      return 0;
    }
  }

  Future<int> _countRewardsFulfilled() async {
    try {
      final data = await SupabaseConfig.client
          .from(_rewardsTable)
          .select('id')
          .eq('fulfilled', true)
          .timeout(const Duration(seconds: 10));
      return (data as List).length;
    } catch (e) {
      developer.log('CoupleAchievements._countRewardsFulfilled error: $e');
      return 0;
    }
  }

  Future<int> _countCouplePoints() async {
    try {
      final data = await SupabaseConfig.client
          .from('couple_points')
          .select('delta')
          .timeout(const Duration(seconds: 10));
      int total = 0;
      for (final r in data as List) {
        total += ((r as Map)['delta'] as num?)?.toInt() ?? 0;
      }
      return total;
    } catch (e) {
      developer.log('CoupleAchievements._countCouplePoints error: $e');
      return 0;
    }
  }

  Future<int> _countMatches() async {
    try {
      final data = await SupabaseConfig.client
          .from(_deckTable)
          .select('reactions')
          .timeout(const Duration(seconds: 10));
      int count = 0;
      for (final r in data as List) {
        final raw = (r as Map)['reactions'];
        if (raw is Map) {
          final values = raw.values.toList();
          if (values.length >= 2 &&
              values.every((v) => v == DeckReaction.encanta)) {
            count++;
          }
        }
      }
      return count;
    } catch (e) {
      developer.log('CoupleAchievements._countMatches error: $e');
      return 0;
    }
  }

  Future<double> _maxDistanceKm() async {
    try {
      final data = await SupabaseConfig.client
          .from(_locationsTable)
          .select('lat, lng')
          .timeout(const Duration(seconds: 10));
      if ((data as List).isEmpty) return 0.0;
      final locations = <List<double>>[];
      for (final r in data) {
        final m = Map<String, dynamic>.from(r as Map);
        locations.add([
          (m['lat'] as num?)?.toDouble() ?? 0.0,
          (m['lng'] as num?)?.toDouble() ?? 0.0,
        ]);
      }
      double maxDist = 0.0;
      for (var i = 0; i < locations.length; i++) {
        for (var j = i + 1; j < locations.length; j++) {
          final d = _haversine(
            locations[i][0], locations[i][1],
            locations[j][0], locations[j][1],
          );
          if (d > maxDist) maxDist = d;
        }
      }
      return maxDist;
    } catch (e) {
      developer.log('CoupleAchievements._maxDistanceKm error: $e');
      return 0.0;
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) *
            math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180);
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }

  Future<bool> _hasCompletedChallenge() async {
    try {
      final data = await SupabaseConfig.client
          .from('challenges')
          .select('id')
          .eq('completed', true)
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasCompletedChallenge error: $e');
      return false;
    }
  }

  Future<bool> _hasCompletedGoal() async {
    try {
      final data = await SupabaseConfig.client
          .from('goals')
          .select('id')
          .eq('completed', true)
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasCompletedGoal error: $e');
      return false;
    }
  }

  Future<bool> _hasSentLetter() async {
    try {
      final data = await SupabaseConfig.client
          .from('letters')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasSentLetter error: $e');
      return false;
    }
  }

  Future<bool> _hasGalleryPhoto() async {
    try {
      final data = await SupabaseConfig.client
          .from('gallery')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 10));
      return (data as List).isNotEmpty;
    } catch (e) {
      developer.log('CoupleAchievements._hasGalleryPhoto error: $e');
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
