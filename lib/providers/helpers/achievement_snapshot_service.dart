import 'dart:developer' as developer;
import 'dart:math' as math;

import '../../models/achievement_snapshot.dart';
import '../../models/couple_stats.dart';
import '../../models/deck_card.dart';
import '../../supabase_config.dart';
import 'achievement_feature_counts.dart';

/// Servicio encargado de recolectar métricas en paralelo y construir el [AchievementSnapshot].
class AchievementSnapshotService {
  static const _moodsTable = 'moods';
  static const _completionsTable = 'workout_completions';
  static const _messagesTable = 'messages';
  static const _deckTable = 'deck_cards';
  static const _locationsTable = 'couple_locations';
  static const _rewardsTable = 'couple_rewards';
  static const _triviaTable = 'question_answers';

  static Future<AchievementSnapshot> buildSnapshot({
    required String myId,
    required String partnerId,
  }) async {
    final r = await Future.wait<Object?>([
      _loadUserIds(_moodsTable, dateColumn: 'date'),
      _loadUserIds(_completionsTable, dateColumn: 'completed_on'),
      _hasDeckMatch(),
      _countMessages(),
      _bothSharedLocation(myId, partnerId),
      _hasFulfilledReward(),
      _bothAnsweredTrivia(myId, partnerId),
      AchievementFeatureCounts.countLetters(),
      AchievementFeatureCounts.countChallengesCompleted(),
      AchievementFeatureCounts.countGoalsCompleted(),
      AchievementFeatureCounts.countGalleryItems(),
      AchievementFeatureCounts.countFavorites(),
      AchievementFeatureCounts.countTriviaAnswers(),
      AchievementFeatureCounts.countRewardsFulfilled(),
      AchievementFeatureCounts.countCouplePoints(),
      AchievementFeatureCounts.countMatches(),
      _maxDistanceKm(),
      AchievementFeatureCounts.hasCompletedChallenge(),
      AchievementFeatureCounts.hasCompletedGoal(),
      AchievementFeatureCounts.hasSentLetter(),
      AchievementFeatureCounts.hasGalleryPhoto(),
    ]);

    final moods = r[0] as List<CoupleActivity>;
    final completions = r[1] as List<CoupleActivity>;
    final hasDeckMatch = r[2] as bool;
    final totalMessages = r[3] as int;
    final bothSharedLocation = r[4] as bool;
    final hasFulfilledReward = r[5] as bool;
    final bothAnsweredTrivia = r[6] as bool;
    final totalLetters = r[7] as int;
    final totalChallengesCompleted = r[8] as int;
    final totalGoalsCompleted = r[9] as int;
    final totalGalleryItems = r[10] as int;
    final totalFavorites = r[11] as int;
    final totalTriviaAnswers = r[12] as int;
    final totalRewardsFulfilled = r[13] as int;
    final totalCouplePoints = r[14] as int;
    final matchCount = r[15] as int;
    final distanceKm = r[16] as double;
    final hasCompletedChallenge = r[17] as bool;
    final hasCompletedGoal = r[18] as bool;
    final hasSentLetter = r[19] as bool;
    final hasGalleryPhoto = r[20] as bool;

    final activities = <CoupleActivity>[
      ...moods,
      ...completions,
    ];
    final activeByDay = CoupleStats.activeByDay(activities);
    final bothDays =
        CoupleStats.bothActiveDays(activeByDay, members: {myId, partnerId});
    final moodBothDays = CoupleStats.bothActiveDays(
        CoupleStats.activeByDay(moods),
        members: {myId, partnerId});

    return AchievementSnapshot(
      coupleStreak: CoupleStats.streakFor(bothDays),
      bestCoupleStreak: CoupleStats.bestStreak(bothDays),
      bothLoggedMood: _hasBoth(moods, myId, partnerId),
      bothWorkedOut: _hasBoth(completions, myId, partnerId),
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

  static Future<List<CoupleActivity>> _loadUserIds(
    String table, {
    required String dateColumn,
  }) async {
    final data = await SupabaseConfig.client
        .from(table)
        .select('user_id, $dateColumn')
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((r) {
          final m = Map<String, dynamic>.from(r as Map);
          return CoupleActivity.fromMap({
            'user_id': m['user_id'],
            'date': m[dateColumn],
          });
        })
        .where((a) => a.userId.isNotEmpty)
        .toList();
  }

  static bool _hasBoth(
      List<CoupleActivity> acts, String myId, String partnerId) {
    final users = acts.map((a) => a.userId).toSet();
    return users.contains(myId) && users.contains(partnerId);
  }

  static Future<bool> _hasDeckMatch() async {
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

  static Future<int> _countMessages() async {
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

  static Future<bool> _bothSharedLocation(
      String myId, String partnerId) async {
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

  static Future<bool> _hasFulfilledReward() async {
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

  static Future<bool> _bothAnsweredTrivia(
      String myId, String partnerId) async {
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
      return byDate.values.any(
          (users) => users.contains(myId) && users.contains(partnerId));
    } catch (e) {
      developer.log('CoupleAchievements._bothAnsweredTrivia error: $e');
      return false;
    }
  }

  static Future<double> _maxDistanceKm() async {
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
            locations[i][0],
            locations[i][1],
            locations[j][0],
            locations[j][1],
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

  static double _haversine(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) *
            math.sin(dLon / 2) *
            math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180);
    final c = 2 * math.asin(math.sqrt(a));
    return r * c;
  }
}
