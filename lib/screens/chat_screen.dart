import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/concrete_painter.dart';
import 'chat/chat_style.dart';
import 'chat/helpers/chat_media_picker_helper.dart';
import 'chat/helpers/chat_voice_recorder.dart';
import 'chat/widgets/chat_app_bar.dart';
import 'chat/widgets/chat_attachment_sheet.dart';
import 'chat/widgets/chat_emoji_sticker_sheet.dart';
import 'chat/widgets/chat_input_bar.dart';
import 'chat/widgets/chat_list_view.dart';
import 'chat/widgets/chat_profile_dialog.dart';
import 'chat/widgets/chat_reaction_dialog.dart';
import 'chat/widgets/chat_state_banners.dart';

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
  final _voiceRecorder = ChatVoiceRecorder();
  final _mediaPicker = ChatMediaPickerHelper();
  final _picker = ImagePicker();
  bool _hasText = false;
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
    if (has != _hasText) setState(() => _hasText = has);
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
    _voiceRecorder.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 180), curve: Curves.easeOut);
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
    final path = await _voiceRecorder.toggleRecord(() {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});

    if (path != null && mounted) {
      await _sendPicked(
        path: path,
        name: 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
        mime: 'audio/mp4',
        type: 'voice',
      );
    }
  }

  void _showEmojiAndStickersSheet(ThemeSet t) {
    HapticFeedback.lightImpact();
    final chat = context.read<ChatProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ChatEmojiStickerSheet(
          textController: _msgCtrl,
          theme: t,
          onStickerSelected: (File file) => ChatMediaPickerHelper.sendSticker(
            stickerFile: file,
            chat: chat,
            onSent: _scrollToBottom,
          ),
        );
      },
    );
  }

  void _openAttachSheet() {
    showChatAttachmentSheet(
      context: context,
      onPickGallery: () => _mediaPicker.pickImage(fromCamera: false, onSend: _sendPicked),
      onPickCamera: () => _mediaPicker.pickImage(fromCamera: true, onSend: _sendPicked),
      onPickVideo: () => _mediaPicker.pickVideo(onSend: _sendPicked),
      onPickFile: () => _mediaPicker.pickFile(onSend: _sendPicked),
      onPickGif: (PlatformFile f) async {
        if (f.path == null) return;
        await _sendPicked(
          path: f.path!,
          name: f.name,
          mime: 'image/gif',
          type: 'gif',
          size: f.size,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final t = getTheme(widget.mode);

    final currentNewestId = chat.messages.isNotEmpty ? chat.messages.last.id : null;
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
      appBar: ChatAppBar(
        chat: chat,
        theme: t,
        onProfileTap: () {
          final partnerName = chat.partnerName.isNotEmpty ? chat.partnerName : 'Pareja';
          showChatProfileDialog(
            context: context,
            partnerName: partnerName,
            avatarUrl: chat.partnerAvatarUrl,
            onChangeAvatar: () => pickAndSetMyAvatar(
              context: context,
              picker: _picker,
              onUpdateAvatar: chat.updateMyAvatar,
            ),
          );
        },
        onCameraTap: () => pickAndSetMyAvatar(
          context: context,
          picker: _picker,
          onUpdateAvatar: chat.updateMyAvatar,
        ),
        onReloadTap: () {
          HapticFeedback.lightImpact();
          chat.loadMessages();
        },
      ),
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
          Column(
            children: [
              if (chat.error != null) ChatErrorBanner(chat: chat),
              Expanded(
                child: switch (chat.state) {
                  ChatLoadState.loading => const Center(
                      child: CircularProgressIndicator(color: ChatStyle.primary, strokeWidth: 3),
                    ),
                  ChatLoadState.error => ChatErrorState(onRetry: chat.loadMessages),
                  ChatLoadState.empty => const ChatEmptyState(),
                  ChatLoadState.data => ChatListView(
                      scrollController: _scrollCtrl,
                      chat: chat,
                      theme: t,
                      onSwipeReply: (m) {
                        HapticFeedback.mediumImpact();
                        chat.setReplyTo(m);
                        _focusNode.requestFocus();
                      },
                      onLongPressMessage: (m) => showChatReactionBar(context, m, chat),
                    ),
                },
              ),
              if (chat.replyTo != null) ChatReplyBanner(chat: chat, theme: t),
              ChatInputBar(
                msgCtrl: _msgCtrl,
                focusNode: _focusNode,
                recording: _voiceRecorder.isRecording,
                recordStarted: _voiceRecorder.recordStarted,
                hasText: _hasText,
                sending: chat.sending,
                theme: t,
                onEmojiTap: () => _showEmojiAndStickersSheet(t),
                onAttachTap: _openAttachSheet,
                onCameraTap: () => _mediaPicker.pickImage(fromCamera: true, onSend: _sendPicked),
                onSendText: _sendText,
                onToggleRecord: _toggleRecord,
                onChanged: (v) => chat.notifyTyping(v.trim().isNotEmpty),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
