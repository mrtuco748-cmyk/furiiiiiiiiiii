import '../models/schedule.dart';
import 'notification_service.dart';

/// Recordatorio programado de un evento (fecha fija).
class EventNotificationSpec {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;

  const EventNotificationSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
  });
}

/// Programa recordatorios locales de los eventos del calendario:
/// - 1 hora antes
/// - al momento de empezar
///
/// Los ids de notificación usan el id local de SQLite (estable por
/// dispositivo) con el namespace [100000, 200000): `100000 + id` (1h antes)
/// y `100000 + id + 1` (al empezar). Las clases usan el namespace >= 200000.
class EventNotificationService {
  static final EventNotificationService _instance =
      EventNotificationService._();
  factory EventNotificationService() => _instance;
  EventNotificationService._();

  final Set<int> _scheduledIds = {};

  /// Lógica pura: recordatorios de un evento (testeable sin plugin).
  static List<EventNotificationSpec> specsForEvent(Schedule s, DateTime now) {
    if (s.id == null) return const [];
    final parts = s.startTime.split(':');
    if (parts.length != 2) return const [];
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return const [];

    final eventDate = DateTime(s.date.year, s.date.month, s.date.day);
    final eventTime = eventDate.add(Duration(hours: hour, minutes: minute));
    final oneHourBefore = eventTime.subtract(const Duration(hours: 1));

    final specs = <EventNotificationSpec>[];
    if (oneHourBefore.isAfter(now)) {
      specs.add(EventNotificationSpec(
        id: 100000 + s.id!,
        title: s.title,
        body: 'El evento empieza en 1 hora',
        scheduledDate: oneHourBefore,
      ));
    }
    if (eventTime.isAfter(now)) {
      specs.add(EventNotificationSpec(
        id: 100000 + s.id! + 1,
        title: s.title,
        body: 'El evento empieza ahora',
        scheduledDate: eventTime,
      ));
    }
    return specs;
  }

  Future<void> cancelForEvent(int eventId) async {
    await NotificationService.cancel(100000 + eventId);
    await NotificationService.cancel(100000 + eventId + 1);
  }

  /// Cancela los recordatorios vigentes y reprograma todos los eventos.
  Future<void> rescheduleAll(List<Schedule> schedules) async {
    for (final id in _scheduledIds) {
      await NotificationService.cancel(id);
    }
    _scheduledIds.clear();

    final now = DateTime.now();
    for (final s in schedules) {
      for (final spec in specsForEvent(s, now)) {
        _scheduledIds.add(spec.id);
        await NotificationService.scheduleNotification(
          id: spec.id,
          title: spec.title,
          body: spec.body,
          scheduledDate: spec.scheduledDate,
        );
      }
    }
  }
}
