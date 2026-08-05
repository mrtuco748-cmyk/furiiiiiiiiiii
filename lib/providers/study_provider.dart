import 'dart:async';
import 'package:flutter/foundation.dart';
import '../supabase_config.dart';
import '../app_state.dart';

class StudySession {
  final int? id;
  final String userId;
  final String type;
  final int durationSeconds;
  final String? notes;
  final DateTime createdAt;

  StudySession({this.id, required this.userId, required this.type, required this.durationSeconds, this.notes, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'user_id': userId, 'type': type, 'duration_seconds': durationSeconds,
    'notes': notes, 'created_at': createdAt.toIso8601String(),
  };

  factory StudySession.fromMap(Map<String, dynamic> m) => StudySession(
    id: m['id'] as int?, userId: m['user_id'] as String? ?? '',
    type: m['type'] as String? ?? 'prog', durationSeconds: m['duration_seconds'] as int? ?? 0,
    notes: m['notes'] as String?, createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
  );
}

class StudyProvider extends ChangeNotifier {
  List<StudySession> _sessions = [];
  bool _loading = false;
  int _todaySeconds = 0;
  int _streak = 0;
  String? _error;

  List<StudySession> get sessions => _sessions;
  bool get loading => _loading;
  int get todaySeconds => _todaySeconds;
  int get streak => _streak;
  String? get error => _error;
  bool get hasError => _error != null;

  void clearError() { _error = null; notifyListeners(); }

  Future<void> load() async {
    _loading = true; _error = null; notifyListeners();
    try {
      final res = await SupabaseConfig.client
          .from('study_sessions')
          .select()
          .eq('user_id', AppState.myId ?? '')
          .order('created_at', ascending: false)
          .limit(50)
          .timeout(const Duration(seconds: 10));
      _sessions = (res as List).map((e) => StudySession.fromMap(e as Map<String, dynamic>)).toList();
      final today = DateTime.now();
      _todaySeconds = _sessions.where((s) =>
        s.createdAt.year == today.year && s.createdAt.month == today.month && s.createdAt.day == today.day
      ).fold(0, (sum, s) => sum + s.durationSeconds);
      _streak = _calcStreak();
      _error = null;
    } catch (e) {
      _sessions = [];
      _todaySeconds = 0;
      _streak = 0;
      _error = 'No se pudieron cargar las sesiones de estudio';
      debugPrint('StudyProvider.load error: $e');
    }
    _loading = false; notifyListeners();
  }

  int _calcStreak() {
    if (_sessions.isEmpty) return 0;
    int streak = 0;
    final dates = _sessions.map((s) => DateTime(s.createdAt.year, s.createdAt.month, s.createdAt.day)).toSet().toList()..sort((a, b) => b.compareTo(a));
    final today = DateTime.now();
    var check = DateTime(today.year, today.month, today.day);
    for (final d in dates) {
      if (d == check) { streak++; check = check.subtract(const Duration(days: 1)); }
      else break;
    }
    return streak;
  }

  Future<void> addSession(int seconds, String type, {String? notes}) async {
    final s = StudySession(userId: AppState.myId ?? '', type: type, durationSeconds: seconds, notes: notes);
    _error = null;
    try {
      await SupabaseConfig.client.from('study_sessions').insert(s.toMap()).timeout(const Duration(seconds: 10));
    } catch (e) {
      _error = 'No se pudo guardar la sesión de estudio';
      debugPrint('StudyProvider.addSession error: $e');
      notifyListeners();
      return;
    }
    await load();
  }
}
