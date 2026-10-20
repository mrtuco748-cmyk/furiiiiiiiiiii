import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../app_state.dart';
import '../../../router.dart';
import '../../../services/notification_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';

/// Panel de notificaciones que se desliza desde la izquierda. Lista las
/// notificaciones (leídas/no leídas), permite abrir y darse por aludido.
class NotificationPanel extends StatefulWidget {
  final ThemeSet theme;
  const NotificationPanel({super.key, required this.theme});

  @override
  State<NotificationPanel> createState() => NotificationPanelState();
}

class NotificationPanelState extends State<NotificationPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await NotificationService.getNotifications();
      if (mounted) {
        setState(() {
          _items = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllAsRead();
    if (mounted) {
      setState(() {
        for (final n in _items) {
          n['read'] = true;
        }
      });
    }
  }

  String _formatTitle(String? rawTitle) {
    final title = (rawTitle ?? '').trim();
    final myName = (AppState.myName ?? AppState.identity ?? 'Yo').trim();
    final partnerName = AppState.partnerName;

    if (_matchesName(title, myName)) {
      return partnerName;
    }
    return title.isNotEmpty ? title : partnerName;
  }

  String _formatBody(String? rawBody) {
    String body = (rawBody ?? '').trim();
    if (body.isEmpty) return '';

    final myName = (AppState.myName ?? AppState.identity ?? 'Yo').trim();
    final partnerName = AppState.partnerName;

    final myVariants = [myName, myName.replaceAll('í', 'i').replaceAll('Í', 'I')];
    for (final v in myVariants) {
      if (v.isNotEmpty && body.contains(v)) {
        body = body.replaceAll(v, partnerName);
      }
    }
    return body;
  }

  bool _matchesName(String text, String name) {
    if (text.isEmpty || name.isEmpty) return false;
    final t = text.trim().toLowerCase().replaceAll('í', 'i');
    final n = name.trim().toLowerCase().replaceAll('í', 'i');
    return t == n;
  }

  void _open(Map<String, dynamic> n) {
    final id = (n['id'] as num?)?.toInt();
    if (id != null) {
      NotificationService.markAsRead(id);
    }
    if (mounted) setState(() => n['read'] = true);
    final type = (n['data'] is Map) ? (n['data'] as Map)['type'] as String? : null;
    final route = type == null ? null : routeForNotificationType(type);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          _formatTitle(n['title']?.toString()),
          style: GoogleFonts.bangers(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: Text(
          _formatBody(n['body']?.toString()),
          style: GoogleFonts.bangers(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          if (route != null)
            TapTile(
              onTap: () {
                Navigator.pop(ctx);
                context.push(route);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: widget.theme.b, borderRadius: BorderRadius.circular(10)),
                child: Text('VER', style: GoogleFonts.bangers(color: Colors.white, fontSize: 13)),
              ),
            ),
          TapTile(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF242424), borderRadius: BorderRadius.circular(10)),
              child: Text('CERRAR', style: GoogleFonts.bangers(color: Colors.white70, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return Material(
      color: const Color(0xFF101010),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(height: 1, color: t.d),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Icon(Icons.notifications_rounded, color: t.a, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'NOTIFICACIONES',
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (_items.any((n) => n['read'] != true))
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Text(
                          'LEER TODAS',
                          style: GoogleFonts.bangers(
                            color: t.b,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _body(t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ThemeSet t) {
    if (_loading) return const Center(child: CircularProgressIndicator(strokeWidth: 3));
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            TapTile(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: t.a, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.refresh, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_none_rounded, color: Colors.white38, size: 48),
            const SizedBox(height: 8),
            Text(
              'SIN NOTIFICACIONES',
              style: GoogleFonts.bangers(color: Colors.white38, fontSize: 14, letterSpacing: 1),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final n = _items[i];
        final read = n['read'] == true;
        final color = read ? Colors.white38 : t.a;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _open(n),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: read ? const Color(0xFF1A1A1A) : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(read ? Icons.mark_email_read : Icons.markunread, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTitle(n['title']?.toString()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.bangers(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
                      ),
                      if ((n['body']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatBody(n['body']?.toString()),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}
