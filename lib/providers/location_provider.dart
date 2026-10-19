import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../models/couple_location.dart';
import '../supabase_config.dart';
import '../services/local_cache.dart';

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
  bool _realtimeUp = false;

  List<CoupleLocation> get locations => List.unmodifiable(_locations);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;

  static const facuId = '8ab030df-9b7b-4dc4-8981-8ef30dfdc203';
  static const rocioId = '7be86414-1630-41c0-b35a-70392c2f4f11';

  String get myId {
    final cur = AppState.myId;
    if (cur != null && cur.isNotEmpty) return cur;
    if (AppState.identity == 'Rocio') return rocioId;
    return facuId;
  }

  String get partnerId {
    final cur = AppState.partnerId;
    if (cur != null && cur.isNotEmpty) return cur;
    if (AppState.identity == 'Rocio') return facuId;
    return rocioId;
  }

  CoupleLocation? get myLocation => of(myId);
  CoupleLocation? get partnerLocation => of(partnerId);

  /// Ubicación efectiva mía (usando última conocida en base de datos o fallback confiable).
  CoupleLocation get effectiveMyLocation =>
      myLocation ??
      CoupleLocation(
        userId: myId,
        lat: myId == rocioId ? -27.3671 : -27.510067,
        lng: myId == rocioId ? -55.8961 : -56.741267,
        updatedAt: DateTime.now(),
      );

  /// Ubicación efectiva de la pareja (usando última conocida en base de datos o fallback confiable).
  CoupleLocation get effectivePartnerLocation =>
      partnerLocation ??
      CoupleLocation(
        userId: partnerId,
        lat: partnerId == rocioId ? -27.3671 : -27.510067,
        lng: partnerId == rocioId ? -55.8961 : -56.741267,
        updatedAt: DateTime.now(),
      );

  /// Distancia real en kilómetros entre la pareja según sus ubicaciones actuales.
  double get coupleDistanceKm {
    final me = effectiveMyLocation;
    final partner = effectivePartnerLocation;
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
    // Cache local (offline-first): mostramos lo último conocido de inmediato.
    final cached = await LocalCache.getList('cache_locations');
    if (cached.isNotEmpty) {
      _apply(cached.map((m) => CoupleLocation.fromMap(m)).toList());
      _loading = false;
      notifyListeners();
    }
    try {
      final data = await SupabaseConfig.client
          .from(_table)
          .select()
          .timeout(const Duration(seconds: 10));
      _apply((data as List)
          .map((r) => CoupleLocation.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList());
      await LocalCache.setList(
          'cache_locations', _locations.map((l) => l.toMap()).toList());
    } catch (e) {
      if (_locations.isEmpty) {
        _error = 'No se pudieron cargar las ubicaciones';
      }
      developer.log('LocationProvider.load error: $e');
    }
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  /// Inicializa la ubicación automáticamente en segundo plano al abrir la app.
  /// Si el servicio de ubicación o los permisos están activos, obtiene
  /// de inmediato la última posición conocida y luego la refina con GPS.
  Future<void> initAutoLocation() async {
    await load();
    if (kIsWeb) return;
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      // 1. Obtener última posición conocida de inmediato (cero latencia)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await updateMyLocation(lastKnown.latitude, lastKnown.longitude);
      }

      // 2. Refinar con la posición actual (máximo 8s para no colgar)
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      await updateMyLocation(current.latitude, current.longitude);
    } catch (e) {
      developer.log('LocationProvider.initAutoLocation error: $e');
    }
  }

  /// Actualiza la última ubicación del usuario activo (upsert por user_id).
  Future<bool> updateMyLocation(double lat, double lng) async {
    if (AppState.myId == null || AppState.myId!.isEmpty) {
      AppState.myId = myId;
      AppState.partnerId = partnerId;
      AppState.saveSession();
    }
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
      await LocalCache.setList(
          'cache_locations', _locations.map((l) => l.toMap()).toList());
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
    if (_realtimeUp) return;
    _realtimeUp = true;
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