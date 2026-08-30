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

/// Retos estilo "Nosotros": UN bloque-icono gigante por cada reto (con
/// check = hecho / círculo = no hecho) repartido en mosaico loco por todo el
/// lienzo. Apretar un reto abre SÓLO ese reto en un panel swink
/// (leer/toggle/editar/borrar). Sin texto a simple vista.
class RetosScreen extends StatefulWidget {
  final AppMode mode;
  const RetosScreen({super.key, required this.mode});
  @override
  State<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends State<RetosScreen> {
  List<Map<String, dynamic>> _retos = [];
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadRetos();
    _subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  void _scheduleReload() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadRetos();
    });
  }

  void _subscribe() {
    _channel = SupabaseConfig.client
        .channel('retos_loca_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'challenges',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

Future<void> _loadRetos() async {
    setState(() { _error = null; });
    // Mostrar cache local al instante (sin "carga"); luego sync con Supabase.
    if (_retos.isEmpty) {
      try {
        final cached = await LocalCache.getList('cache_retos');
        if (cached != null && cached.isNotEmpty && mounted) {
          setState(() => _retos = cached);
        }
      } catch (_) {}
    }
    try {
      final data = await SupabaseConfig.client.from('challenges').select('*')
          .or('couple_id.eq.${AppState.myId ?? ''},couple_id.eq.${AppState.partnerId ?? ''}').order('created_at', ascending: true);
      final list = List<Map<String, dynamic>>.from(data);
      if (mounted) setState(() { _retos = list; });
      await LocalCache.setList('cache_retos', list);
    } catch (e) {
      developer.log('cargar retos fallo: $e');
      if (mounted) setState(() { _error = 'No se pudieron cargar los retos'; });
    }
  }

  Future<void> _toggleChallenge(Map<String, dynamic> reto) async {
    try {
      final completed = reto['completed'] as bool? ?? false;
      await SupabaseConfig.client.from('challenges').update({'completed': !completed, 'started': true}).eq('id', reto['id']);
    } catch (e) {
      developer.log('toggle reto fallo: $e');
      if (mounted) _showError('No se pudo actualizar el reto');
    }
    if (mounted) _loadRetos();
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    try {
      await SupabaseConfig.client.from('challenges').delete().eq('id', r['id']);
    } catch (e) {
      developer.log('delete reto fallo: $e');
      if (mounted) _showError('No se pudo eliminar el reto');
    }
    if (mounted) _loadRetos();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: GoogleFonts.bangers(color: Colors.white)), backgroundColor: const Color(0xFFCC0000)));
  }

  void _addOrEdit({Map<String, dynamic>? existing}) {
    final ctrl = TextEditingController(text: existing?['title'] ?? '');
    showDialog(context: context, builder: (ctx) {
      final t = getTheme(widget.mode);
      return AlertDialog(
        backgroundColor: t.mid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: t.d, width: 4)),
        title: Icon(existing != null ? Icons.edit : Icons.flag, color: t.light, size: 34),
        content: TextField(controller: ctrl, autofocus: true, style: GoogleFonts.bangers(color: t.light), decoration: InputDecoration(hintText: 'Nombre...', hintStyle: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.4)), filled: true, fillColor: t.a.withValues(alpha: 0.25), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.a, width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.a, width: 2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.d, width: 3)))),
        actions: [
          TapTile(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: t.mid, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.mid, width: 2)), child: Icon(Icons.close, color: t.light, size: 20))),
          TapTile(onTap: () async {
            Navigator.pop(ctx);
            final text = ctrl.text.trim();
            if (text.isEmpty) return;
            try {
              if (existing != null) {
                await SupabaseConfig.client.from('challenges').update({'title': text}).eq('id', existing['id']);
              } else {
                await SupabaseConfig.client.from('challenges').insert({'couple_id': AppState.myId, 'title': text});
              }
            } catch (e) {
              developer.log('guardar reto fallo: $e');
              if (mounted) _showError('No se pudo guardar el reto');
            }
            _loadRetos();
          }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: t.a, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.a, width: 2)), child: Icon(Icons.check, color: t.dark, size: 20))),
        ],
      );
    });
  }

  String get _myInitial => (AppState.identity?.substring(0, 1).toUpperCase() ?? '?');
  String get _partnerInitial => _myInitial == 'F' ? 'R' : 'F';

  bool _done(Map<String, dynamic> r) => (r['completed'] as bool? ?? false);

  static const _randomColors = [
    Color(0xFFFF6B00), Color(0xFFFF00FF), Color(0xFF00D4FF),
    Color(0xFF39FF14), Color(0xFF9D00FF), Color(0xFFFF1493),
    Color(0xFFFFD700), Color(0xFF00FF88), Color(0xFFFF4444),
    Color(0xFF4488FF), Color(0xFFFF88CC), Color(0xFF88FF44),
  ];

  Color _retoColor(Map<String, dynamic> reto) {
    final id = reto['id'] as int? ?? 0;
    return _randomColors[id % _randomColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    // Mosaico: solo los 5 retos más recientes. El resto se ve desde "historial".
    final shownRetos = _retos.take(5).toList();
    final entries = <LocaEntry>[
      if (_error != null)
        LocaEntry(icon: Icons.cloud_off, color: const Color(0xFFCC0000), onTap: _loadRetos),
      for (var i = 0; i < shownRetos.length; i++)
        LocaEntry(
          icon: _done(shownRetos[i]) ? Icons.check_circle : Icons.radio_button_unchecked,
          color: _done(shownRetos[i]) ? t.c : _retoColor(shownRetos[i]),
          label: shownRetos[i]['title'] as String? ?? '',
          panel: i,
        ),
      LocaEntry(
        icon: Icons.history,
        color: t.c,
        label: 'historial',
        panel: shownRetos.length,
        isAction: true,
      ),
      LocaEntry(
        icon: Icons.add,
        color: t.a,
        iconColor: t.dark,
        label: 'agregar',
        onTap: () => _addOrEdit(),
        isAction: true,
      ),
    ];
    return LocaScreen(
      seed: 71,
      theme: t,
      entries: entries,
      panels: [
        for (var i = 0; i < shownRetos.length; i++)
          (_, close) => _retoPanel(t, close, shownRetos[i]),
        (_, close) => _historyPanel(t, close),
      ],
    );
  }

  Widget _historyPanel(ThemeSet t, VoidCallback close) {
    return LocaScreen.panel(color: t.mid, borderColor: t.c, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Row(children: [
          Icon(Icons.history, color: t.c, size: 22),
          const Spacer(),
          LocaScreen.closeIcon(close, t.c, Icons.close),
        ]),
      ),
      const SizedBox(height: 4),
      Expanded(
        child: _retos.isEmpty
            ? const Center(child: Icon(Icons.flag, color: Color(0x66FFFFFF), size: 60))
            : ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _retos.length,
                itemBuilder: (context, i) => _historyRetoCard(t, _retos[i]),
              ),
      ),
    ]));
  }

  Widget _historyRetoCard(ThemeSet t, Map<String, dynamic> reto) {
    final done = _done(reto);
    return TapTile(
      onTap: () => _toggleChallenge(reto),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: t.mid,
            border: Border.all(color: done ? t.c : t.e, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Row(children: [
            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? t.c : t.e, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(reto['title'] as String? ?? '',
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

  Widget _retoPanel(ThemeSet t, VoidCallback close, Map<String, dynamic> reto) {
    final done = _done(reto);
    final title = reto['title'] as String? ?? '';
    final coupleId = reto['couple_id'] as String? ?? '';
    final isMine = coupleId == AppState.myId;
    final initial = isMine ? _myInitial : _partnerInitial;
    return LocaScreen.panel(color: t.mid, borderColor: done ? t.c : t.e, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Row(children: [
          Icon(Icons.flag, color: t.e, size: 22),
          const Spacer(),
          LocaScreen.closeIcon(close, t.e, Icons.close),
        ]),
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.bangers(color: t.light, fontSize: 26, fontWeight: FontWeight.w900,
                decoration: done ? TextDecoration.lineThrough : null)),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
          Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: isMine ? const Color(0xFF00F0FF) : const Color(0xFFFF66C4), borderRadius: BorderRadius.circular(6)),
            child: Text(initial, style: GoogleFonts.bangers(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
          const Spacer(),
          TapTile(onTap: () => _toggleChallenge(reto), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: done ? t.e : t.c, borderRadius: BorderRadius.circular(12), border: Border.all(color: done ? t.e : t.c, width: 2)), child: Icon(done ? Icons.undo : Icons.check, color: t.light, size: 22))),
          const SizedBox(width: 8),
          TapTile(onTap: () => _addOrEdit(existing: reto), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: t.a, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.a, width: 2)), child: Icon(Icons.edit, color: t.dark, size: 22))),
          const SizedBox(width: 8),
          TapTile(onTap: () { HapticFeedback.heavyImpact(); _delete(reto); }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFCC0000), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFCC0000), width: 2)), child: Icon(Icons.delete, color: t.light, size: 22))),
          const SizedBox(width: 8),
        ]),
      ),
      const SizedBox(height: 14),
    ]));
  }
}