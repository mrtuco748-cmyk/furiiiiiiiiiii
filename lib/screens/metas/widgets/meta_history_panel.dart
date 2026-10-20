import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/loca_screen.dart';
import '../../../widgets/tap_tile.dart';

/// Panel swink que lista todas las metas existentes y permite abrirlas con doble tap o marcarlas con tap simple.
class MetaHistoryPanel extends StatefulWidget {
  final ThemeSet theme;
  final VoidCallback close;
  final List<Map<String, dynamic>> metas;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final ValueChanged<Map<String, dynamic>> onOpenDetail;

  const MetaHistoryPanel({
    super.key,
    required this.theme,
    required this.close,
    required this.metas,
    required this.onToggle,
    required this.onOpenDetail,
  });

  @override
  State<MetaHistoryPanel> createState() => _MetaHistoryPanelState();
}

class _MetaHistoryPanelState extends State<MetaHistoryPanel> {
  int _tapMetaId = 0;
  Timer? _tapTimerMeta;

  @override
  void dispose() {
    _tapTimerMeta?.cancel();
    super.dispose();
  }

  void _handleTap(Map<String, dynamic> meta) {
    if (_tapMetaId == meta['id']) {
      _tapTimerMeta?.cancel();
      _tapTimerMeta = null;
      _tapMetaId = 0;
      widget.onOpenDetail(meta);
    } else {
      _tapTimerMeta?.cancel();
      setState(() => _tapMetaId = (meta['id'] as num).toInt());
      _tapTimerMeta = Timer(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() => _tapMetaId = 0);
        widget.onToggle(meta);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return LocaScreen.panel(
      color: t.mid,
      borderColor: t.d,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                Icon(Icons.history, color: t.d, size: 22),
                const Spacer(),
                LocaScreen.closeIcon(widget.close, t.d, Icons.close),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: widget.metas.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.emoji_events,
                      color: Color(0x66FFFFFF),
                      size: 60,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: widget.metas.length,
                    itemBuilder: (context, i) => _buildCard(t, widget.metas[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(ThemeSet t, Map<String, dynamic> meta) {
    final done = (meta['completed'] as bool? ?? false);
    return TapTile(
      onTap: () => _handleTap(meta),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.mid,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? t.d : t.e,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  meta['title'] as String? ?? '',
                  style: GoogleFonts.bangers(
                    color: t.light,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: t.light.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
