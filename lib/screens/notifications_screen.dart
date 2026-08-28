import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';
import '../services/notification_service.dart';

const _c = Color(0xFFFFFF00);
const _dark = Color(0xFF0D0D0D);
const _near = Color(0xFF2A2A2A);

/// Notificaciones estilo "Nosotros": UN bloque por notificación con estado
/// leída/no leída; apretar abre solo esa notificación. "Marcar todas" queda en
/// la columna lateral fija.
class NotificationsScreen extends StatefulWidget {
  final AppMode mode;
  const NotificationsScreen({super.key, required this.mode});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await NotificationService.getNotifications();
      if (mounted) setState(() { _notifications = list; _loading = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'No se pudieron cargar las notificaciones'; });
      developer.log('NotificationsScreen._load error: $e');
    }
  }

  Future<void> _markAllRead() async {
    HapticFeedback.heavyImpact();
    await NotificationService.markAllAsRead();
    _load();
  }

  void _markRead(Map<String, dynamic> n) {
    final id = n['id'] as int?;
    if (id == null) return;
    if (n['read'] as bool? ?? false) return;
    NotificationService.markAsRead(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    final entries = <LocaEntry>[
      if (_error != null)
        LocaEntry(icon: Icons.cloud_off, color: const Color(0xFFCC0000), onTap: _load),
      if (!_loading && _error == null && _notifications.isEmpty)
        LocaEntry(icon: Icons.notifications_none, color: _near, iconColor: _c),
      for (var i = 0; i < _notifications.length; i++)
        LocaEntry(
          icon: (_notifications[i]['read'] as bool? ?? false)
              ? Icons.mark_email_read
              : Icons.markunread,
          color: (_notifications[i]['read'] as bool? ?? false) ? _near : _c,
          iconColor: (_notifications[i]['read'] as bool? ?? false) ? _c : _dark,
          label: _notifications[i]['title'] as String? ?? '',
          panel: i,
        ),
      LocaEntry(
        icon: Icons.done_all,
        color: _c,
        iconColor: _dark,
        label: 'todas leídas',
        onTap: _markAllRead,
        isAction: true,
      ),
    ];
    return LocaScreen(
      seed: 21,
      theme: t,
      entries: entries,
      panels: [
        for (var i = 0; i < _notifications.length; i++)
          (_, close) => _notifPanel(close, _notifications[i]),
      ],
    );
  }

  Widget _notifPanel(VoidCallback close, Map<String, dynamic> n) {
    final read = n['read'] as bool? ?? false;
    final title = n['title'] as String? ?? '';
    final body = n['body'] as String? ?? _shortBody(n['body']);
    if (!read) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _markRead(n);
      });
    }
    return LocaScreen.panel(color: _dark, borderColor: _c, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Row(children: [
          Icon(Icons.notifications, color: _c, size: 22),
          const Spacer(),
          LocaScreen.closeIcon(close, _c, Icons.close),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.bangers(color: _c, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(body, style: GoogleFonts.bangers(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400)),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 10),
    ]));
  }

  String _shortBody(dynamic body) {
    if (body == null) return '';
    final s = body.toString();
    return s.length > 80 ? '${s.substring(0, 80)}...' : s;
  }
}