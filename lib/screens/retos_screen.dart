import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_state.dart';
import '../supabase_config.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../theme/app_theme.dart';

class RetosScreen extends StatefulWidget {
  final AppMode mode;
  const RetosScreen({super.key, required this.mode});
  @override
  State<RetosScreen> createState() => _RetosScreenState();
}

class _RetosScreenState extends State<RetosScreen> {
  List<Map<String, dynamic>> _retos = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadRetos(); }

  Future<void> _loadRetos() async {
    try {
      final data = await SupabaseConfig.client.from('challenges').select('*')
          .or('couple_id.eq.${AppState.myId ?? ''},couple_id.eq.${AppState.partnerId ?? ''}').order('created_at', ascending: false);
      if (mounted) setState(() { _retos = List<Map<String, dynamic>>.from(data); _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _toggleChallenge(Map<String, dynamic> reto) async {
    final completed = reto['completed'] as bool? ?? false;
    await SupabaseConfig.client.from('challenges').update({'completed': !completed, 'started': true}).eq('id', reto['id']);
    _loadRetos();
  }

  Future<void> _delete(Map<String, dynamic> r) async {
    await SupabaseConfig.client.from('challenges').delete().eq('id', r['id']);
    _loadRetos();
  }

  void _addOrEdit({Map<String, dynamic>? existing}) {
    final ctrl = TextEditingController(text: existing?['title'] ?? '');
    showDialog(context: context, builder: (ctx) {
      final t = getTheme(widget.mode);
      return AlertDialog(
        backgroundColor: t.mid,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: t.d, width: 4)),
        title: Text(existing != null ? 'Editar Reto' : 'Nuevo Reto', style: GoogleFonts.bangers(color: t.light, fontWeight: FontWeight.bold)),
        content: TextField(controller: ctrl, autofocus: true, style: GoogleFonts.bangers(color: t.light), decoration: InputDecoration(hintText: 'Nombre...', hintStyle: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.4)), filled: true, fillColor: t.a.withValues(alpha: 0.25), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.a, width: 2)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.a, width: 2)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: t.d, width: 3)))),
        actions: [
          TapTile(onTap: () => Navigator.pop(ctx), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: t.mid, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.mid, width: 2)), child: Text('Cancelar', style: GoogleFonts.bangers(color: t.light)))),
          TapTile(onTap: () async {
            Navigator.pop(ctx);
            final text = ctrl.text.trim();
            if (text.isEmpty) return;
            if (existing != null) {
              await SupabaseConfig.client.from('challenges').update({'title': text}).eq('id', existing['id']);
            } else {
              await SupabaseConfig.client.from('challenges').insert({'couple_id': AppState.myId, 'title': text});
            }
            _loadRetos();
          }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: t.a, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.a, width: 2)), child: Text(existing != null ? 'OK' : 'Crear', style: GoogleFonts.bangers(color: t.dark, fontWeight: FontWeight.bold)))),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final w = constraints.maxWidth; final h = constraints.maxHeight;
        return SizedBox(width: w, height: h, child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          _header(w, h, t),
          _body(w, h, t),
          _fab(w, h, t),
        ]));
      })),
    );
  }

  Widget _header(double w, double h, ThemeSet t) {
    final barH = h * 0.07;
    return Positioned(left: 0, top: 0, width: w, height: barH, child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(decoration: BoxDecoration(color: t.d, border: Border.all(color: t.d, width: 4), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
        child: Center(child: Text('RETOS', style: GoogleFonts.bangers(color: t.light, fontSize: 20, fontWeight: FontWeight.bold)))),
    ));
  }

  Widget _body(double w, double h, ThemeSet t) {
    final top = h * 0.07 + h * 0.02;
    final pad = w * 0.04;
    if (_loading) return Positioned(left: pad, top: top, width: w - pad * 2, height: h - top, child: Center(child: CircularProgressIndicator(color: t.a)));
    if (_retos.isEmpty) return Positioned(left: pad, top: top, width: w - pad * 2, height: h - top, child: Center(child: Text('Sin retos aun', style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.5), fontSize: 14))));
    return Positioned(left: pad, top: top, width: w - pad * 2, height: h - top - pad,
      child: ListView.builder(itemCount: _retos.length, itemBuilder: (context, i) {
        final reto = _retos[i]; final completed = reto['completed'] as bool? ?? false; final title = reto['title'] as String? ?? '';
        final coupleId = reto['couple_id'] as String? ?? '';
        final isMine = coupleId == AppState.myId;
        final initial = isMine ? (AppState.identity?.substring(0,1).toUpperCase() ?? '?') : (AppState.identity == 'Facu' ? 'R' : 'F');
        return Padding(padding: const EdgeInsets.only(bottom: 8), child: ClipRRect(borderRadius: BorderRadius.circular(18),
          child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: completed ? t.c.withValues(alpha: 0.2) : t.d.withValues(alpha: 0.25), border: Border.all(color: completed ? t.c : t.d, width: 3), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)]),
            child: Row(children: [
              GestureDetector(onTap: () => _toggleChallenge(reto), child: Icon(completed ? Icons.check_circle : Icons.circle_outlined, color: completed ? t.c : t.light, size: 24)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: GoogleFonts.bangers(color: t.light, fontSize: 14, decoration: completed ? TextDecoration.lineThrough : null))),
              Container(width: 20, height: 20, alignment: Alignment.center, decoration: BoxDecoration(color: isMine ? const Color(0xFF00F0FF) : const Color(0xFFFF66C4), borderRadius: BorderRadius.circular(6)), child: Text(initial, style: GoogleFonts.bangers(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))),
              const SizedBox(width: 6),
              GestureDetector(onTap: () => _addOrEdit(existing: reto), child: Icon(Icons.edit, color: t.light.withValues(alpha: 0.5), size: 18)),
              const SizedBox(width: 6),
              GestureDetector(onTap: () { HapticFeedback.heavyImpact(); _delete(reto); }, child: const Icon(Icons.close, color: Color(0xFFFF4444), size: 20)),
            ])),
          ),
        );
      }),
    );
  }

  Widget _fab(double w, double h, ThemeSet t) {
    return Positioned(right: w * 0.06, bottom: h * 0.04, child: TapTile(onTap: () => _addOrEdit(), child: Container(width: w * 0.13, height: w * 0.13, decoration: BoxDecoration(color: t.a, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.dark, width: 4), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)]), child: Center(child: Icon(Icons.add, color: t.dark, size: 28)))));
  }
}
