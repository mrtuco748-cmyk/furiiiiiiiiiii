import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app_state.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/loca_screen.dart';
import '../../../widgets/tap_tile.dart';

/// Panel swink que muestra el detalle de una meta, con botones para cumplir/deshacer, editar y eliminar.
class MetaDetailPanel extends StatelessWidget {
  final ThemeSet theme;
  final VoidCallback close;
  final Map<String, dynamic> meta;
  final ValueChanged<Map<String, dynamic>> onToggle;
  final ValueChanged<Map<String, dynamic>> onEdit;
  final ValueChanged<Map<String, dynamic>> onDelete;

  const MetaDetailPanel({
    super.key,
    required this.theme,
    required this.close,
    required this.meta,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  String get _myInitial =>
      (AppState.identity?.substring(0, 1).toUpperCase() ?? '?');
  String get _partnerInitial => _myInitial == 'F' ? 'R' : 'F';

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final done = meta['completed'] as bool? ?? false;
    final title = meta['title'] as String? ?? '';
    final description = meta['description'] as String? ?? '';
    final completedBy = meta['completed_by'] as String?;
    final doneInitial = done && completedBy != null
        ? (completedBy == AppState.myId ? _myInitial : _partnerInitial)
        : null;

    return LocaScreen.panel(
      color: t.mid,
      borderColor: done ? t.d : t.e,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                Icon(Icons.emoji_events, color: t.d, size: 22),
                const Spacer(),
                LocaScreen.closeIcon(close, t.d, Icons.close),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.bangers(
                          color: t.light,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          decoration: done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          description,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.bangers(
                            color: t.light.withValues(alpha: 0.7),
                            fontSize: 14,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                      if (doneInitial != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.d,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            doneInitial,
                            style: GoogleFonts.bangers(
                              color: t.light,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Spacer(),
                TapTile(
                  onTap: () {
                    close();
                    onToggle(meta);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: done ? t.e : t.d,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      done ? Icons.undo : Icons.check,
                      color: t.light,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TapTile(
                  onTap: () {
                    close();
                    onEdit(meta);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.a,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit, color: t.dark, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                TapTile(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    close();
                    onDelete(meta);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCC0000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete, color: t.light, size: 22),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
