import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../supabase_config.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import '../theme/app_theme.dart';

const _c = Color(0xFFFF6B00);
const _dark = Color(0xFF1A1A1A);
const _mid = Color(0xFF2A2A2A);
const _black = Color(0xFF000000);

class ChatScreen extends StatefulWidget {
  final String myId; final String partnerId; final String myName; final AppMode mode;
  const ChatScreen({super.key, required this.myId, required this.partnerId, required this.myName, required this.mode});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

enum _PageState { loading, error, empty, data }

class _ChatScreenState extends State<ChatScreen> {
  _PageState _state = _PageState.loading;
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  RealtimeChannel? _channel;
  List<Map<String, dynamic>> _messages = [];
  String _partnerName = '';
  Map<String, dynamic>? _replyTo;
  double _swipeOffset = 0;
  int? _swipingMsgId;

  @override
  void initState() { super.initState(); _loadMessages(); _subscribeRealtime(); _loadPartnerName(); }

  @override
  void dispose() { _channel?.unsubscribe(); _msgCtrl.dispose(); _scrollCtrl.dispose(); _focusNode.dispose(); super.dispose(); }

  Future<void> _loadPartnerName() async {
    if (widget.partnerId.isEmpty) return;
    try {
      final data = await SupabaseConfig.client.from('profiles').select('name').eq('id', widget.partnerId).single();
      if (mounted) setState(() => _partnerName = data['name'] as String? ?? '');
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    try {
      final data = await SupabaseConfig.client.from('messages').select('*')
          .or('from_user.eq.${widget.myId},to_user.eq.${widget.myId}').order('created_at', ascending: false).limit(100);
      if (!mounted) return;
      // La query trae los 100 más NUEVOS (desc); se invierten para mostrar cronológico (viejo arriba, nuevo abajo)
      final newestFirst = List<Map<String, dynamic>>.from(data);
      setState(() { _messages = newestFirst.reversed.toList(); _state = _messages.isEmpty ? _PageState.empty : _PageState.data; });
      _scrollToBottom();
    } catch (_) { if (mounted) setState(() => _state = _PageState.error); }
  }

  void _subscribeRealtime() {
    _channel = SupabaseConfig.client.channel('chat').onPostgresChanges(
      event: PostgresChangeEvent.insert, schema: 'public', table: 'messages',
      callback: (payload) {
        final row = payload.newRecord; final sender = row['from_user'] as String? ?? ''; final receiver = row['to_user'] as String? ?? '';
        if (sender == widget.myId || receiver == widget.myId) {
          if (mounted) { setState(() { _messages.add(row); _state = _PageState.data; }); _scrollToBottom(); }
        }
      },
    ).onPostgresChanges(
      event: PostgresChangeEvent.update, schema: 'public', table: 'messages',
      callback: (payload) {
        final row = payload.newRecord; final msgId = row['id']; final idx = _messages.indexWhere((m) => m['id'] == msgId);
        if (idx >= 0 && mounted) setState(() => _messages[idx] = row);
      },
    ).subscribe();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.heavyImpact();
    try {
      final msg = <String, dynamic>{'from_user': widget.myId, 'to_user': widget.partnerId, 'content': text};
      if (_replyTo != null) {
        final rid = _replyTo!['id'];
        if (rid != null) {
          msg['reply_to_id'] = rid is int ? rid : int.tryParse(rid.toString());
        }
        msg['reply_content'] = _replyTo!['content']?.toString() ?? '';
      }
      await SupabaseConfig.client.from('messages').insert(msg);
      _msgCtrl.clear();
      setState(() => _replyTo = null);
      _focusNode.unfocus();
    } catch (e) {
      debugPrint('Chat send error: $e');
    }
  }

  DateTime? _parseDt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: _dark, body: SafeArea(child: _buildContent()));
  }

  Widget _buildContent() {
    return ResponsiveWrapper(builder: (context, w, h) {
      return SizedBox(width: w, height: h, child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
        _header(w, h), _msgArea(w, h), _inputArea(w, h),
      ]));
    });
  }

  Widget _header(double w, double h) {
    final barH = h * 0.07;
    return Positioned(left: 0, top: 0, width: w, height: barH, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, border: Border.all(color: _c, width: 4), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)]),
        child: Row(children: [
          Expanded(child: Center(child: Text(_partnerName.isNotEmpty ? _partnerName : 'CHAT', style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 18, color: _dark)))),
        ]))));
  }

  Widget _msgArea(double w, double h) {
    final top = h * 0.08; final areaH = h * 0.78;
    final t = getTheme(widget.mode);
    return Positioned(left: w * 0.025, top: top, width: w * 0.95, height: areaH, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _mid, border: Border.all(color: _c, width: 4), borderRadius: BorderRadius.circular(18)),
      child: switch (_state) {
        _PageState.loading => Center(child: CircularProgressIndicator(color: _c, strokeWidth: 3)),
        _PageState.error => _errorContent(),
        _PageState.empty => _emptyContent(),
        _PageState.data => ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(10), itemCount: _messages.length, itemBuilder: (ctx, i) {
          final m = _messages[i]; final isMine = (m['from_user'] as String?) == widget.myId; final msgId = m['id']; final isReplying = _replyTo?['id'] == msgId;
          return GestureDetector(
            onHorizontalDragUpdate: (d) { if (!isMine) setState(() { _swipingMsgId = msgId; _swipeOffset = (d.delta.dx).clamp(0, 80); }); },
            onHorizontalDragEnd: (d) {
              if (_swipeOffset > 40) { HapticFeedback.mediumImpact(); setState(() { _replyTo = m; _swipeOffset = 0; _swipingMsgId = null; }); _focusNode.requestFocus(); }
              else { setState(() { _swipeOffset = 0; _swipingMsgId = null; }); }
            },
            child: Transform.translate(offset: Offset(_swipingMsgId == msgId ? _swipeOffset : (isReplying ? 24 : 0), 0), child: _msgBlock(m, isMine, t)),
          );
        }),
      },
    )));
  }

  Widget _msgBlock(Map<String, dynamic> m, bool isMine, ThemeSet t) {
    final content = m['content']?.toString() ?? '';
    final raw = _parseDt(m['created_at']);
    final timeStr = raw != null ? '${raw.hour.toString().padLeft(2,'0')}:${raw.minute.toString().padLeft(2,'0')}' : '';
    final blockColor = isMine ? t.a : t.e; final borderColor = blockColor;
    final textColor = isMine ? t.dark : t.light;
    final subColor = isMine ? t.dark.withValues(alpha: 0.6) : Colors.white38;
    final read = m['read'] == true; final starred = m['starred'] == true;
    final replyContent = m['reply_content']?.toString();
    return Padding(
      padding: EdgeInsets.only(bottom: 8, left: isMine ? 60 : 4, right: isMine ? 4 : 60),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: blockColor, border: Border.all(color: borderColor, width: 3), borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (replyContent != null && replyContent.isNotEmpty)
            Container(margin: const EdgeInsets.only(bottom: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white24, width: 1)), child: Text(replyContent, style: GoogleFonts.bangers(fontSize: 10, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(content, style: GoogleFonts.bangers(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(timeStr, style: GoogleFonts.bangers(fontSize: 10, color: subColor)),
            if (isMine) ...[const SizedBox(width: 4), Icon(read ? Icons.done_all : Icons.done, size: 14, color: subColor)],
            if (starred) ...[const SizedBox(width: 4), Icon(Icons.star, size: 12, color: t.d)],
          ]),
        ]),
      )),
    );
  }

  Widget _errorContent() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.cloud_off, color: _c.withValues(alpha: 0.5), size: 60),
    const SizedBox(height: 10),
    GestureDetector(onTap: () { HapticFeedback.heavyImpact(); _loadMessages(); }, child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _c, borderRadius: BorderRadius.circular(14), border: Border.all(color: _c, width: 3)), child: Icon(Icons.refresh, color: _dark, size: 28))),
  ]));

  Widget _emptyContent() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.chat_bubble_outline, color: _c.withValues(alpha: 0.5), size: 60), const SizedBox(height: 8),
    Text('Inicia la conversacion', style: GoogleFonts.bangers(color: _c.withValues(alpha: 0.5), fontSize: 16)),
  ]));

  Widget _inputArea(double w, double h) {
    final hasReply = _replyTo != null; final top = hasReply ? h * 0.82 : 0.87; final areaH = hasReply ? h * 0.14 : 0.09;
    return Positioned(left: w * 0.05, top: h * top, width: w * 0.90, height: h * areaH, child: Column(children: [
      if (hasReply)
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), margin: const EdgeInsets.only(bottom: 4), decoration: BoxDecoration(color: _c, border: Border.all(color: _c, width: 2), borderRadius: BorderRadius.circular(18)), child: Row(children: [
          Icon(Icons.reply, color: _dark, size: 16), const SizedBox(width: 8),
          Expanded(child: Text(_replyTo!['content']?.toString() ?? '', style: GoogleFonts.bangers(color: _dark, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
          GestureDetector(onTap: () => setState(() => _replyTo = null), child: Icon(Icons.close, color: _dark, size: 18)),
        ])),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(color: _c, border: Border.all(color: _c, width: 4), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _msgCtrl, focusNode: _focusNode, style: GoogleFonts.bangers(color: _dark, fontSize: 14), decoration: const InputDecoration(hintText: 'Mensaje...', hintStyle: TextStyle(color: Color(0xFF220000)), border: InputBorder.none), onSubmitted: (_) => _sendMessage())),
          GestureDetector(onTap: _sendMessage, child: Container(width: 40, height: 40, margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(12), border: Border.all(color: _dark, width: 2)), child: const Icon(Icons.send, color: Color(0xFFFF6B00), size: 18))),
        ])))),
    ]));
  }
}
