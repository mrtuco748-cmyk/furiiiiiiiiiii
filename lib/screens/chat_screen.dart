import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:video_player/video_player.dart';

import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../services/chat_media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/responsive_wrapper.dart';

const _c = Color(0xFFFF6B00);
const _bg = Color(0xFF1A0F08);
const _panel = Color(0xFF2A1810);
const _inputBg = Color(0xFFFF6B00);
const _darkText = Color(0xFF1A0F08);
const _errorBg = Color(0xFF5A1010);

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
        _scrollCtrl.position.maxScrollExtent,
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
    try {
      await chat.sendText(text);
      _scrollToBottom();
      _focusNode.unfocus();
    } catch (_) {}
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
    } catch (_) {}
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
      final secs = _recordStarted == null
          ? 0
          : DateTime.now().difference(_recordStarted!).inSeconds;
      await _sendPicked(
        path: path,
        name: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        mime: 'audio/mp4',
        type: 'voice',
      );
      if (mounted && secs > 0) {
        // caption opcional con duración ya va en content=filename
      }
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
          return GestureDetector(
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
                    style: GoogleFonts.bangers(fontSize: 11, color: _darkText),
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
                    _ReactChip(
                      label: e,
                      selected: msg.myReactionKey(chat.myId) == e,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await chat.toggleReaction(msg, e);
                      },
                    ),
                  _ReactChip(
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
            GestureDetector(
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
            GestureDetector(
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
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.arrow_back, color: _darkText, size: 22),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  chat.partnerName.isNotEmpty ? chat.partnerName : 'CHAT',
                  style: GoogleFonts.bangers(
                    fontWeight: FontWeight.bold,
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
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                chat.error ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 12),
              ),
            ),
            GestureDetector(
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
        ),
        child: switch (chat.state) {
          ChatLoadState.loading => const Center(
              child: CircularProgressIndicator(color: _c, strokeWidth: 3),
            ),
          ChatLoadState.error => Center(
              child: GestureDetector(
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
          ChatLoadState.data => ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              itemCount: chat.messages.length,
              itemBuilder: (ctx, i) {
                final m = chat.messages[i];
                final isMine = m.fromUser == chat.myId;
                return _SwipeToReply(
                  onReply: () {
                    HapticFeedback.mediumImpact();
                    chat.setReplyTo(m);
                    _focusNode.requestFocus();
                  },
                  child: _MessageTile(
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
            ),
        },
      ),
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
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            GestureDetector(
              onTap: chat.sending ? null : _showAttachSheet,
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
                      ),
                    )
                  : TextField(
                      controller: _msgCtrl,
                      focusNode: _focusNode,
                      style: GoogleFonts.bangers(
                        color: _darkText,
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Mensaje...',
                        hintStyle: TextStyle(color: Color(0xFF5A2200)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
            ),
            GestureDetector(
              onTap: chat.sending ? null : _toggleRecord,
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
            GestureDetector(
              onTap: chat.sending ? null : _sendText,
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
        ),
        child: Row(
          children: [
            const Icon(Icons.reply, color: _darkText, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                chat.replyTo!.previewText,
                style: GoogleFonts.bangers(color: _darkText, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: chat.clearReply,
              child: const Icon(Icons.close, color: _darkText, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReactChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ReactChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? _c : _bg;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: bg, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: label == '+' ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: selected ? _darkText : Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

/// Swipe horizontal acumulado (WhatsApp-like) en CUALQUIER mensaje.
class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  const _SwipeToReply({required this.child, required this.onReply});

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  double _dx = 0;
  static const _max = 72.0;
  static const _threshold = 42.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
      if (_ctrl.isAnimating) {
        setState(() => _dx = _ctrl.value * _max);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _snapBack() {
    final from = _dx;
    if (from <= 0) return;
    _ctrl.value = from / _max;
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dx / _threshold).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) {
        _ctrl.stop();
        setState(() => _dx = 0);
      },
      onHorizontalDragUpdate: (d) {
        setState(() {
          _dx = (_dx + d.delta.dx).clamp(0.0, _max);
        });
      },
      onHorizontalDragEnd: (_) {
        final trigger = _dx >= _threshold;
        _snapBack();
        if (trigger) widget.onReply();
      },
      onHorizontalDragCancel: _snapBack,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Opacity(
            opacity: progress,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.reply, color: _c.withValues(alpha: progress), size: 22),
            ),
          ),
          Transform.translate(
            offset: Offset(_dx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final Message message;
  final bool isMine;
  final ThemeSet theme;
  final bool downloading;
  final VoidCallback onLongPress;
  final void Function(String key) onReactionTap;
  final VoidCallback onDownload;

  const _MessageTile({
    required this.message,
    required this.isMine,
    required this.theme,
    required this.downloading,
    required this.onLongPress,
    required this.onReactionTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = isMine ? theme.a : theme.e;
    final textColor = isMine ? theme.dark : theme.light;
    final subColor = isMine ? theme.dark.withValues(alpha: 0.6) : Colors.white38;
    final raw = message.createdAt;
    final timeStr = raw != null
        ? '${raw.hour.toString().padLeft(2, '0')}:${raw.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: message.reactions.isEmpty ? 8 : 14,
        left: isMine ? 48 : 4,
        right: isMine ? 4 : 48,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: blockColor,
                  border: Border.all(color: blockColor, width: 3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.replyContent != null &&
                        message.replyContent!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _panel,
                          border: Border.all(
                            color: _panel,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.replyContent!,
                          style: GoogleFonts.bangers(
                            fontSize: 11,
                            color: _c,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    _MediaBody(
                      message: message,
                      textColor: textColor,
                      downloading: downloading,
                      onDownload: onDownload,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: GoogleFonts.bangers(fontSize: 10, color: subColor),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.read ? Icons.done_all : Icons.done,
                            size: 14,
                            color: subColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (message.reactions.isNotEmpty)
                Positioned(
                  bottom: -12,
                  right: isMine ? 8 : null,
                  left: isMine ? null : 8,
                  child: _ReactionsRow(
                    reactions: message.reactions,
                    onTap: onReactionTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReactionsRow extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final void Function(String key) onTap;
  const _ReactionsRow({required this.reactions, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _panel, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in reactions.entries)
            GestureDetector(
              onTap: () => onTap(e.key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  e.value.length > 1 ? '${e.key}${e.value.length}' : e.key,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MediaBody extends StatelessWidget {
  final Message message;
  final Color textColor;
  final bool downloading;
  final VoidCallback onDownload;

  const _MediaBody({
    required this.message,
    required this.textColor,
    required this.downloading,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    if (!message.isMedia) {
      return Text(
        message.content,
        style: GoogleFonts.bangers(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: textColor,
        ),
      );
    }

    if (message.hasLocalMedia) {
      return _LocalMediaView(message: message, textColor: textColor);
    }

    if (message.needsCloudDownload || downloading) {
      return GestureDetector(
        onTap: downloading ? null : onDownload,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF3A2418),
            border: Border.all(color: const Color(0xFF3A2418), width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (downloading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _c),
                )
              else
                Icon(_iconFor(message.messageType), color: textColor, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  downloading
                      ? 'Descargando...'
                      : (message.attachmentName ?? message.previewText),
                  style: GoogleFonts.bangers(fontSize: 13, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!downloading) ...[
                const SizedBox(width: 8),
                Icon(Icons.download, color: textColor, size: 18),
              ],
            ],
          ),
        ),
      );
    }

    // cloud borrado y sin local
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, color: textColor.withValues(alpha: 0.7), size: 18),
        const SizedBox(width: 6),
        Text(
          message.attachmentName ?? message.previewText,
          style: GoogleFonts.bangers(fontSize: 13, color: textColor),
        ),
      ],
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'image':
      case 'gif':
        return Icons.image;
      case 'video':
        return Icons.videocam;
      case 'voice':
        return Icons.mic;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _LocalMediaView extends StatelessWidget {
  final Message message;
  final Color textColor;
  const _LocalMediaView({required this.message, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final path = message.localPath!;
    switch (message.messageType) {
      case 'image':
      case 'gif':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                width: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.broken_image,
                  color: textColor,
                  size: 40,
                ),
              ),
            ),
            if (message.content.isNotEmpty &&
                message.content != message.attachmentName) ...[
              const SizedBox(height: 6),
              Text(
                message.content,
                style: GoogleFonts.bangers(fontSize: 14, color: textColor),
              ),
            ],
          ],
        );
      case 'video':
        return _VideoThumb(path: path, textColor: textColor);
      case 'voice':
        return _AudioPlayerTile(path: path, textColor: textColor);
      default:
        return GestureDetector(
          onTap: () => OpenFilex.open(path),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.insert_drive_file, color: textColor, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  message.attachmentName ?? message.content,
                  style: GoogleFonts.bangers(fontSize: 13, color: textColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.open_in_new, color: textColor, size: 16),
            ],
          ),
        );
    }
  }
}

class _VideoThumb extends StatefulWidget {
  final String path;
  final Color textColor;
  const _VideoThumb({required this.path, required this.textColor});

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  VideoPlayerController? _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ctrl == null) {
      return SizedBox(
        width: 200,
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: widget.textColor, strokeWidth: 2),
        ),
      );
    }
    return GestureDetector(
      onTap: () {
        final c = _ctrl!;
        setState(() {
          c.value.isPlaying ? c.pause() : c.play();
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 220,
          child: AspectRatio(
            aspectRatio: _ctrl!.value.aspectRatio == 0
                ? 16 / 9
                : _ctrl!.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayer(_ctrl!),
                if (!_ctrl!.value.isPlaying)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _bg,
                      border: Border.all(color: _bg, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.play_arrow, color: _c, size: 28),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioPlayerTile extends StatefulWidget {
  final String path;
  final Color textColor;
  const _AudioPlayerTile({required this.path, required this.textColor});

  @override
  State<_AudioPlayerTile> createState() => _AudioPlayerTileState();
}

class _AudioPlayerTileState extends State<_AudioPlayerTile> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    await _player.play(DeviceFileSource(widget.path));
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _playing ? Icons.stop : Icons.play_arrow,
            color: widget.textColor,
            size: 26,
          ),
          const SizedBox(width: 6),
          Icon(Icons.graphic_eq, color: widget.textColor, size: 20),
          const SizedBox(width: 6),
          Text(
            'Audio',
            style: GoogleFonts.bangers(fontSize: 13, color: widget.textColor),
          ),
        ],
      ),
    );
  }
}
