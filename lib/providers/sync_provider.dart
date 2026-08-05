import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../services/notification_service.dart';

/// Eventos de sincronización automática entre secciones
/// Cada vez que una acción en una sección debe reflejarse en otra.
enum SyncEventType {
  /// 1. Calendario -> Estudio: crear examen crea entrada en estudio
  examCreated,
  /// 2. Calendario -> Finanzas: crear pago crea transacción en finanzas
  paymentCreated,
  /// 3. Galería -> Nosotros: subir foto crea recuerdo en timeline
  photoUploaded,
  /// 4. Nosotros -> Calendario: fecha especial aparece en calendario
  specialDateCreated,
  /// 5. Finanzas -> Tareas: deuda pendiente aparece como tarea
  debtCreated,
  /// 6. Tareas -> Calendario: tarea con fecha aparece en calendario
  taskWithDate,
  /// 7. Estudio -> Calendario: examen creado en estudio aparece en calendario
  studyExamCreated,
  /// 8. Nosotros -> Calendario: estado de ánimo registrado
  moodRecorded,
  /// 9. Finanzas -> Nosotros: meta de ahorro cumplida
  savingsGoalMet,
  /// 10. Tareas -> Notificaciones: tarea vencida
  taskOverdue,
  /// 11. Estudio -> Registro: sesión de estudio completada
  studySessionCompleted,
  /// 12. Nosotros -> Notificaciones: cumpleaños/aniversario próximo
  upcomingSpecialDate,
}

class SyncEvent {
  final SyncEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  SyncEvent({required this.type, required this.data, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class SyncProvider extends ChangeNotifier {
  static SyncProvider? _instance;
  static SyncProvider? get instance => _instance;

  SyncProvider() { _instance = this; }

  final List<SyncEvent> _eventQueue = [];
  bool _processing = false;

  void emit(SyncEventType type, Map<String, dynamic> data) {
    _eventQueue.add(SyncEvent(type: type, data: data));
    notifyListeners();
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;
    while (_eventQueue.isNotEmpty) {
      final event = _eventQueue.removeAt(0);
      try {
        await _dispatch(event);
      } catch (e) {
        developer.log('SyncProvider error despachando ${event.type.name}: $e');
      }
    }
    _processing = false;
  }

  List<SyncEvent> get pendingEvents => List.unmodifiable(_eventQueue);

  // ---------------------------------------------------------------------------
  // DISPATCH: cada tipo de evento ejecuta la lógica cross-section
  // ---------------------------------------------------------------------------

  Future<void> _dispatch(SyncEvent event) async {
    switch (event.type) {
      // ------- 1. Calendario → Estudio --------
      case SyncEventType.examCreated:
        await _syncExamToStudy(event.data);
        break;

      // ------- 2. Calendario → Finanzas -------
      case SyncEventType.paymentCreated:
        await _syncPaymentToFinance(event.data);
        break;

      // ------- 3. Galería → Nosotros ----------
      case SyncEventType.photoUploaded:
        await _syncPhotoToTimeline(event.data);
        break;

      // ------- 4. Nosotros → Calendario -------
      case SyncEventType.specialDateCreated:
        await _syncDateToCalendar(event.data);
        break;

      // ------- 7. Estudio → Calendario --------
      case SyncEventType.studyExamCreated:
        await _syncExamToCalendar(event.data);
        break;

      // ------- 8. Nosotros → Calendario (mood) -
      case SyncEventType.moodRecorded:
        // El mood se muestra como evento sutil en calendario
        break;

      // ------- 9. Finanzas → Nosotros ---------
      case SyncEventType.savingsGoalMet:
        await _syncGoalToTimeline(event.data);
        break;

      // ------- 5. Finanzas -> Tareas -----------
      case SyncEventType.debtCreated:
        break;

      // ------- 6. Tareas -> Calendario --------
      case SyncEventType.taskWithDate:
        break;

      // ------- 10. Tareas -> Notificaciones ---
      case SyncEventType.taskOverdue:
        break;

      // ------- 11. Estudio → Registro ---------
      case SyncEventType.studySessionCompleted:
        break;

      // ------- 12. Nosotros → Notificaciones --
      case SyncEventType.upcomingSpecialDate:
        await _notifySpecialDate(event.data);
        break;
    }
  }

  // =============== IMPLEMENTACIONES ===============

  /// 1. Al crear un examen en Calendario → aparece en Estudio como entrada de estudio
  Future<void> _syncExamToStudy(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Examen';
    final date = data['date'] as String? ?? DateTime.now().toIso8601String();
    try {
      await SupabaseConfig.client.from('study_sessions').insert({
        'user_id': AppState.myId ?? '',
        'type': 'exam',
        'duration_seconds': 0,
        'notes': '📚 Examen: $title - $date',
        'created_at': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      developer.log('Sync: fallo al sincronizar examen a estudio: $e');
    }
  }

  /// 2. Al crear un pago en Calendario → aparece en Finanzas como transacción
  Future<void> _syncPaymentToFinance(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Pago';
    final amount = data['amount'] as num? ?? 0;
    try {
      await SupabaseConfig.client.from('transactions').insert({
        'user_id': AppState.myId,
        'type': 'expense',
        'category': 'other',
        'amount': amount.toDouble(),
        'description': '📅 $title',
        'date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      developer.log('Sync: fallo al sincronizar pago a finanzas: $e');
    }
  }

  /// 3. Al subir foto en Galería → aparece en Nosotros como evento de timeline
  Future<void> _syncPhotoToTimeline(Map<String, dynamic> data) async {
    final url = data['url'] as String? ?? '';
    final label = data['label'] as String? ?? '📸';
    try {
      await SupabaseConfig.client.from('timeline_events').insert({
        'user_id': AppState.myId,
        'type': 'photo',
        'emoji': '📸',
        'content': '$label $url',
        'created_at': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      developer.log('Sync: fallo al sincronizar foto a timeline: $e');
    }
  }

  /// 4. Al crear fecha especial en Nosotros → aparece en Calendario
  Future<void> _syncDateToCalendar(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Fecha especial';
    final dateStr = data['date'] as String? ?? DateTime.now().toIso8601String();
    try {
      await SupabaseConfig.client.from('schedules').insert({
        'title': '❤️ $title',
        'description': '',
        'date': dateStr,
        'startTime': '00:00',
        'endTime': '23:59',
        'location': '',
        'instructor': '',
        'type': 'Fecha especial',
        'color': 0xFFFF5757,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      developer.log('Sync: fallo al sincronizar fecha especial a calendario: $e');
    }
  }

  /// 7. Al crear examen en Estudio → aparece en Calendario
  Future<void> _syncExamToCalendar(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Examen';
    final date = data['date'] as String? ?? DateTime.now().toIso8601String();
    try {
      await SupabaseConfig.client.from('schedules').insert({
        'title': '📚 $title',
        'description': '',
        'date': date,
        'startTime': '08:00',
        'endTime': '10:00',
        'location': '',
        'instructor': '',
        'type': 'Examen',
        'color': 0xFFE53935,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      developer.log('Sync: fallo al sincronizar examen a calendario: $e');
    }
  }

  /// 9. Meta de ahorro cumplida → timeline en Nosotros
  Future<void> _syncGoalToTimeline(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Meta cumplida';
    try {
      await SupabaseConfig.client.from('timeline_events').insert({
        'user_id': AppState.myId,
        'type': 'achievement',
        'emoji': '🎯',
        'content': '🎉 $title',
        'created_at': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      developer.log('Sync: fallo al sincronizar meta a timeline: $e');
    }
  }

  /// 12. Fecha especial próxima → notificación
  Future<void> _notifySpecialDate(Map<String, dynamic> data) async {
    final title = data['title'] as String? ?? 'Fecha especial';
    final daysLeft = data['days_left'] ?? 0;
    await NotificationService.showNotification(
      title: '❤️ $title',
      body: daysLeft == 0 ? '¡Hoy!' : 'En $daysLeft día(s)',
    );
    await NotificationService.storeNotification(
      type: 'special_date',
      title: title,
      body: daysLeft == 0 ? '¡Hoy!' : 'En $daysLeft día(s)',
    );
  }
}
