import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../supabase_config.dart';
import '../services/local_cache.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';
import '../widgets/tap_tile.dart';
import '../widgets/app_feedback.dart';

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
    setState(() { _error = null; });
    // Mostrar el cache local al instante (sin "carga"); luego sync con Supabase.
    if (_metas.isEmpty) {
      try {
        final cached = await LocalCache.getList('cache_metas');
        if (cached != null && cached.isNotEmpty && mounted) {
          setState(() => _metas = cached);
        }
      } catch (_) {}
    }
    try {
      final data = await SupabaseConfig.client.from('goals').select('*')
          .or('couple_id.eq.${AppState.myId ?? ''},couple_id.eq.${AppState.partnerId ?? ''}').order('created_at', ascending: true);
      final list = List<Map<String, dynamic>>.from(data);
      if (mounted) setState(() { _metas = list; });
      await LocalCache.setList('cache_metas', list);
    } catch (e) {
      developer.log('cargar metas fallo: $e');
      if (mounted) setState(() { _error = 'No se pudieron cargar las metas'; });
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
        AppFeedback.success(context, '¡Meta cumplida! 🎉',
            celebration: true);
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

  /// Reinserta una meta borrada (deshacer).
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.bangers(color: Colors.white)), backgroundColor: const Color(0xFFCC0000)));
  }

  void _addOrEdit({Map<String, dynamic>? existing}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    showDialog(context: context, builder: (ctx) {
      final t = getTheme(widget.mode);
      return AlertDialog(backgroundColor: t.mid, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: t.d, width: 4)),
        title: Icon(existing != null ? Icons.edit : Icons.emoji_events, color: t.light, size: 34),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, autofocus: true, style: GoogleFonts.bangers(color: t.light), decoration: InputDecoration(hintText: 'Titulo...', hintStyle: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.4)), filled: true, fillColor: t.e.withValues(alpha: 0.25), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.e, width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.e, width: 2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.d, width: 3)))),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, maxLines: 2, style: GoogleFonts.bangers(color: t.light), decoration: InputDecoration(hintText: 'Descripcion...', hintStyle: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.4)), filled: true, fillColor: t.e.withValues(alpha: 0.25), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.e, width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.e, width: 2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.d, width: 3)))),
        ]),
        actions: [
          TapTile(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: t.mid, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.mid, width: 2)), child: Icon(Icons.close, color: t.light, size: 20))),
          TapTile(onTap: () async {
            Navigator.pop(ctx);
            final title = titleCtrl.text.trim();
            if (title.isEmpty) return;
            try {
              if (existing != null) {
                await SupabaseConfig.client.from('goals').update({'title': title, 'description': descCtrl.text.trim()}).eq('id', existing['id']);
              } else {
                await SupabaseConfig.client.from('goals').insert({'couple_id': AppState.myId, 'title': title, 'description': descCtrl.text.trim()});
              }
              if (mounted) AppFeedback.saved(context, 'Meta guardada');
            } catch (e) {
              developer.log('guardar meta fallo: $e');
              if (mounted) _showError('No se pudo guardar la meta');
            }
            _loadMetas();
          }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: t.e, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.e, width: 2)), child: Icon(Icons.check, color: t.light, size: 20))),
        ],
      );
    });
  }

  String get _myInitial => (AppState.identity?.substring(0, 1).toUpperCase() ?? '?');
  String get _partnerInitial => _myInitial == 'F' ? 'R' : 'F';
  bool _done(Map<String, dynamic> m) => (m['completed'] as bool? ?? false);

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    final palette = [t.a, t.b, t.c, t.d, t.e];
    // Mosaico: solo las 8 metas más recientes (en su orden). El resto se ve
    // desde "historial".
    final shownMetas = _metas.take(8).toList();
    final entries = <LocaEntry>[
      if (_error != null)
        LocaEntry(icon: Icons.cloud_off, color: const Color(0xFFCC0000), onTap: _loadMetas),
      for (var i = 0; i < shownMetas.length; i++)
        LocaEntry(
          icon: _done(shownMetas[i]) ? Icons.check_circle : Icons.radio_button_unchecked,
          color: _done(shownMetas[i]) ? t.d : palette[i % palette.length],
          label: shownMetas[i]['title'] as String? ?? '',
          panel: i,
        ),
      LocaEntry(
        icon: Icons.history,
        color: t.d,
        label: 'historial',
        panel: shownMetas.length,
        isAction: true,
      ),
      LocaEntry(
        icon: Icons.add,
        color: t.e,
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
          (_, close) => _metaPanel(t, close, shownMetas[i]),
        (_, close) => _historyPanel(t, close),
      ],
    );
  }

  Widget _historyPanel(ThemeSet t, VoidCallback close) {
    return LocaScreen.panel(color: t.mid, borderColor: t.d, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Row(children: [
          Icon(Icons.history, color: t.d, size: 22),
          const Spacer(),
          LocaScreen.closeIcon(close, t.d, Icons.close),
        ]),
      ),
      const SizedBox(height: 4),
      Expanded(
        child: _metas.isEmpty
            ? const Center(child: Icon(Icons.emoji_events, color: Color(0x66FFFFFF), size: 60))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _metas.length,
                itemBuilder: (context, i) => _historyMetaCard(t, _metas[i]),
              ),
      ),
    ]));
  }

  Widget _historyMetaCard(ThemeSet t, Map<String, dynamic> meta) {
    final done = _done(meta);
    return TapTile(
      onTap: () => _toggle(meta),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.mid,
            border: Border.all(color: done ? t.d : t.e, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Row(children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? t.d : t.e, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(meta['title'] as String? ?? '',
                style: GoogleFonts.bangers(
                  color: t.light,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  decoration: done ? TextDecoration.lineThrough : null,
                )),
            ),
            Icon(Icons.chevron_right, color: t.light.withValues(alpha: 0.4), size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _metaPanel(ThemeSet t, VoidCallback close, Map<String, dynamic> meta) {
    final done = _done(meta);
    final title = meta['title'] as String? ?? '';
    final description = meta['description'] as String? ?? '';
    final completedBy = meta['completed_by'] as String?;
    final doneInitial = done && completedBy != null
        ? (completedBy == AppState.myId ? _myInitial : _partnerInitial)
        : null;
    return LocaScreen.panel(color: t.mid, borderColor: done ? t.d : t.e, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Row(children: [
          Icon(Icons.emoji_events, color: t.d, size: 22),
          const Spacer(),
          LocaScreen.closeIcon(close, t.d, Icons.close),
        ]),
      ),
      Expanded(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(title, textAlign: TextAlign.center,
                  style: GoogleFonts.bangers(color: t.light, fontSize: 26, fontWeight: FontWeight.w900,
                    decoration: done ? TextDecoration.lineThrough : null)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(description, textAlign: TextAlign.center,
                    style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.7), fontSize: 14,
                      decoration: done ? TextDecoration.lineThrough : null)),
                ],
                if (doneInitial != null) ...[
                  const SizedBox(height: 12),
                  Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(color: t.d, borderRadius: BorderRadius.circular(6)),
                    child: Text(doneInitial, style: GoogleFonts.bangers(color: t.light, fontSize: 11, fontWeight: FontWeight.w900))),
                ],
              ]),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          const Spacer(),
          TapTile(onTap: () => _toggle(meta), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: done ? t.e : t.d, borderRadius: BorderRadius.circular(12), border: Border.all(color: done ? t.e : t.d, width: 2)), child: Icon(done ? Icons.undo : Icons.check, color: t.light, size: 22))),
          const SizedBox(width: 8),
          TapTile(onTap: () => _addOrEdit(existing: meta), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: t.a, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.a, width: 2)), child: Icon(Icons.edit, color: t.dark, size: 22))),
          const SizedBox(width: 8),
          TapTile(onTap: () { HapticFeedback.heavyImpact(); _delete(meta); }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFCC0000), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCC0000), width: 2)), child: Icon(Icons.delete, color: t.light, size: 22))),
          const SizedBox(width: 8),
        ]),
      ),
      const SizedBox(height: 14),
    ]));
  }
}