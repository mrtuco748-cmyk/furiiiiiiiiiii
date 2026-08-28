import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/couple_location.dart';
import '../supabase_config.dart';

/// Ubicaciones de la pareja y distancia en tiempo real. Sin cache local (como
/// finanzas/workouts): las últimas ubicaciones viven en Supabase `couple_locations`
/// (PK user_id) y se sincronizan por realtime.
class LocationProvider extends ChangeNotifier {
  static const _table = 'couple_locations';

  List<CoupleLocation> _locations = [];
  Map<String, CoupleLocation> _byUser = {};
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;

  List<CoupleLocation> get locations => List.unmodifiable(_locations);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  String get myId => AppState.myId ?? '';
  String? get partnerId => AppState.partnerId;

  CoupleLocation? get myLocation => of(myId);
  CoupleLocation? get partnerLocation => of(partnerId ?? '');

  /// Distancia actual (km) entre la pareja; 0 si falta alguna ubicación.
  double get coupleDistanceKm {
    final me = myLocation;
    final partner = partnerLocation;
    if (me == null || partner == null) return 0;
    return distanceKm(me.lat, me.lng, partner.lat, partner.lng);
  }

  CoupleLocation? of(String userId) => _byUser[userId];

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .timeout(const Duration(seconds: 10));
      _apply((data as List)
          .map((r) => CoupleLocation.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList());
    } catch (e) {
      _error = 'No se pudieron cargar las ubicaciones';
      developer.log('LocationProvider.load error: $e');
    }
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  /// Actualiza la última ubicación del usuario activo (upsert por user_id).
  Future<bool> updateMyLocation(double lat, double lng) async {
    if (myId.isEmpty) return false;
    _error = null;
    try {
      await SupabaseConfig.client.from(_table).upsert({
        'user_id': myId,
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
      _upsertLocal(CoupleLocation(userId: myId, lat: lat, lng: lng, updatedAt: DateTime.now()));
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'No se pudo compartir tu ubicación';
      developer.log('LocationProvider.updateMyLocation error: $e');
      notifyListeners();
      return false;
    }
  }

  void _upsertLocal(CoupleLocation l) {
    _locations = [
      for (final x in _locations)
        if (x.userId != l.userId) x,
      l,
    ];
    _rebuildIndex();
  }

  void _apply(List<CoupleLocation> list) {
    _locations = list;
    _rebuildIndex();
  }

  void _rebuildIndex() {
    _byUser = {for (final l in _locations) l.userId: l};
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('couple_locations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: _table,
          callback: (_) => _reload(),
        )
        .subscribe();
  }

  Future<void> _reload() async {
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .timeout(const Duration(seconds: 10));
      _apply((data as List)
          .map((r) => CoupleLocation.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList());
      notifyListeners();
    } catch (e) {
      developer.log('LocationProvider._reload error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}