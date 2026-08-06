import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../supabase_config.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import '../theme/app_theme.dart';

class MetasScreen extends StatefulWidget {
  final AppMode mode;
  const MetasScreen({super.key, required this.mode});
  @override
  State<MetasScreen> createState() => _MetasScreenState();
}

class _MetasScreenState extends State<MetasScreen> {
  List<Map<String, dynamic>> _metas = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadMetas(); }

  Future<void> _loadMetas() async {
    try {
      final data = await SupabaseConfig.client.from('goals').select('*')
          .or('couple_id.eq.${AppState.myId ?? ''},couple_id.eq.${AppState.partnerId ?? ''}').order('created_at', ascending: false);
      if (mounted) setState(() { _metas = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _toggle(Map<String, dynamic> m) async {
    final completed = m['completed'] as bool? ?? false;
    await SupabaseConfig.client.from('goals').update({
      'completed': !completed,
      'completed_by': completed ? null : AppState.myId,
    }).eq('id', m['id']);
    _loadMetas();
  }

  Future<void> _delete(Map<String, dynamic> m) async {
    await SupabaseConfig.client.from('goals').delete().eq('id', m['id']);
    _loadMetas();
  }

  void _addOrEdit({Map<String, dynamic>? existing}) {
    final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    showDialog(context: context, builder: (ctx) {
      final t = getTheme(widget.mode);
      return AlertDialog(backgroundColor: t.mid, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: t.d, width: 4)),
        title: Text(existing != null ? 'Editar Meta' : 'Nueva Meta', style: GoogleFonts.bangers(color: t.light, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, autofocus: true, style: GoogleFonts.bangers(color: t.light), decoration: InputDecoration(hintText: 'Titulo...', hintStyle: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.4)), filled: true, fillColor: t.e.withValues(alpha: 0.25), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.e, width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.e, width: 2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.d, width: 3)))),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, maxLines: 2, style: GoogleFonts.bangers(color: t.light), decoration: InputDecoration(hintText: 'Descripcion...', hintStyle: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.4)), filled: true, fillColor: t.e.withValues(alpha: 0.25), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.e, width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.e, width: 2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.d, width: 3)))),
        ]),
        actions: [
          TapTile(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: t.mid, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.mid, width: 2)), child: Text('Cancelar', style: GoogleFonts.bangers(color: t.light)))),
          TapTile(onTap: () async {
            Navigator.pop(ctx);
            final title = titleCtrl.text.trim();
            if (title.isEmpty) return;
            if (existing != null) {
              await SupabaseConfig.client.from('goals').update({'title': title, 'description': descCtrl.text.trim()}).eq('id', existing['id']);
            } else {
              await SupabaseConfig.client.from('goals').insert({'couple_id': AppState.myId, 'title': title, 'description': descCtrl.text.trim()});
            }
            _loadMetas();
          }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: t.e, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.e, width: 2)), child: Text(existing != null ? 'OK' : 'Crear', style: GoogleFonts.bangers(color: t.light, fontWeight: FontWeight.bold)))),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Scaffold(backgroundColor: const Color(0xFF1A1A1A),
      body: ResponsiveWrapper(builder: (context, w, h) {
        return SizedBox(width: w, height: h, child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          _header(w, h, t),
          _body(w, h, t),
          _fab(w, h, t),
        ]));
      }),
    );
  }

  Widget _header(double w, double h, ThemeSet t) {
    final barH = h * 0.07;
    return Positioned(left: 0, top: 0, width: w, height: barH, child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(decoration: BoxDecoration(color: t.e, border: Border.all(color: t.e, width: 4), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
        child: Center(child: Text('METAS', style: GoogleFonts.bangers(color: t.light, fontSize: 20, fontWeight: FontWeight.bold)))),
    ));
  }

  Widget _body(double w, double h, ThemeSet t) {
    final top = h * 0.07 + h * 0.02; final pad = w * 0.04;
    if (_loading) return Positioned(left: pad, top: top, width: w - pad * 2, height: h - top, child: Center(child: CircularProgressIndicator(color: t.a)));
    if (_metas.isEmpty) return Positioned(left: pad, top: top, width: w - pad * 2, height: h - top, child: Center(child: Text('Sin metas aun', style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.5), fontSize: 14))));
    return Positioned(left: pad, top: top, width: w - pad * 2, height: h - top - pad,
      child: ListView.builder(itemCount: _metas.length, itemBuilder: (context, i) {
        final meta = _metas[i]; final completed = meta['completed'] as bool? ?? false; final title = meta['title'] as String? ?? ''; final description = meta['description'] as String? ?? '';
        final myInitial = AppState.identity?.substring(0, 1).toUpperCase() ?? '?';
        final completedBy = meta['completed_by'] as String?;
        final doneInitial = completed && completedBy != null ? (completedBy == AppState.myId ? myInitial : (myInitial == 'F' ? 'R' : 'F')) : null;
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: completed ? t.e.withValues(alpha: 0.15) : t.e.withValues(alpha: 0.20), border: Border.all(color: completed ? t.d : t.e, width: 3), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                GestureDetector(onTap: () => _toggle(meta), child: Icon(completed ? Icons.emoji_events : Icons.emoji_events_outlined, color: completed ? t.d : t.e, size: 24)),
                if (doneInitial != null) Padding(padding: const EdgeInsets.only(top: 2), child: Container(width: 18, height: 18, alignment: Alignment.center, decoration: BoxDecoration(color: completed ? t.d : t.mid, borderRadius: BorderRadius.circular(6)), child: Text(doneInitial, style: GoogleFonts.bangers(color: t.light, fontSize: 10, fontWeight: FontWeight.w900)))),
              ]),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.bangers(color: t.light, fontSize: 14, fontWeight: FontWeight.bold, decoration: completed ? TextDecoration.lineThrough : null)),
                if (description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(description, style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.6), fontSize: 11, decoration: completed ? TextDecoration.lineThrough : null))),
              ])),
              GestureDetector(onTap: () => _addOrEdit(existing: meta), child: Icon(Icons.edit, color: t.light.withValues(alpha: 0.5), size: 18)),
              const SizedBox(width: 6),
              GestureDetector(onTap: () { HapticFeedback.heavyImpact(); _delete(meta); }, child: const Icon(Icons.close, color: Color(0xFFFF4444), size: 20)),
            ])),
          ),
        );
      }),
    );
  }

  Widget _fab(double w, double h, ThemeSet t) {
    return Positioned(right: w * 0.06, bottom: h * 0.04, child: TapTile(onTap: () => _addOrEdit(), child: Container(width: w * 0.13, height: w * 0.13, decoration: BoxDecoration(color: t.d, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.dark, width: 4), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)]), child: Center(child: Icon(Icons.add, color: t.dark, size: 28)))));
  }
}
