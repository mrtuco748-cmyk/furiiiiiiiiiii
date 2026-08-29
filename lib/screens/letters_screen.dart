import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../supabase_config.dart';
import '../services/local_cache.dart';
import '../app_state.dart';
import '../models/letter.dart';
import '../theme/app_theme.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/loca_screen.dart';
import '../widgets/tap_tile.dart';
import '../widgets/brutal_style.dart';
import '../widgets/app_feedback.dart';

const _cInbox = Color(0xFFFF1493);
const _cRead = Color(0xFF7A3E5A);
const _cSealed = Color(0xFFFFB300);
const _cSent = Color(0xFF00F0FF);
const _dark = Color(0xFF1A1A1A);
const _mid = Color(0xFF2A2A2A);
const _black = Color(0xFF000000);
const _gold = Color(0xFFFFD700);

/// Paleta variada para bloques de cartas en el mosaico.
const _letterPalette = [
  Color(0xFFFF6B00), // naranja
  Color(0xFF00D4FF), // cian
  Color(0xFF9D00FF), // violeta
  Color(0xFFFF1493), // rosa
  Color(0xFFFFDE59), // amarillo
  Color(0xFFFF00FF), // fucsia
  Color(0xFF7000FF), // morado
  Color(0xFFFF5757), // rojo
];

class LettersScreen extends StatefulWidget {
  final AppMode mode;
  final String name;
  const LettersScreen({super.key, required this.mode, required this.name});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

enum _PageState { loading, error, data }

/// Cartas estilo "Nosotros": UN bloque-icono por cada carta recibida en el
/// mosaico loco, con icono de leída/no leída (visto) y cerraduras para las
/// selladas. Apretar una carta abre SÓLO esa carta. Tiles extra: Enviadas
/// (panel con las enviadas) y Escribir (composición completa).
class _LettersScreenState extends State<LettersScreen> {
  _PageState _state = _PageState.loading;
  List<Map<String, dynamic>> _inboxLetters = const [];
  List<Map<String, dynamic>> _sentLetters = const [];
  final Set<int> _readLocal = {};
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _composing = false;
  DateTime? _scheduledOpen;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadReadLocal();
    _loadLetters();
    _subscribe();
  }

  Future<void> _loadReadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs
          .getKeys()
          .where((k) => k.startsWith('readLetter-'))
          .map((k) => int.tryParse(k.replaceFirst('readLetter-', '')))
          .whereType<int>()
          .where((v) => v > 0)
          .toList();
      if (!mounted) return;
      setState(() => _readLocal.addAll(ids));
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }

  void _scheduleReload() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _loadLetters();
    });
  }

  void _subscribe() {
    _channel = SupabaseConfig.client
        .channel('cartas_loca_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'letters',
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  Future<void> _loadLetters() async {
    // Mostrar cache local al instante (sin "carga"); luego sync con Supabase.
    if (_inboxLetters.isEmpty && _sentLetters.isEmpty) {
      try {
        final inbox = await LocalCache.getList('cache_letters_inbox');
        final sent = await LocalCache.getList('cache_letters_sent');
        if (mounted && (inbox != null || sent != null)) {
          setState(() {
            if (inbox != null) _inboxLetters = inbox;
            if (sent != null) _sentLetters = sent;
            _state = _PageState.data;
          });
        }
      } catch (_) {}
    }
    try {
      final results = await Future.wait([_loadInbox(), _loadSent()]);
      if (!mounted) return;
      _inboxLetters = results[0];
      _sentLetters = results[1];
      setState(() => _state = _PageState.data);
      // El cache SOLO se actualiza con datos reales de Supabase: si el fetch
      // falla (sin red), no pisar el cache bueno con listas vacías.
      await LocalCache.setList('cache_letters_inbox', _inboxLetters);
      await LocalCache.setList('cache_letters_sent', _sentLetters);
    } catch (e) {
      if (!mounted) return;
      // Sin datos que mostrar (ni cache) → error visible. Con cache visible
      // se mantienen los datos y no se muestra una bandeja vacía falsa.
      if (_inboxLetters.isEmpty && _sentLetters.isEmpty) {
        setState(() => _state = _PageState.error);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadInbox() async {
    final data = await SupabaseConfig.client
        .from('letters')
        .select('*')
        .eq('to_user', AppState.myId ?? '')
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> _loadSent() async {
    final data = await SupabaseConfig.client
        .from('letters')
        .select('*')
        .eq('from_user', AppState.myId ?? '')
        .order('created_at', ascending: false)
        .limit(20);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _sendLetter() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    HapticFeedback.heavyImpact();
    try {
      await SupabaseConfig.client.from('letters').insert({
        'from_user': AppState.myId,
        'to_user': AppState.partnerId,
        'title': title,
        'content': body,
        if (_scheduledOpen != null)
          'scheduled_open': _scheduledOpen!.toUtc().toIso8601String(),
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() {
        _composing = false;
        _scheduledOpen = null;
      });
      _loadLetters();
      if (mounted) AppFeedback.saved(context, 'Carta enviada');
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo enviar la carta', style: GoogleFonts.bangers(color: Colors.white)), backgroundColor: Color(0xFFCC0000)),
      ); }
    }
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  DateTime? _scheduledOpenOf(Map<String, dynamic> letter) {
    final raw = letter['scheduled_open'];
    return raw == null ? null : DateTime.tryParse(raw.toString());
  }

  bool _isSealed(Map<String, dynamic> letter, {required bool incoming}) =>
      Letter.isSealed(
        scheduledOpen: _scheduledOpenOf(letter),
        isIncoming: incoming,
      );

  bool _isReadByMe(Map<String, dynamic> letter) {
    final id = (letter['id'] as num?)?.toInt();
    if (id != null && _readLocal.contains(id)) return true;
    final seen = (letter['seen_by'] as List?)?.cast<String>() ?? <String>[];
    return seen.contains(AppState.myId);
  }

  /// Marca una carta como "vista" de forma LOCAL (SharedPreferences), para que
  /// el icono refleje la leída al instante sin depender de la vista en la nube.
  Future<void> _markReadLocal(int id) async {
    if (id <= 0 || _readLocal.contains(id)) return;
    setState(() => _readLocal.add(id));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('readLetter-$id', true);
    } catch (_) {}
  }

void _showLetter(String title, String body, String date, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: color, width: 4)),
        title: Text(title, style: GoogleFonts.bangers(fontWeight: FontWeight.w900, color: color, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(body, style: GoogleFonts.bangers(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400)),
          const SizedBox(height: 12),
          Text(_formatDate(date), style: GoogleFonts.bangers(color: Colors.white38, fontSize: 11)),
        ]),
        actions: [
          TapTile(
            onTap: () => Navigator.of(ctx).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _dark,
                border: Border.all(color: _dark, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close, color: color, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishEditLetter(int id, String newTitle, String newBody) async {
    if (newTitle.isEmpty || newBody.isEmpty) return;
    try {
      await SupabaseConfig.client.from('letters').update({
        'title': newTitle,
        'content': newBody,
        'is_edited': true,
      }).eq('id', id);
      _loadLetters();
      if (mounted) AppFeedback.saved(context, 'Carta editada');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar la edición', style: GoogleFonts.bangers(color: Colors.white)), backgroundColor: Color(0xFFCC0000)),
        );
      }
    }
  }

  Widget _showSentLetterEditor(Map<String, dynamic> letter) {
    final titleCtrl = TextEditingController(text: letter['title']?.toString() ?? '');
    final bodyCtrl = TextEditingController(text: letter['content']?.toString() ?? '');
    return AlertDialog(
      backgroundColor: _dark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _cSent, width: 4)),
      title: Text('Editar carta', style: GoogleFonts.bangers(color: _cSent, fontSize: 18)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: titleCtrl,
          style: GoogleFonts.bangers(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Título',
            hintStyle: GoogleFonts.bangers(color: Colors.white38),
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: bodyCtrl,
          style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Cuerpo',
            hintStyle: GoogleFonts.bangers(color: Colors.white38),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        Text('Fecha: ${_formatDate(letter['created_at']?.toString() ?? '')}', style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11)),
      ]),
      actions: [
        TapTile(
          onTap: () async {
            final newTitle = titleCtrl.text.trim();
            final newBody = bodyCtrl.text.trim();
            if (newTitle.isEmpty || newBody.isEmpty) return;
            HapticFeedback.heavyImpact();
            await _finishEditLetter(letter['id'], newTitle, newBody);
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _cSent,
              border: Border.all(color: _cSent, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('Guardar', style: GoogleFonts.bangers(color: Colors.white, fontSize: 16)),
          ),
        ),
        TapTile(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _dark,
              border: Border.all(color: _dark, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.close, color: _cSent, size: 28),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_composing) return _composeView();
    final t = getTheme(widget.mode);
    // Mosaico: solo las 6 recibidas más recientes (sin importar la leída).
    // El resto se ve desde el botón "historial".
    final shownInbox = _inboxLetters.take(6).toList();
    final entries = <LocaEntry>[
      if (_state == _PageState.error)
        LocaEntry(
          icon: Icons.cloud_off,
          color: const Color(0xFFFF4444),
          iconColor: Colors.white,
          label: 'reintentar',
          onTap: () { HapticFeedback.heavyImpact(); _loadLetters(); },
          isAction: true,
        ),
      for (var i = 0; i < shownInbox.length; i++)
        LocaEntry(
          icon: _letterIcon(shownInbox[i]),
          color: _letterColor(shownInbox[i], index: i),
          iconColor: _letterIconColor(shownInbox[i]),
          label: shownInbox[i]['title']?.toString() ?? '',
          childBuilder: (_) => _letterChild(shownInbox[i]),
          panel: i,
        ),
      LocaEntry(
        icon: Icons.history,
        color: _cSent,
        iconColor: _black,
        label: 'historial',
        panel: shownInbox.length,
        isAction: true,
      ),
      LocaEntry(
        icon: Icons.create,
        color: _gold,
        iconColor: _black,
        label: 'escribir',
        onTap: () { HapticFeedback.heavyImpact(); setState(() => _composing = true); },
        isAction: true,
      ),
    ];
    return LocaScreen(
      seed: 13,
      theme: t,
      entries: entries,
      panels: [
        for (var i = 0; i < shownInbox.length; i++)
          (_, close) => _letterPanel(close, shownInbox[i]),
        (_, close) => _historyPanel(close),
      ],
    );
  }

  IconData _letterIcon(Map<String, dynamic> letter) {
    final sealed = _isSealed(letter, incoming: true);
    if (sealed) return Icons.mail_lock;
    return _isReadByMe(letter) ? Icons.mark_email_read : Icons.markunread;
  }

  /// Bloque de carta en el mosaico: icono de estado + título + preview del
  /// contenido (para las no selladas). Se muestra ya sin animación de entrada.
  Widget _letterChild(Map<String, dynamic> letter) {
    final sealed = _isSealed(letter, incoming: true);
    final title = letter['title']?.toString() ?? '';
    final body = letter['content']?.toString() ?? '';
    final color = _letterIconColor(letter);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(mainAxisSize: MainAxisSize.max, children: [
        Expanded(child: BrutalStyle.fillIcon(_letterIcon(letter), color)),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.bangers(color: color, fontSize: 21, height: 1.1),
        ),
        if (!sealed && body.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            body.length > 40 ? '${body.substring(0, 40)}…' : body,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 11, height: 1.1),
          ),
        ],
      ]),
    );
  }

  Color _letterColor(Map<String, dynamic> letter, {required int index}) {
    final sealed = _isSealed(letter, incoming: true);
    if (sealed) return _cSealed;
    return _letterPalette[index % _letterPalette.length];
  }

  Color _letterIconColor(Map<String, dynamic> letter) {
    if (_isSealed(letter, incoming: true)) return _black;
    return Colors.white;
  }

  Widget _letterPanel(VoidCallback close, Map<String, dynamic> letter) {
    if (!_isSealed(letter, incoming: true)) {
      Future.microtask(() {
        if (mounted) _markReadLocal((letter['id'] as num?)?.toInt() ?? -1);
      });
    }
    final title = letter['title']?.toString() ?? '';
    final body = letter['content']?.toString() ?? '';
    final date = letter['created_at']?.toString() ?? '';
    final sealed = _isSealed(letter, incoming: true);
    final openAt = _scheduledOpenOf(letter);
    final color = sealed ? _cSealed : _cInbox;
    return LocaScreen.panel(color: _mid, borderColor: color, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Row(children: [
          Icon(sealed ? Icons.mail_lock : Icons.mark_email_read, color: color, size: 22),
          const Spacer(),
          LocaScreen.closeIcon(close, color, Icons.close),
        ]),
      ),
      Expanded(
        child: sealed
            ? Center(child: Padding(padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.mail_lock, color: _cSealed, size: 56),
                  const SizedBox(height: 12),
                  Text(title, textAlign: TextAlign.center,
                    style: GoogleFonts.bangers(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  if (openAt != null) ...[
                    const SizedBox(height: 8),
                    Text('Se podrá abrir el ${openAt.day}/${openAt.month}/${openAt.year}',
                      style: GoogleFonts.bangers(color: _cSealed, fontSize: 13)),
                  ],
                ])))
            : Center(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: GoogleFonts.bangers(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  Text(body, style: GoogleFonts.bangers(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 16),
                  Text(_formatDate(date), style: GoogleFonts.bangers(color: Colors.white38, fontSize: 11)),
                ])))),
      ),
      const SizedBox(height: 10),
    ]));
  }

  Widget _historyPanel(VoidCallback close) {
    return LocaScreen.panel(color: _mid, borderColor: _cSent, child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
        child: Row(children: [
          Icon(Icons.history, color: _cSent, size: 22),
          const Spacer(),
          LocaScreen.closeIcon(close, _cSent, Icons.close),
        ]),
      ),
      const SizedBox(height: 4),
      Expanded(child: _historyBody()),
    ]));
  }

  Widget _historyBody() {
    if (_state == _PageState.loading) {
      return const Center(child: Icon(Icons.hourglass_top, color: _cSent, size: 60));
    }
    if (_state == _PageState.error) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, color: _cSent, size: 60),
        const SizedBox(height: 12),
        TapTile(
          onTap: () { HapticFeedback.heavyImpact(); _loadLetters(); },
          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _cSent, borderRadius: BorderRadius.circular(10), border: Border.all(color: _cSent, width: 2)), child: const Icon(Icons.refresh, color: Colors.white, size: 24)),
        ),
      ]));
    }
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _sectionHeader('RECIBIDAS', _inboxLetters.length),
        if (_inboxLetters.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: Icon(Icons.markunread, color: Color(0x66FFFFFF), size: 48)))
        else
          ..._inboxLetters.map((l) => _historyCard(l, incoming: true)),
        const SizedBox(height: 12),
        _sectionHeader('ENVIADAS', _sentLetters.length),
        if (_sentLetters.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: Icon(Icons.send_outlined, color: Color(0x66FFFFFF), size: 48)))
        else
          ..._sentLetters.map((l) => _historyCard(l, incoming: false)),
      ],
    );
  }

  Widget _sectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(children: [
        Icon(Icons.label, color: _cSent.withValues(alpha: 0.7), size: 14),
        const SizedBox(width: 6),
        Text('$label  ·  $count', style: GoogleFonts.bangers(color: _cSent, fontSize: 13)),
      ]),
    );
  }

  Widget _historyCard(Map<String, dynamic> letter, {required bool incoming}) {
    final title = letter['title']?.toString() ?? '';
    final body = letter['content']?.toString() ?? '';
    final date = letter['created_at']?.toString() ?? '';
    final sealed = incoming && _isSealed(letter, incoming: true);
    final read = incoming && _isReadByMe(letter);
    final color = incoming ? (sealed ? _cSealed : (read ? _cRead : _cInbox)) : _cSent;
    return TapTile(
      onTap: () {
        HapticFeedback.heavyImpact();
        final isMySent = !incoming && letter['from_user'] == AppState.myId;
        if (sealed) {
          _showLetter(title, '🔒 Se podrá abrir más adelante', date, _cSealed);
        } else if (isMySent) {
          _showSentLetterEditor(letter);
        } else {
          if (incoming) _markReadLocal((letter['id'] as num?)?.toInt() ?? -1);
          _showLetter(title, body, date, color);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _dark,
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
          ),
          child: Row(children: [
            Icon(incoming ? (sealed ? Icons.mail_lock : (read ? Icons.mark_email_read : Icons.markunread)) : Icons.mail, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.bangers(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(body.length > 60 ? '${body.substring(0, 60)}...' : body, style: GoogleFonts.bangers(color: Colors.white54, fontSize: 11)),
                ],
              ]),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 20),
          ]),
        ),
      ),
    );
  }

  Widget _composeView() {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final color = _cInbox;
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(child: SizedBox(width: w, height: h, child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          Positioned(left: 0, top: 0, width: w, height: h * 0.07, child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: color, width: 4),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
              ),
              child: Row(children: [
                TapTile(
                  onTap: () { HapticFeedback.heavyImpact(); setState(() => _composing = false); },
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.close, color: Colors.white, size: 28)),
                ),
                const Spacer(),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.edit_note, color: Colors.white, size: 26)),
                TapTile(
                  onTap: _sendLetter,
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.send, color: Colors.white, size: 28)),
                ),
              ]),
            ),
          )),
          Positioned(left: w * 0.05, top: h * 0.09, width: w * 0.90, height: h * 0.10, child: _fieldShell(color, Row(children: [
            const Padding(padding: EdgeInsets.only(left: 14), child: Icon(Icons.title, color: _cInbox, size: 24)),
            Expanded(child: TextField(
              controller: _titleCtrl,
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
            )),
          ]))),
          Positioned(left: w * 0.05, top: h * 0.21, width: w * 0.90, height: h * 0.63, child: _fieldShell(color, Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(left: 14, top: 14), child: Icon(Icons.edit_note, color: _cInbox, size: 24)),
            Expanded(child: TextField(
              controller: _bodyCtrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
            )),
          ]))),
          Positioned(left: w * 0.05, top: h * 0.86, width: w * 0.90, height: h * 0.07, child: _fieldShell(color, Row(children: [
            Padding(padding: const EdgeInsets.only(left: 14), child: Icon(Icons.schedule, color: color, size: 24)),
            Expanded(
              child: _scheduledOpen == null
                  ? Text('Programar apertura (opcional)', style: GoogleFonts.bangers(color: Colors.white54, fontSize: 13))
                  : Text('Se abre el ${_scheduledOpen!.day}/${_scheduledOpen!.month}/${_scheduledOpen!.year}',
                      style: GoogleFonts.bangers(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.w900)),
            ),
            TapTile(
              onTap: _pickSchedule,
              child: Padding(padding: const EdgeInsets.all(10), child: Icon(Icons.edit_calendar, color: color, size: 22)),
            ),
            if (_scheduledOpen != null)
              TapTile(
                onTap: () => setState(() => _scheduledOpen = null),
                child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.close, color: Colors.white, size: 22)),
              ),
          ]))),
        ],
      ))),
    );
  }

  Widget _fieldShell(Color color, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _mid,
          border: Border.all(color: color, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: child,
      ),
    );
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledOpen ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: '¿Cuándo se podrá abrir?',
    );
    if (picked != null && mounted) {
      setState(() => _scheduledOpen = DateTime(picked.year, picked.month, picked.day));
    }
  }
}