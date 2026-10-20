import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message.dart';
import '../services/chat_media_service.dart';
import 'helpers/chat_message_operations.dart';
import 'helpers/chat_message_sync.dart';
import 'helpers/chat_presence_service.dart';
import 'helpers/chat_profile_mixin.dart';

enum ChatLoadState { loading, empty, error, data }

class ChatProvider extends ChangeNotifier with WidgetsBindingObserver, ChatProfileMixin {
  @override
  final String myId;
  @override
  final String partnerId;
  final ChatMediaService media;

  late final ChatPresenceService _presence;
  late final ChatMessageOperations _ops;

  ChatProvider({
    required this.myId,
    required this.partnerId,
    ChatMediaService? media,
  }) : media = media ?? ChatMediaService() {
    _presence = ChatPresenceService(
      myId: myId,
      partnerId: partnerId,
      onNotify: notifyListeners,
    );
    _ops = ChatMessageOperations(
      myId: myId,
      partnerId: partnerId,
      media: this.media,
      getMessages: () => _messages,
      getLocalPaths: () => _localPaths,
      downloading: _downloading,
      setSending: (v) => _sending = v,
      setError: (err) => _error = err,
      clearReply: clearReply,
      onNotify: notifyListeners,
    );
  }

  final List<Message> _messages = [];
  ChatLoadState _state = ChatLoadState.loading;
  String? _error;
  Message? _replyTo;
  bool _sending = false;
  bool _hasMore = true;
  bool _loadingOlder = false;
  final Set<int> _downloading = {};
  RealtimeChannel? _channel;
  Map<int, String> _localPaths = {};

  List<Message> get messages => List.unmodifiable(_messages);
  ChatLoadState get state => _state;
  String? get error => _error;
  Message? get replyTo => _replyTo;
  bool get sending => _sending;
  bool get hasMore => _hasMore;
  bool get loadingOlder => _loadingOlder;

  bool get partnerTyping => _presence.partnerTyping;
  bool get isPartnerOnline => _presence.isPartnerOnline;
  DateTime? get partnerLastSeen => _presence.partnerLastSeen;
  String get partnerStatusText => _presence.partnerStatusText;
  bool isDownloading(int id) => _downloading.contains(id);

  static String formatLastSeen(DateTime dt, {DateTime? clockNow}) =>
      ChatPresenceService.formatLastSeen(dt, clockNow: clockNow);

  @visibleForTesting
  void setPartnerOnlineForTest(bool online, {DateTime? lastSeen}) =>
      _presence.setPartnerOnlineForTest(online, lastSeen: lastSeen);

  @visibleForTesting
  void setPartnerTypingForTest(bool typing) =>
      _presence.setPartnerTypingForTest(typing);

  @visibleForTesting
  void setMessagesForTest(List<Message> items) {
    _messages
      ..clear()
      ..addAll(items);
    _state = items.isEmpty ? ChatLoadState.empty : ChatLoadState.data;
  }

  @visibleForTesting
  void addOlderMessagesForTest(List<Message> items) {
    final existingIds = _messages.map((m) => m.id).toSet();
    final older = items.where((m) => !existingIds.contains(m.id)).toList();
    _messages.insertAll(0, older);
    if (_messages.isNotEmpty && _state == ChatLoadState.empty) {
      _state = ChatLoadState.data;
    }
    notifyListeners();
  }

  @visibleForTesting
  void setHasMoreForTest(bool value) {
    _hasMore = value;
    notifyListeners();
  }

  Future<void> init() async {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
    _localPaths = await media.loadLocalIndex();
    subscribeRealtime();
    _presence.subscribeTyping();
    subscribeProfiles();
    _presence.subscribePresence();
    await Future.wait([
      loadMessages(),
      loadProfiles(),
      _presence.loadPartnerPresence(),
    ]);
  }

  Future<void> loadMessages() async {
    _state = ChatLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final res = await ChatMessageSync.fetchInitialMessages(
        myId: myId,
        localPaths: _localPaths,
        currentMessages: _messages,
      );
      _hasMore = res.hasMore;
      _messages
        ..clear()
        ..addAll(res.messages);
      _state = _messages.isEmpty ? ChatLoadState.empty : ChatLoadState.data;
      notifyListeners();
      await markIncomingDelivered();
      await markIncomingRead();
    } catch (e) {
      _error = e.toString();
      _state = ChatLoadState.error;
      notifyListeners();
    }
  }

  Future<void> loadOlderMessages() async {
    if (_loadingOlder || !_hasMore || _messages.isEmpty) return;
    final oldestMsg = _messages.firstWhere(
      (m) => m.createdAt != null,
      orElse: () => _messages.first,
    );
    final oldest = oldestMsg.createdAt;
    if (oldest == null) return;
    _loadingOlder = true;
    notifyListeners();
    final res = await ChatMessageSync.fetchOlderMessages(
      myId: myId,
      oldest: oldest,
      localPaths: _localPaths,
      existingIds: _messages.map((m) => m.id).toSet(),
    );
    if (res != null) {
      _hasMore = res.hasMore;
      if (res.messages.isNotEmpty) {
        _messages.insertAll(0, res.messages);
        _state = ChatLoadState.data;
      }
    }
    _loadingOlder = false;
    notifyListeners();
  }

  void subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = ChatMessageSync.subscribeMessages(
      myId: myId,
      localPaths: _localPaths,
      onInsert: (msg) {
        if (_messages.any((m) => m.id == msg.id)) return;
        _messages.add(msg);
        _state = ChatLoadState.data;
        notifyListeners();
        if (msg.toUser == myId) {
          markIncomingDelivered(onlyThese: {msg.id});
          markIncomingRead();
        }
      },
      onUpdate: (updated) {
        final idx = _messages.indexWhere((m) => m.id == updated.id);
        if (idx < 0) return;
        final local = _messages[idx].localPath ?? _localPaths[updated.id];
        _messages[idx] = updated.copyWith(localPath: local);
        notifyListeners();
      },
    );
  }

  void setReplyTo(Message? msg) {
    _replyTo = msg;
    notifyListeners();
  }

  void clearReply() {
    _replyTo = null;
    notifyListeners();
  }

  Future<void> sendText(String text) async {
    final body = text.trim();
    if (body.isEmpty || partnerId.isEmpty) return;
    await _ops.insertMessage({
      'from_user': myId,
      'to_user': partnerId,
      'content': body,
      'message_type': 'text',
      if (_replyTo != null) 'reply_to_id': _replyTo!.id,
      if (_replyTo != null) 'reply_content': _replyTo!.previewText,
    });
  }

  Future<void> sendMedia({
    required String localPath,
    required String messageType,
    required String fileName,
    String? mimeType,
    int? size,
    String caption = '',
  }) async {
    await _ops.sendMedia(
      localPath: localPath,
      messageType: messageType,
      fileName: fileName,
      mimeType: mimeType,
      size: size,
      caption: caption,
      replyTo: _replyTo,
    );
  }

  Future<void> toggleReaction(Message msg, String key) =>
      _ops.toggleReaction(msg, key);

  Future<void> downloadMedia(Message msg) => _ops.downloadMedia(msg);

  Future<void> markIncomingRead() => _ops.markIncomingRead();

  Future<void> markIncomingDelivered({Set<int>? onlyThese}) =>
      _ops.markIncomingDelivered(onlyThese: onlyThese);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void notifyTyping(bool typing) => _presence.notifyTyping(typing);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _presence.handleLifecycleState(state);
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _presence.dispose();
    disposeProfiles();
    _channel?.unsubscribe();
    super.dispose();
  }
}
