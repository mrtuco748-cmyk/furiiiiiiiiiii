import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../services/chat_media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/tap_tile.dart';
import 'chat/chat_style.dart';
import 'chat/widgets/chat_react_chip.dart';
import 'chat/widgets/chat_swipe_to_reply.dart';
import 'chat/widgets/chat_message_tile.dart';

/// Aliases de la paleta compartida del chat (ChatStyle).
const _c = ChatStyle.primary;
const _bg = ChatStyle.bg;
const _panel = ChatStyle.panel;
const _inputBg = ChatStyle.inputBg;
const _darkText = ChatStyle.darkText;
const _errorBg = ChatStyle.errorBg;

class ChatScreen extends StatelessWidget {
  final String myId;
  final String partnerId;
  final String myName;
  final AppMode mode;

  const ChatScreen({
    super.key,
    required this.myId,
    required this.partnerId,
    required this.myName,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatProvider(myId: myId, partnerId: partnerId)..init(),
      child: _ChatView(mode: mode),
    );
  }
}

class _ChatView extends StatefulWidget {
  final AppMode mode;
  const _ChatView({required this.mode});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();
  bool _recording = false;
  DateTime? _recordStarted;
  Timer? _recordTicker;
  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();
    // Scroll infinito hacia arriba: al llegar al tope (mensajes más viejos),
    // cargamos una página anterior. La lista es reverse:true (nuevo abajo),
    // así el paginado ancla la vista sin saltar.
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 40) {
      context.read<ChatProvider>().loadOlderMessages();
    }
  }

  @override
  void dispose() {
    _recordTicker?.cancel();
    _recorder.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendText() async {
    final text = _msgCtrl.text;
    if (text.trim().isEmpty) return;
    HapticFeedback.heavyImpact();
    final chat = context.read<ChatProvider>();
    _msgCtrl.clear();
    chat.notifyTyping(false);
    try {
      await chat.sendText(text);
      _scrollToBottom();
      _focusNode.unfocus();
    } catch (e) {
      developer.log('sendText fallo: $e');
    }
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    await _sendPicked(
      path: file.path,
      name: file.name,
      mime: file.mimeType ?? 'image/jpeg',
      type: 'image',
    );
  }

  Future<void> _pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    await _sendPicked(
      path: file.path,
      name: file.name,
      mime: file.mimeType ?? 'video/mp4',
      type: 'video',
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final f = result.files.single;
    if (f.path == null) return;
    final type = ChatMediaService.guessMessageType(
      mime: f.extension == 'gif' ? 'image/gif' : null,
      fileName: f.name,
    );
    await _sendPicked(
      path: f.path!,
      name: f.name,
      mime: f.extension != null ? _mimeFromExt(f.extension!) : null,
      type: type,
      size: f.size,
    );
  }

  String? _mimeFromExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
        return 'audio/mp4';
      case 'wav':
        return 'audio/wav';
      case 'pdf':
        return 'application/pdf';
      default:
        return null;
    }
  }

  Future<void> _sendPicked({
    required String path,
    required String name,
    required String type,
    String? mime,
    int? size,
  }) async {
    HapticFeedback.mediumImpact();
    final chat = context.read<ChatProvider>();
    try {
      await chat.sendMedia(
        localPath: path,
        messageType: type,
        fileName: name,
        mimeType: mime,
        size: size,
      );
      _scrollToBottom();
    } catch (e) {
      developer.log('sendMedia fallo: $e');
    }
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      _recordTicker?.cancel();
      setState(() {
        _recording = false;
        _recordStarted = null;
      });
      if (path == null || !mounted) return;
      await _sendPicked(
        path: path,
        name: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        mime: 'audio/mp4',
        type: 'voice',
      );
      return;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;
    if (!await _recorder.hasPermission()) return;

    final dir = Directory.systemTemp;
    final out = '${dir.path}/furi_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: out,
    );
    setState(() {
      _recording = true;
      _recordStarted = DateTime.now();
    });
    _recordTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _showAttachSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        Widget item(IconData icon, String label, VoidCallback onTap) {
          return TapTile(
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _c,
                border: Border.all(color: _c, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: _darkText, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.bangers(
                      fontSize: 11,
                      color: _darkText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                item(Icons.photo_library, 'Galeria', () => _pickImage(fromCamera: false)),
                item(Icons.camera_alt, 'Camara', () => _pickImage(fromCamera: true)),
                item(Icons.videocam, 'Video', _pickVideo),
                item(Icons.attach_file, 'Archivo', _pickFile),
                item(Icons.gif_box, 'GIF', () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: const ['gif'],
                  );
                  if (result == null || result.files.single.path == null) return;
                  final f = result.files.single;
                  await _sendPicked(
                    path: f.path!,
                    name: f.name,
                    mime: 'image/gif',
                    type: 'gif',
                    size: f.size,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReactionBar(Message msg) {
    HapticFeedback.mediumImpact();
    final chat = context.read<ChatProvider>();
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x88000000),
      builder: (ctx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: _panel,
                border: Border.all(color: _panel, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in Message.defaultReactionEmojis)
                    ChatReactChip(
                      label: e,
                      selected: msg.myReactionKey(chat.myId) == e,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await chat.toggleReaction(msg, e);
                      },
                    ),
                  ChatReactChip(
                    label: '+',
                    selected: false,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final custom = await _askCustomReaction();
                      if (custom == null || custom.isEmpty) return;
                      await chat.toggleReaction(msg, custom);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _askCustomReaction() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _panel, width: 2),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 12,
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              counterStyle: GoogleFonts.bangers(color: Colors.white38),
              filled: true,
              fillColor: _bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _bg, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _bg, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _c, width: 2),
              ),
            ),
          ),
          actions: [
            TapTile(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bg,
                  border: Border.all(color: _bg, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, color: Colors.white70, size: 22),
              ),
            ),
            TapTile(
              onTap: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _c,
                  border: Border.all(color: _c, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check, color: _darkText, size: 22),
              ),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final t = getTheme(widget.mode);

    if (chat.messages.length != _lastMsgCount) {
      _lastMsgCount = chat.messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ResponsiveWrapper(
          builder: (context, w, h) {
            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
                  _header(w, h, chat),
                  _msgArea(w, h, chat, t),
                  if (chat.error != null) _errorBanner(w, h, chat),
                  if (chat.replyTo != null) _replyBanner(w, h, chat),
                  _inputArea(w, h, chat),
                  if (chat.partnerTyping) _typingBanner(w, h),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(double w, double h, ChatProvider chat) {
    final barH = h * 0.07;
    return Positioned(
      left: 0,
      top: 0,
      width: w,
      height: barH,
      child: Container(
        decoration: BoxDecoration(
          color: _c,
          border: Border.all(color: _c, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            Expanded(
              child: Center(
                child: Text(
                  chat.partnerName.isNotEmpty ? chat.partnerName : 'CHAT',
                  style: GoogleFonts.bangers(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: _darkText,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 46),
          ],
        ),
      ),
    );
  }

  Widget _errorBanner(double w, double h, ChatProvider chat) {
    return Positioned(
      left: w * 0.05,
      top: h * 0.075,
      width: w * 0.9,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _errorBg,
          border: Border.all(color: _errorBg, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chat.error ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bangers(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TapTile(
              onTap: chat.clearError,
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _msgArea(double w, double h, ChatProvider chat, ThemeSet t) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final top = h * 0.08;
    return Positioned(
      left: w * 0.025,
      top: top,
      width: w * 0.95,
      bottom: keyboard + 8 + h * 0.09 + 4,
      child: Container(
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _panel, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: switch (chat.state) {
          ChatLoadState.loading => const Center(
              child: CircularProgressIndicator(color: _c, strokeWidth: 3),
            ),
          ChatLoadState.error => Center(
              child: TapTile(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  chat.loadMessages();
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _c,
                    border: Border.all(color: _c, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh, color: _darkText, size: 28),
                ),
              ),
            ),
          ChatLoadState.empty => Center(
              child: Icon(
                Icons.chat_bubble_outline,
                color: _c.withValues(alpha: 0.5),
                size: 60,
              ),
            ),
          ChatLoadState.data => _chatList(chat, t),
        },
      ),
    );
  }

  Widget _chatList(ChatProvider chat, ThemeSet t) {
    final items = chat.messages.reversed.toList();
    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final m = items[i];
        final isMine = m.fromUser == chat.myId;
        return ChatSwipeToReply(
          onReply: () {
            HapticFeedback.mediumImpact();
            chat.setReplyTo(m);
            _focusNode.requestFocus();
          },
          child: ChatMessageTile(
            message: m,
            isMine: isMine,
            theme: t,
            downloading: chat.isDownloading(m.id),
            onLongPress: () => _showReactionBar(m),
            onReactionTap: (key) => chat.toggleReaction(m, key),
            onDownload: () => chat.downloadMedia(m),
          ),
        );
      },
    );
  }

  Widget _inputArea(double w, double h, ChatProvider chat) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    final recLabel = _recording && _recordStarted != null
        ? '${DateTime.now().difference(_recordStarted!).inSeconds}s'
        : '';

    return Positioned(
      left: w * 0.04,
      bottom: keyboard + 8,
      width: w * 0.92,
      height: h * 0.09,
      child: Container(
        decoration: BoxDecoration(
          color: _inputBg,
          border: Border.all(color: _inputBg, width: 3),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(5, 5), blurRadius: 0)],
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            TapTile(
              onTap: () {
                if (!chat.sending) _showAttachSheet();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _darkText,
                  border: Border.all(color: _darkText, width: 2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: _c, size: 20),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _recording
                  ? Text(
                      'Grabando $recLabel',
                      style: GoogleFonts.bangers(
                        color: _darkText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : TextField(
                      controller: _msgCtrl,
                      focusNode: _focusNode,
                      style: GoogleFonts.bangers(
                        color: _darkText,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Mensaje...',
                        hintStyle: TextStyle(color: Color(0xFF5A2200)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendText(),
                      onChanged: (v) => chat.notifyTyping(v.trim().isNotEmpty),
                    ),
            ),
            TapTile(
              onTap: () {
                if (!chat.sending) _toggleRecord();
              },
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: _recording ? const Color(0xFFFF1744) : _darkText,
                  border: Border.all(
                    color: _recording ? const Color(0xFFFF1744) : _darkText,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _recording ? Icons.stop : Icons.mic,
                  color: _recording ? Colors.white : _c,
                  size: 18,
                ),
              ),
            ),
            TapTile(
              onTap: () {
                if (!chat.sending) _sendText();
              },
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _darkText,
                  border: Border.all(color: _darkText, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: chat.sending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _c,
                        ),
                      )
                    : const Icon(Icons.send, color: _c, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typingBanner(double w, double h) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Positioned(
      right: w * 0.04,
      bottom: keyboard + 8 + h * 0.09 + 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _c,
          border: Border.all(color: _c, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text('escribiendo…',
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _replyBanner(double w, double h, ChatProvider chat) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom;
    return Positioned(
      left: w * 0.04,
      bottom: keyboard + 8 + h * 0.09 + 4,
      width: w * 0.92,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _c,
          border: Border.all(color: _c, width: 2),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: Row(
          children: [
            const Icon(Icons.reply, color: _darkText, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                chat.replyTo!.previewText,
                style: GoogleFonts.bangers(
                  color: _darkText,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TapTile(
              onTap: chat.clearReply,
              child: const Icon(Icons.close, color: _darkText, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}