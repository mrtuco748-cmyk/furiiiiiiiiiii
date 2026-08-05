import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import '../services/notification_service.dart';

const _c = Color(0xFFFFFF00);
const _dark = Color(0xFF000000);
const _near = Color(0xFF1A1A1A);

Widget fillIcon(IconData icon, Color color) {
  return FittedBox(
    fit: BoxFit.contain,
    child: SizedBox(width: 120, height: 120, child: Icon(icon, color: color, size: 120)),
  );
}

Widget bg(double w, double h) {
  return Positioned.fill(child: CustomPaint(painter: ConcretePainter()));
}

Widget nBlock(double l, double t, double w, double h, Color bgColor, Widget child,
    void Function() onTap, {int borderWidth = 3, Color borderColor = const Color(0xFF000000)}) {
  return Positioned(
    left: l, top: t, width: w, height: h,
    child: TapTile(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: borderWidth.toDouble()),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: child,
        ),
      ),
    ),
  );
}

class NotificationsScreen extends StatefulWidget {
  final AppMode mode;
  const NotificationsScreen({super.key, required this.mode});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationService.getNotifications();
    if (mounted) setState(() { _notifications = list; _loading = false; });
  }

  Future<void> _markAllRead() async {
    HapticFeedback.heavyImpact();
    await NotificationService.markAllAsRead();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: ResponsiveWrapper(builder: (context, w, h) {
            return SizedBox(width: w, height: h, child: Stack(
              children: [
                bg(w, h),
                nBlock(w * 0.04, h * 0.02, w * 0.12, w * 0.12, _dark,
                  fillIcon(Icons.arrow_back, _c),
                  () { HapticFeedback.heavyImpact(); Navigator.pop(context); },
                  borderWidth: 4, borderColor: _c),
                nBlock(w * 0.84, h * 0.02, w * 0.12, w * 0.12, _c,
                  fillIcon(Icons.done_all, _dark),
                  _markAllRead, borderWidth: 4, borderColor: _dark),
                nBlock(w * 0.72, h * 0.02, w * 0.10, w * 0.10, _dark,
                  fillIcon(Icons.filter_list, _c),
                  () { HapticFeedback.heavyImpact(); }, borderWidth: 3, borderColor: _c),
                _listBlock(w, h),
              ],
            ));
          },
      ),
    );
  }

  Widget _listBlock(double w, double h) {
    return Positioned(
      left: w * 0.04, top: h * 0.16, width: w * 0.92, height: h * 0.80,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              border: Border.all(color: _c, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildListContent(w),
            ),
          ),
        ),
    );
  }

  Widget _buildListContent(double w) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _c, strokeWidth: 3));
    }
    if (_notifications.isEmpty) {
      return Center(
        child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(width: 120, height: 120, child: Icon(Icons.notifications_none, color: _c, size: 120)),
          ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _notificationBlock(index),
        );
      },
    );
  }

  Widget _notificationBlock(int index) {
    final n = _notifications[index];
    final read = n['read'] as bool? ?? false;
    final bgColor = read ? _near : _c;
    final iconColor = read ? _c : _dark;
    final borderClr = read ? _c : _dark;
    return TapTile(
      onTap: () {
        HapticFeedback.heavyImpact();
        final id = n['id'] as int?;
        if (id != null) NotificationService.markAsRead(id);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderClr, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Row(
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(width: 50, height: 50,
                  child: Icon(Icons.notifications, color: iconColor, size: 50)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      n['title'] as String? ?? '',
                      style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: iconColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shortBody(n['body']),
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: read ? const Color(0xFFAAAAAA) : iconColor),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortBody(dynamic body) {
    if (body == null) return '';
    final s = body.toString();
    return s.length > 80 ? '${s.substring(0, 80)}...' : s;
  }
}
