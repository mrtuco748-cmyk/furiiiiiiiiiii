import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../services/local_cache.dart';
import '../supabase_config.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/loca_screen.dart';
import 'metas/widgets/meta_detail_panel.dart';
import 'metas/widgets/meta_edit_dialog.dart';
import 'metas/widgets/meta_history_panel.dart';

/// Metas estilo "Nosotros": UN bloque-icono por cada meta (check = hecha /
/// círculo = no hecha) en mosaico loco que ocupa toda la pantalla. Apretar una
/// meta abre SÓLO esa meta en un panel swink (leer/toggle/editar/borrar).
class MetasScreen extends StatefulWidget {
  final AppMode mode;
  const MetasScreen({super.key, required this.mode});
  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  List<Map<String, dynamic>> _metas = [];
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadMetas();
    _subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _scheduleReload() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadMetas();
    });
  }

  void _subscribe() {
    _channel = SupabaseConfig.client
        .channel('metas_loca_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'goals',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  Future<void> _loadMetas() async {
    setState(() {
      _error = null;
    });
    if (_metas.isEmpty) {
      try {
        final cached = await LocalCache.getList('cache_metas');
        if (cached.isNotEmpty && mounted) {
          setState(() => _metas = cached);
        }
      } catch (_) {}
    }
    try {
      final data = await SupabaseConfig.client
          .from('goals')
          .select('*')
          .or('couple_id.eq.${AppState.myId ?? ''},couple_id.eq.${AppState.partnerId ?? ''}')
          .order('created_at', ascending: true);
      final list = List<Map<String, dynamic>>.from(data);
      if (mounted) setState(() => _metas = list);
      await LocalCache.setList('cache_metas', list);
    } catch (e) {
      developer.log('cargar metas fallo: $e');
      if (mounted) setState(() => _error = 'No se pudieron cargar las metas');
    }
  }

  Future<void> _toggle(Map<String, dynamic> m) async {
    try {
      final completed = m['completed'] as bool? ?? false;
      await SupabaseConfig.client.from('goals').update({
        'completed': !completed,
        'completed_by': completed ? null : AppState.myId,
      }).eq('id', m['id']);
      if (!completed && mounted) {
        AppFeedback.success(context, '¡Meta cumplida! 🎉', celebration: true);
      }
    } catch (e) {
      developer.log('toggle meta fallo: $e');
      if (mounted) _showError('No se pudo actualizar la meta');
    }
    if (mounted) _loadMetas();
  }

  Future<void> _delete(Map<String, dynamic> m) async {
    try {
      await SupabaseConfig.client.from('goals').delete().eq('id', m['id']);
      if (mounted) {
        AppFeedback.deleted(context, 'Meta eliminada',
            onUndo: () => _restoreMeta(m));
      }
    } catch (e) {
      developer.log('delete meta fallo: $e');
      if (mounted) _showError('No se pudo eliminar la meta');
    }
    if (mounted) _loadMetas();
  }

  Future<void> _restoreMeta(Map<String, dynamic> m) async {
    try {
      await SupabaseConfig.client.from('goals').insert({
        'couple_id': m['couple_id'] ?? AppState.myId,
        'title': m['title'],
        'description': m['description'],
        'completed': m['completed'] ?? false,
        if (m['completed_by'] != null) 'completed_by': m['completed_by'],
      });
    } catch (e) {
      developer.log('restaurar meta fallo: $e');
    }
    if (mounted) _loadMetas();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: GoogleFonts.bangers(color: Colors.white)),
        backgroundColor: const Color(0xFFCC0000)));
  }

  void _addOrEdit({Map<String, dynamic>? existing}) {
    MetaEditDialog.show(
      context,
      existing: existing,
      theme: getTheme(widget.mode),
      onSaved: _loadMetas,
    );
  }

  void _showMetaModal(Map<String, dynamic> meta) {
    final t = getTheme(widget.mode);
    final done = _done(meta);
    final title = meta['title'] as String? ?? '';
    final description = meta['description'] as String? ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.mid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Icon(Icons.flag, color: t.light, size: 34),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.bangers(
                color: t.light,
                fontSize: 24,
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
                  decoration: done ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _done(Map<String, dynamic> m) => (m['completed'] as bool? ?? false);

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    final palette = [
      const Color(0xFFFF6B00),
      const Color(0xFF00D4FF),
      const Color(0xFF9D00FF),
      const Color(0xFFFF1493),
      const Color(0xFFFFDE59),
      const Color(0xFFFF00FF),
      const Color(0xFF7000FF),
      const Color(0xFFFF5757),
    ];
    const doneColor = Color(0xFF39FF14);
    final shownMetas = _metas.take(8).toList();

    final entries = <LocaEntry>[
      if (_error != null)
        LocaEntry(
            icon: Icons.cloud_off,
            color: const Color(0xFFCC0000),
            onTap: _loadMetas),
      for (var i = 0; i < shownMetas.length; i++)
        LocaEntry(
          icon: _done(shownMetas[i])
              ? Icons.check_circle
              : Icons.radio_button_unchecked,
          color: _done(shownMetas[i]) ? doneColor : palette[i % palette.length],
          label: shownMetas[i]['title'] as String? ?? '',
          panel: i,
        ),
      LocaEntry(
        icon: Icons.history,
        color: const Color(0xFF555555),
        label: 'historial',
        panel: shownMetas.length,
        isAction: true,
      ),
      LocaEntry(
        icon: Icons.add,
        color: const Color(0xFF39FF14),
        label: 'agregar',
        onTap: () => _addOrEdit(),
        isAction: true,
      ),
    ];

    return LocaScreen(
      seed: 97,
      theme: t,
      entries: entries,
      panels: [
        for (var i = 0; i < shownMetas.length; i++)
          (_, close) => MetaDetailPanel(
                theme: t,
                close: close,
                meta: shownMetas[i],
                onToggle: _toggle,
                onEdit: (m) => _addOrEdit(existing: m),
                onDelete: _delete,
              ),
        (_, close) => MetaHistoryPanel(
              theme: t,
              close: close,
              metas: _metas,
              onToggle: _toggle,
              onOpenDetail: _showMetaModal,
            ),
      ],
    );
  }
}
