import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../supabase_config.dart';
import '../app_state.dart';
import '../widgets/tap_tile.dart';
import '../widgets/concrete_painter.dart';
import '../theme/app_theme.dart';

const _cInbox = Color(0xFFFF1493);
const _cSent = Color(0xFF00F0FF);
const _dark = Color(0xFF1A1A1A);
const _mid = Color(0xFF2A2A2A);
const _black = Color(0xFF000000);

class LettersScreen extends StatefulWidget {
  final AppMode mode;
  final String name;
  const LettersScreen({super.key, required this.mode, required this.name});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

enum _PageState { loading, error, empty, data }
enum _Tab { inbox, sent }

class _LettersScreenState extends State<LettersScreen> {
  _PageState _state = _PageState.loading;
  _Tab _tab = _Tab.inbox;
  List<Map<String, dynamic>> _inboxLetters = const [];
  List<Map<String, dynamic>> _sentLetters = const [];
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _composing = false;

  @override
  void initState() {
    super.initState();
    _loadLetters();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    setState(() => _state = _PageState.loading);
    try {
      final results = await Future.wait([
        _loadInbox().catchError((_) => <Map<String, dynamic>>[]),
        _loadSent().catchError((_) => <Map<String, dynamic>>[]),
      ]);
      if (!mounted) return;
      _inboxLetters = results[0];
      _sentLetters = results[1];
      final current = _tab == _Tab.inbox ? _inboxLetters : _sentLetters;
      setState(() => _state = current.isEmpty ? _PageState.empty : _PageState.data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _state = _PageState.error);
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
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _composing = false);
      _loadLetters();
    } catch (e) {
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar la carta', style: TextStyle(fontFamily: 'monospace')), backgroundColor: Colors.red),
      ); }
    }
  }

  void _toggleTab(_Tab t) {
    HapticFeedback.heavyImpact();
    setState(() => _tab = t);
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Color get _activeColor => _tab == _Tab.inbox ? _cInbox : _cSent;

  void _showLetter(String title, String body, String author, String date) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _dark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _activeColor, width: 4)),
        title: Text(title, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: _activeColor, fontSize: 18)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(body, style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14)),
          const SizedBox(height: 12),
          Text(_formatDate(date), style: const TextStyle(fontFamily: 'monospace', color: Colors.white38, fontSize: 11)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Icon(Icons.close, color: _activeColor, size: 28),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (_composing) return _composeView(w, h);
        return SizedBox(width: w, height: h, child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
            _header(w, h),
            _tabBlocks(w, h),
            _lettersArea(w, h),
          ],
        ));
      },
    );
  }

  Widget _header(double w, double h) {
    final barH = h * 0.07;
    return Positioned(left: 0, top: 0, width: w, height: barH, child: ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _activeColor,
          border: Border.all(color: _activeColor, width: 4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(children: [
          TapTile(
            onTap: () { HapticFeedback.heavyImpact(); Navigator.of(context).pop(); },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
            ),
          ),
          const Spacer(),
          TapTile(
            onTap: () { HapticFeedback.heavyImpact(); setState(() => _composing = true); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _black, width: 3),
              ),
              child: Icon(Icons.create, color: _activeColor, size: 22),
            ),
          ),
        ]),
      ),
    ));
  }

  Widget _tabBlocks(double w, double h) {
    final top = h * 0.08;
    final tabW = w * 0.38;
    return Stack(children: [
      Positioned(left: w * 0.08, top: top, width: tabW, height: h * 0.05, child: TapTile(
          onTap: () => _toggleTab(_Tab.inbox),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: _tab == _Tab.inbox ? _cInbox : _mid,
                border: Border.all(color: _cInbox, width: _tab == _Tab.inbox ? 4 : 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.inbox, color: _tab == _Tab.inbox ? Colors.white : _cInbox, size: 20),
                const SizedBox(width: 6),
                Text('Recibidas', style: TextStyle(
                  fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold,
                  color: _tab == _Tab.inbox ? Colors.white : _cInbox,
                )),
              ]),
            ),
          ),
        )),
      Positioned(left: w * 0.52, top: top, width: tabW, height: h * 0.05, child: TapTile(
          onTap: () => _toggleTab(_Tab.sent),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: _tab == _Tab.sent ? _cSent : _mid,
                border: Border.all(color: _cSent, width: _tab == _Tab.sent ? 4 : 3),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.send, color: _tab == _Tab.sent ? _black : _cSent, size: 20),
                const SizedBox(width: 6),
                Text('Enviadas', style: TextStyle(
                  fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold,
                  color: _tab == _Tab.sent ? _black : _cSent,
                )),
              ]),
            ),
          ),
        )),
    ]);
  }

  Widget _lettersArea(double w, double h) {
    final top = h * 0.145;
    final letters = _tab == _Tab.inbox ? _inboxLetters : _sentLetters;

    return Positioned(left: w * 0.05, top: top, width: w * 0.90, height: h - top - h * 0.03, child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: _mid,
            border: Border.all(color: _activeColor, width: 4),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
          ),
          child: switch (_state) {
            _PageState.loading => Center(
              child: Icon(Icons.hourglass_top, color: _activeColor, size: 60),
            ),
            _PageState.error => _errorContent(),
            _PageState.empty => _emptyContent(),
            _PageState.data => ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: letters.length,
              itemBuilder: (ctx, i) => _letterCard(letters[i]),
            ),
          },
        ),
      ),
    );
  }

  Widget _letterCard(Map<String, dynamic> letter) {
    final title = letter['title']?.toString() ?? '';
    final body = letter['content']?.toString() ?? '';
    final date = letter['created_at']?.toString() ?? '';
    final author = letter['author_name']?.toString() ?? '';
    return TapTile(
        onTap: () { HapticFeedback.heavyImpact(); _showLetter(title, body, author, date); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _black,
              border: Border.all(color: _activeColor, width: 3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
            ),
            child: Row(children: [
              Icon(Icons.mail, color: _activeColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(
                    fontFamily: 'monospace', color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold,
                  )),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(body.length > 60 ? '${body.substring(0, 60)}...' : body, style: const TextStyle(
                      fontFamily: 'monospace', color: Colors.white54, fontSize: 11,
                    )),
                  ],
                ]),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: _activeColor.withValues(alpha: 0.5), size: 20),
            ]),
          ),
        ),
      );
  }

  Widget _errorContent() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off, color: _activeColor, size: 60),
      const SizedBox(height: 10),
      TapTile(
        onTap: () { HapticFeedback.heavyImpact(); _loadLetters(); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _activeColor,
              border: Border.all(color: _black, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text('Reintentar', style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    ]));
  }

  Widget _emptyContent() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.email_outlined, color: _activeColor, size: 60),
      const SizedBox(height: 14),
      TapTile(
        onTap: () { HapticFeedback.heavyImpact(); setState(() => _composing = true); },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _activeColor,
              border: Border.all(color: _black, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.create, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text('Escribir carta', style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          ),
        ),
      ),
    ]));
  }

  Widget _composeView(double w, double h) {
    return SizedBox(width: w, height: h, child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
        Positioned(left: 0, top: 0, width: w, height: h * 0.07, child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _activeColor,
              border: Border.all(color: _activeColor, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Row(children: [
              TapTile(
                onTap: () { HapticFeedback.heavyImpact(); setState(() => _composing = false); },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close, color: Colors.white, size: 28),
                ),
              ),
              const Expanded(child: Center(
                child: Text('NUEVA CARTA', style: TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              )),
              TapTile(
                onTap: _sendLetter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.send, color: Colors.white, size: 28),
                ),
              ),
            ]),
          ),
        )),
        Positioned(left: w * 0.05, top: h * 0.09, width: w * 0.90, height: h * 0.10, child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _mid,
              border: Border.all(color: _activeColor, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Row(children: [
              const Padding(padding: EdgeInsets.only(left: 14), child: Icon(Icons.title, color: _cInbox, size: 24)),
              Expanded(child: TextField(
                controller: _titleCtrl,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  border: InputBorder.none, contentPadding: EdgeInsets.all(14),
                ),
              )),
            ]),
          ),
        )),
        Positioned(left: w * 0.05, top: h * 0.21, width: w * 0.90, height: h * 0.70, child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: _mid,
              border: Border.all(color: _activeColor, width: 4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(left: 14, top: 14), child: Icon(Icons.edit_note, color: _cInbox, size: 24)),
              Expanded(child: TextField(
                controller: _bodyCtrl,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  border: InputBorder.none, contentPadding: EdgeInsets.all(14),
                ),
              )),
            ]),
          ),
        )),
      ],
    ));
  }
}
