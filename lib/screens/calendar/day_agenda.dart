import '../../models/class_schedule.dart';
import '../../models/recurrence.dart';
import '../../models/schedule.dart';

/// Un renglón de la agenda del día: evento único, evento repetido o clase
/// vieja (`class_schedules`, mostrada como repetido semanal).
class AgendaItem {
  final String title;
  final String startTime;
  final String endTime;
  final String location;
  final int color;
  final String userId;
  final bool recurring;
  final Schedule? schedule;
  final ClassSchedule? legacyClass;

  const AgendaItem({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.color,
    required this.userId,
    required this.recurring,
    this.schedule,
    this.legacyClass,
  });
}

/// Lógica pura de la agenda (testeable sin providers ni widgets).
class DayAgenda {
  DayAgenda._();

  static int _minutes(String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) return 24 * 60 + 1;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return 24 * 60 + 1;
    return h * 60 + m;
  }

  static List<AgendaItem> forDay({
    required List<Schedule> schedules,
    required List<ClassSchedule> classes,
    required DateTime day,
  }) {
    final items = <AgendaItem>[];
    for (final s in schedules) {
      final r = Recurrence.parse(s.recurrence);
      if (!r.occursOn(s.date, day)) continue;
      items.add(AgendaItem(
        title: s.title,
        startTime: s.startTime,
        endTime: s.endTime,
        location: s.location,
        color: s.color,
        userId: s.userId,
        recurring: r.isRecurring,
        schedule: s,
      ));
    }
    for (final c in classes) {
      if (c.dayOfWeek != day.weekday) continue;
      items.add(AgendaItem(
        title: c.title,
        startTime: c.startTime,
        endTime: c.endTime,
        location: c.professor,
        color: c.color,
        userId: c.userId,
        recurring: true,
        legacyClass: c,
      ));
    }
    items.sort((a, b) => _minutes(a.startTime).compareTo(_minutes(b.startTime)));
    return items;
  }

  static bool hasAny({
    required List<Schedule> schedules,
    required List<ClassSchedule> classes,
    required DateTime day,
  }) =>
      forDay(schedules: schedules, classes: classes, day: day).isNotEmpty;

  /// Las clases viejas guardaban 1 fila por día: agrupa las filas que son la
  /// "misma" clase (título + horario + autor) para editarlas/borrarlas juntas.
  static List<ClassSchedule> legacyGroup(
      List<ClassSchedule> all, ClassSchedule c) {
    return all
        .where((x) =>
            x.title == c.title &&
            x.startTime == c.startTime &&
            x.endTime == c.endTime &&
            x.userId == c.userId)
        .toList();
  }
}
