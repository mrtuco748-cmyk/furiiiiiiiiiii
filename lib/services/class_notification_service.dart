import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/class_schedule.dart';
import 'notification_service.dart';

/// Recordatorio programado de una clase recurrente.
class ClassNotificationSpec {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final DateTimeComponents matchDateTimeComponents;

  const ClassNotificationSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.matchDateTimeComponents,
  });
}

/// Programa recordatorios locales de las clases recurrentes:
/// 1 hora antes, con repeticion semanal (día de la semana + hora).
///
/// Ids con el namespace [200000, 300000): `200000 + id` (id local de
/// SQLite). Los eventos fechados usan el namespace < 200000, así no
/// colisionan.
class ClassNotificationService {
  static final ClassNotificationService _instance =
      ClassNotificationService._();
  factory ClassNotificationService() => _instance;
  ClassNotificationService._();

  final Set<int> _scheduledIds = {};

  /// Lógica pura: próxima ocurrencia de la clase desde [now].
  /// `dayOfWeek` usa la convención de Dart: 1 = lunes .. 7 = domingo.
  static DateTime? nextOccurrence(ClassSchedule cls, DateTime now) {
    final parts = cls.startTime.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    final today = DateTime(now.year, now.month, now.day);
    var daysUntil = (cls.dayOfWeek - now.weekday) % 7;
    if (daysUntil == 0 && now.hour * 60 + now.minute >= hour * 60 + minute) {
      daysUntil += 7;
    }
    return today.add(Duration(days: daysUntil, hours: hour, minutes: minute));
  }

  /// Lógica pura: recordatorio 1h antes de la próxima ocurrencia
  /// (testeable sin plugin).
  static List<ClassNotificationSpec> specsForClass(
      ClassSchedule cls, DateTime now) {
    if (cls.id == null) return const [];
    final occurrence = nextOccurrence(cls, now);
    if (occurrence == null) return const [];
    final oneHourBefore = occurrence.subtract(const Duration(hours: 1));
    if (!oneHourBefore.isAfter(now)) return const [];
    return [
      ClassNotificationSpec(
        id: 200000 + cls.id!,
        title: cls.title,
        body: 'Tu clase empieza en 1 hora',
        scheduledDate: oneHourBefore,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      ),
    ];
  }

  /// Cancela los recordatorios vigentes y reprograma todas las clases.
  Future<void> rescheduleAll(List<ClassSchedule> schedules) async {
    for (final id in _scheduledIds) {
      await NotificationService.cancel(id);
    }
    _scheduledIds.clear();

    final now = DateTime.now();
    for (final cls in schedules) {
      for (final spec in specsForClass(cls, now)) {
        _scheduledIds.add(spec.id);
        await NotificationService.scheduleNotification(
          id: spec.id,
          title: spec.title,
          body: spec.body,
          scheduledDate: spec.scheduledDate,
          matchDateTimeComponents: spec.matchDateTimeComponents,
        );
      }
    }
  }
}
