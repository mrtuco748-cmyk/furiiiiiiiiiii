/// Regla de repetición de un evento del calendario.
///
/// Se persiste como texto en `schedules.recurrence` (SQLite y Supabase):
/// - `''`              → evento único (solo el día ancla `date`)
/// - `'weekly:1,3,5'`  → días de la semana (1=lunes … 7=domingo)
/// - `'every:3'`       → cada N días desde el ancla
/// - `'monthly'`       → mismo día del mes (si no existe, el último del mes)
/// - `'yearly'`        → mismo día y mes (29/2 cae el 28/2 en no bisiestos)
///
/// Nunca ocurre antes del día ancla. Sin fecha de fin (decisión del usuario).
enum RecurrenceKind { none, weekly, everyNDays, monthly, yearly }

class Recurrence {
  final RecurrenceKind kind;
  final Set<int> weekdays;
  final int interval;

  const Recurrence._(this.kind, {this.weekdays = const {}, this.interval = 1});

  static const none = Recurrence._(RecurrenceKind.none);

  factory Recurrence.weekly(Set<int> days) {
    final valid = days.where((d) => d >= 1 && d <= 7).toSet();
    if (valid.isEmpty) return none;
    return Recurrence._(RecurrenceKind.weekly, weekdays: valid);
  }

  factory Recurrence.everyNDays(int n) =>
      n < 1 ? none : Recurrence._(RecurrenceKind.everyNDays, interval: n);

  factory Recurrence.monthly() => const Recurrence._(RecurrenceKind.monthly);

  factory Recurrence.yearly() => const Recurrence._(RecurrenceKind.yearly);

  bool get isRecurring => kind != RecurrenceKind.none;

  static Recurrence parse(String? raw) {
    final s = (raw ?? '').trim();
    if (s == 'monthly') return Recurrence.monthly();
    if (s == 'yearly') return Recurrence.yearly();
    if (s.startsWith('weekly:')) {
      final days = s
          .substring(7)
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .toSet();
      return Recurrence.weekly(days);
    }
    if (s.startsWith('every:')) {
      return Recurrence.everyNDays(int.tryParse(s.substring(6)) ?? 0);
    }
    return none;
  }

  String encode() {
    switch (kind) {
      case RecurrenceKind.none:
        return '';
      case RecurrenceKind.weekly:
        final days = weekdays.toList()..sort();
        return 'weekly:${days.join(',')}';
      case RecurrenceKind.everyNDays:
        return 'every:$interval';
      case RecurrenceKind.monthly:
        return 'monthly';
      case RecurrenceKind.yearly:
        return 'yearly';
    }
  }

  static DateTime _d(DateTime x) => DateTime.utc(x.year, x.month, x.day);

  static int _daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  /// ¿El evento con ancla [anchor] ocurre el día [day]?
  bool occursOn(DateTime anchor, DateTime day) {
    final a = _d(anchor);
    final d = _d(day);
    if (d.isBefore(a)) return false;
    switch (kind) {
      case RecurrenceKind.none:
        return d == a;
      case RecurrenceKind.weekly:
        return weekdays.contains(d.weekday);
      case RecurrenceKind.everyNDays:
        // UTC: sin saltos de horario de verano en la diferencia de días.
        return d.difference(a).inDays % interval == 0;
      case RecurrenceKind.monthly:
        final target = a.day.clamp(1, _daysInMonth(d.year, d.month));
        return d.day == target;
      case RecurrenceKind.yearly:
        if (d.month != a.month) return false;
        final target = a.day.clamp(1, _daysInMonth(d.year, d.month));
        return d.day == target;
    }
  }

  /// Primera ocurrencia en o después de [from] (fecha sin hora), o null.
  DateTime? nextOnOrAfter(DateTime anchor, DateTime from) {
    final a = DateTime(anchor.year, anchor.month, anchor.day);
    var d = DateTime(from.year, from.month, from.day);
    if (d.isBefore(a)) d = a;
    if (kind == RecurrenceKind.none) return d == a ? a : null;
    // Peor caso: anual (≤ 366 días; con 29/2 sigue cayendo el 28/2).
    for (var i = 0; i < 400; i++) {
      final c = DateTime(d.year, d.month, d.day + i);
      if (occursOn(a, c)) return c;
    }
    return null;
  }
}
