/// Nombres canónicos de ruta en la aplicación F.U.R.I.
abstract final class RouterRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String nosotros = '/nosotros';
  static const String calendar = '/calendar';
  static const String trivia = '/trivia';
  static const String finanzas = '/finanzas';
  static const String galeria = '/galeria';
  static const String pinterest = '/pinterest';
  static const String favoritos = '/favoritos';
  static const String milanote = '/milanote';
  static const String notes = '/notes';
  static const String pizarra = '/pizarra';
  static const String music = '/music';
  static const String ejercicios = '/ejercicios';
  static const String logros = '/logros';
  static const String rewards = '/rewards';
  static const String chat = '/chat';
  static const String retos = '/retos';
  static const String cartas = '/cartas';
  static const String metas = '/metas';
  static const String mapa = '/mapa';
  static const String scheduleForm = '/calendar/form';
  static const String dailyEvents = '/calendar/dia';
  static const String classBoard = '/calendar/clases';
  static const String classSetup = '/calendar/setup';
  static const String calendarMosaico = '/calendario-mosaico';
  static const String notesMosaico = '/notes-mosaico';
  static const String ejerciciosMosaico = '/ejercicios-mosaico';
  static const String herramientas = '/herramientas';
  static const String dibujo = '/dibujo';
  static const String comic = '/comic';
  static const String comicReader = '/comic/reader';
}

/// Mapea el `data.type` de una notificación push a la ruta canónica de la app.
String? routeForNotificationType(String type) {
  switch (type) {
    case 'message':
      return RouterRoutes.chat;
    case 'mood':
    case 'letter':
    case 'custom_question':
    case 'timeline':
      return RouterRoutes.nosotros;
    case 'goal':
      return RouterRoutes.metas;
    case 'challenge':
      return RouterRoutes.retos;
    case 'note':
    case 'pizarra':
      return RouterRoutes.milanote;
    case 'transaction':
      return RouterRoutes.finanzas;
    case 'favorite':
      return RouterRoutes.favoritos;
    case 'gallery':
      return RouterRoutes.galeria;
    case 'schedule':
    case 'class_schedule':
    case 'anniversary':
      return RouterRoutes.calendar;
    case 'achievement':
      return RouterRoutes.logros;
    case 'workout_log':
    case 'workout_completion':
    case 'workout_challenge':
      return RouterRoutes.ejercicios;
    case 'music':
      return RouterRoutes.music;
    case 'trivia':
      return RouterRoutes.trivia;
    case 'mapa':
      return RouterRoutes.mapa;
    default:
      return RouterRoutes.notifications;
  }
}
