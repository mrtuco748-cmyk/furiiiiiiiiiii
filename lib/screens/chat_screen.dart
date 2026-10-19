import 'dart:async';
import 'dart:convert';
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

import '../app_state.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../services/chat_media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/concrete_painter.dart';
import '../widgets/tap_tile.dart';
import 'chat/chat_style.dart';
import 'chat/widgets/chat_message_tile.dart';
import 'chat/widgets/chat_react_chip.dart';
import 'chat/widgets/chat_swipe_to_reply.dart';
import 'chat/widgets/chat_emoji_sticker_sheet.dart';

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
  bool _hasText = false;
  DateTime? _recordStarted;
  Timer? _recordTicker;
  int? _lastNewestMessageId;
  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _msgCtrl.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = _msgCtrl.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pv = context.read<ChatProvider>();
    if (pv.messages.isEmpty || !pv.hasMore || pv.loadingOlder) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      pv.loadOlderMessages();
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
    HapticFeedback.lightImpact();
    final chat = context.read<ChatProvider>();
    _msgCtrl.clear();
    chat.notifyTyping(false);
    try {
      await chat.sendText(text);
      _scrollToBottom();
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
      backgroundColor: ChatStyle.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget item(IconData icon, String label, Color color, VoidCallback onTap) {
          return TapTile(
            onTap: () {
              Navigator.pop(ctx);
              onTap();
            },
            child: Container(
              width: 76,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 26),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                item(Icons.photo_library, 'Galería', const Color(0xFF9C27B0), () => _pickImage(fromCamera: false)),
                item(Icons.camera_alt, 'Cámara', const Color(0xFFE91E63), () => _pickImage(fromCamera: true)),
                item(Icons.videocam, 'Video', const Color(0xFF00B0FF), _pickVideo),
                item(Icons.attach_file, 'Archivo', const Color(0xFFFF9800), _pickFile),
                item(Icons.gif_box, 'GIF', const Color(0xFF4CAF50), () async {
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

  void _showEmojiAndStickersSheet(ThemeSet t) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ChatEmojiStickerSheet(
          textController: _msgCtrl,
          theme: t,
          onStickerSelected: (File stickerFile) async {
            await _sendSticker(stickerFile);
          },
        );
      },
    );
  }

  Future<void> _sendSticker(File stickerFile) async {
    HapticFeedback.mediumImpact();
    final chat = context.read<ChatProvider>();
    final name = 'sticker_${DateTime.now().millisecondsSinceEpoch}.webp';
    try {
      await chat.sendMedia(
        localPath: stickerFile.path,
        messageType: 'sticker',
        fileName: name,
        mimeType: 'image/webp',
        caption: 'Sticker',
      );
      _scrollToBottom();
    } catch (e) {
      developer.log('sendSticker fallo: $e');
    }
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
                color: ChatStyle.panel,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...Message.defaultReactionEmojis.map((e) {
                    final selected = msg.myReactionKey(chat.myId) == e;
                    return ChatReactChip(
                      label: e,
                      selected: selected,
                      onTap: () {
                        Navigator.pop(ctx);
                        chat.toggleReaction(msg, e);
                      },
                    );
                  }),
                  TapTile(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final custom = await _promptCustomEmoji();
                      if (custom != null && custom.isNotEmpty) {
                        chat.toggleReaction(msg, custom);
                      }
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: ChatStyle.inputBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _promptCustomEmoji() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ChatStyle.panel,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Reacción personalizada',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            maxLength: 8,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: const InputDecoration(
              hintText: 'Emoji o texto corto...',
              hintStyle: TextStyle(color: Colors.white38),
              border: InputBorder.none,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: ChatStyle.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    return result;
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(local.year, local.month, local.day);
    final diff = today.difference(msgDate).inDays;
    if (diff == 0) return 'HOY';
    if (diff == 1) return 'AYER';
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final mName = months[(local.month - 1).clamp(0, 11)];
    if (local.year == now.year) {
      return '${local.day} de $mName';
    }
    return '${local.day} de $mName de ${local.year}';
  }

  Widget _dateChip(DateTime dt) {
    final text = _formatDateHeader(dt);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: ChatStyle.panel,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ChatStyle.subText,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final t = getTheme(widget.mode);

    final currentNewestId =
        chat.messages.isNotEmpty ? chat.messages.last.id : null;
    if (chat.messages.length != _lastMsgCount) {
      final isNewMessageAppended = _lastMsgCount == 0 ||
          (currentNewestId != null && currentNewestId != _lastNewestMessageId);
      _lastMsgCount = chat.messages.length;
      _lastNewestMessageId = currentNewestId;
      if (isNewMessageAppended) {
        _scrollToBottom();
      }
    } else if (currentNewestId != _lastNewestMessageId) {
      _lastNewestMessageId = currentNewestId;
    }

    return Scaffold(
      backgroundColor: ChatStyle.bg,
      appBar: _buildAppBar(context, chat, t),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          Column(
            children: [
              if (chat.error != null) _errorBanner(chat),
              Expanded(
                child: switch (chat.state) {
                  ChatLoadState.loading => const Center(
                      child: CircularProgressIndicator(color: ChatStyle.primary, strokeWidth: 3),
                    ),
                  ChatLoadState.error => _buildErrorState(chat, t),
                  ChatLoadState.empty => _buildEmptyState(),
                  ChatLoadState.data => _buildChatList(chat, t),
                },
              ),
              if (chat.replyTo != null) _replyBanner(chat, t),
              _buildInputBar(chat, t),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider? _getAvatarImageProvider(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;
    if (avatarUrl.startsWith('data:image')) {
      final comma = avatarUrl.indexOf(',');
      if (comma != -1) {
        final base64Str = avatarUrl.substring(comma + 1);
        try {
          return MemoryImage(base64Decode(base64Str));
        } catch (_) {
          return null;
        }
      }
    } else if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return NetworkImage(avatarUrl);
    } else if (File(avatarUrl).existsSync()) {
      return FileImage(File(avatarUrl));
    }
    return null;
  }

  Future<void> _pickAndSetMyAvatar(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: ChatStyle.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cambiar mi foto de perfil',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: ChatStyle.primary),
                title: Text(
                  'Elegir de la galería',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: ChatStyle.primary),
                title: Text(
                  'Tomar foto con la cámara',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 82,
      );
      if (picked == null || !context.mounted) return;

      final bytes = await File(picked.path).readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      if (!context.mounted) return;
      await context.read<ChatProvider>().updateMyAvatar(base64Image);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '¡Foto de perfil actualizada!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF25D366),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('Error actualizando foto de perfil: $e');
    }
  }

  void _showProfileDialog(BuildContext context, String partnerName, String? avatarUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ChatStyle.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: const Color(0xFF2A2A2A),
                backgroundImage: _getAvatarImageProvider(avatarUrl),
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(
                        partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 42,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                partnerName,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pareja F.U.R.I',
                style: GoogleFonts.plusJakartaSans(
                  color: ChatStyle.subText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ChatStyle.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: Text(
                  'Cambiar mi foto de perfil',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _pickAndSetMyAvatar(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatProvider chat, ThemeSet t) {
    final partnerName = chat.partnerName.isNotEmpty
        ? chat.partnerName
        : (AppState.partnerName.isNotEmpty ? AppState.partnerName : 'Pareja');
    final initial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P';
    final partnerAvatar = chat.partnerAvatarUrl;

    return AppBar(
      backgroundColor: ChatStyle.appbarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 44,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: const EdgeInsets.only(left: 6),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: () => _showProfileDialog(context, partnerName, partnerAvatar),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: t.a,
                backgroundImage: _getAvatarImageProvider(partnerAvatar),
                child: (partnerAvatar == null || partnerAvatar.isEmpty)
                    ? Text(
                        initial,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: t.dark,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      partnerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    if (chat.partnerTyping)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF25D366),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'escribiendo...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF25D366),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'en línea',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ChatStyle.subText,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 22),
          tooltip: 'Cambiar mi foto de perfil',
          onPressed: () => _pickAndSetMyAvatar(context),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70, size: 22),
          tooltip: 'Recargar mensajes',
          onPressed: () {
            HapticFeedback.lightImpact();
            chat.loadMessages();
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _errorBanner(ChatProvider chat) {
    return Container(
      width: double.infinity,
      color: ChatStyle.errorBg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              chat.error ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TapTile(
            onTap: chat.clearError,
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ChatProvider chat, ThemeSet t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: ChatStyle.errorBg, size: 48),
          const SizedBox(height: 12),
          Text(
            'Error al cargar mensajes',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TapTile(
            onTap: () {
              HapticFeedback.heavyImpact();
              chat.loadMessages();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: t.a,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Reintentar',
                style: GoogleFonts.plusJakartaSans(
                  color: t.dark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: Colors.white.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin mensajes aún',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¡Envía el primer mensaje a tu pareja!',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white38,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(ChatProvider chat, ThemeSet t) {
    final items = chat.messages.reversed.toList();
    final bool showTopLoader = chat.loadingOlder;
    final bool showStartBanner = !chat.hasMore && items.isNotEmpty;
    final int extraTopItem = (showTopLoader || showStartBanner) ? 1 : 0;
    final int itemCount = items.length + extraTopItem;

    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      itemCount: itemCount,
      itemBuilder: (ctx, i) {
        if (i == items.length) {
          if (showTopLoader) {
            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: ChatStyle.primary,
                  ),
                ),
              ),
            );
          }
          if (showStartBanner) {
            return Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 14),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: ChatStyle.panel.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Inicio de los mensajes',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ChatStyle.subText,
                  ),
                ),
              ),
            );
          }
        }

        final m = items[i];
        final next = i + 1 < items.length ? items[i + 1] : null;
        final bool showDateHeader =
            next == null || !_isSameDay(m.createdAt, next.createdAt);
        final isMine = m.fromUser == chat.myId;

        final tile = ChatSwipeToReply(
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

        if (showDateHeader && m.createdAt != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dateChip(m.createdAt!),
              tile,
            ],
          );
        }

        return tile;
      },
    );
  }

  Widget _replyBanner(ChatProvider chat, ThemeSet t) {
    final preview = chat.replyTo?.previewText ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ChatStyle.inputBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: t.a,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.reply, color: Colors.white70, size: 18),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Respondiendo a mensaje',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: t.a,
                  ),
                ),
                Text(
                  preview,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
            onPressed: chat.clearReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatProvider chat, ThemeSet t) {
    final recLabel = _recording && _recordStarted != null
        ? '${DateTime.now().difference(_recordStarted!).inSeconds}s'
        : '';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ChatStyle.inputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white70, size: 24),
                      onPressed: () => _showEmojiAndStickersSheet(t),
                    ),
                    Expanded(
                      child: _recording
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.fiber_manual_record, color: Color(0xFFFF1744), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Grabando $recLabel...',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextField(
                              controller: _msgCtrl,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 5,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Mensaje...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                              ),
                              onSubmitted: (_) => _sendText(),
                              onChanged: (v) => chat.notifyTyping(v.trim().isNotEmpty),
                            ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.white70, size: 22),
                      onPressed: () {
                        if (!chat.sending) _showAttachSheet();
                      },
                    ),
                    if (!_hasText && !_recording)
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 22),
                        onPressed: () => _pickImage(fromCamera: true),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                if (_recording) {
                  _toggleRecord();
                } else if (_hasText) {
                  _sendText();
                } else {
                  _toggleRecord();
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _recording ? const Color(0xFFFF1744) : t.a,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: chat.sending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: t.dark,
                          ),
                        )
                      : Icon(
                          _recording
                              ? Icons.stop
                              : (_hasText ? Icons.send : Icons.mic),
                          color: _recording ? Colors.white : t.dark,
                          size: 22,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}