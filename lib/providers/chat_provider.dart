import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/message.dart';
import '../services/chat_media_service.dart';
import '../supabase_config.dart';

enum ChatLoadState { loading, empty, error, data }

class ChatProvider extends ChangeNotifier {
  final String myId;
  final String partnerId;
  final ChatMediaService media;

  ChatProvider({
    required this.myId,
    required this.partnerId,
    ChatMediaService? media,
  }) : media = media ?? ChatMediaService();

  final List<Message> _messages = [];
  ChatLoadState _state = ChatLoadState.loading;
  String? _error;
  String _partnerName = '';
  Message? _replyTo;
  bool _sending = false;
  bool _hasMore = true;
  bool _loadingOlder = false;
  final Set<int> _downloading = {};
  RealtimeChannel? _channel;
  Map<int, String> _localPaths = {};
  bool _partnerTyping = false;
  Timer? _typingDebounce;
  Timer? _typingReceiverTimer;
  RealtimeChannel? _typingChannel;

  List<Message> get messages => List.unmodifiable(_messages);
  ChatLoadState get state => _state;
  String? get error => _error;
  String get partnerName => _partnerName;
  Message? get replyTo => _replyTo;
  bool get sending => _sending;
  bool get hasMore => _hasMore;
  bool get loadingOlder => _loadingOlder;
  bool get partnerTyping => _partnerTyping;
  bool isDownloading(int id) => _downloading.contains(id);

  @visibleForTesting
  void setMessagesForTest(List<Message> items) {
    _messages
      ..clear()
      ..addAll(items);
    _state = items.isEmpty ? ChatLoadState.empty : ChatLoadState.data;
  }

  Future<void> init() async {
    _localPaths = await media.loadLocalIndex();
    // Nos suscribimos al realtime ANTES de cargar el snapshot de la BD: así
    // cualquier mensaje que llegue por el canal mientras hacemos el fetch no
    // se pierde. loadMessages hace merge por id en vez de limpiar la lista.
    subscribeRealtime();
    subscribeTyping();
    await Future.wait([loadMessages(), loadPartnerName()]);
  }

  Future<void> loadPartnerName() async {
    if (partnerId.isEmpty) return;
    try {
      final data = await SupabaseConfig.client
          .from('profiles')
          .select('name')
          .eq('id', partnerId)
          .maybeSingle();
      _partnerName = data?['name'] as String? ?? '';
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMessages() async {
    _state = ChatLoadState.loading;
    _error = null;
    _hasMore = true;
    notifyListeners();
    try {
      final data = await SupabaseConfig.client
          .from('messages')
          .select('*')
          .or('from_user.eq.$myId,to_user.eq.$myId')
          .order('created_at', ascending: false)
          .limit(100);
      final newestFirst = List<Map<String, dynamic>>.from(data as List);
      final fetched = newestFirst.reversed.map((row) {
        final id = Message.fromMap(row).id;
        return Message.fromMap(row, localPath: _localPaths[id]);
      }).toList();
      // Merge por id: preserva los mensajes que ya entraron por realtime
      // durante la carga (la suscripción corre antes del fetch en init()).
      final byId = <int, Message>{};
      for (final m in _messages) {
        byId[m.id] = m;
      }
      for (final m in fetched) {
        byId[m.id] = m;
      }
      final merged = byId.values.toList()
        ..sort((a, b) => (a.createdAt ?? DateTime(0))
            .compareTo(b.createdAt ?? DateTime(0)));
      _messages
        ..clear()
        ..addAll(merged);
      _state =
          _messages.isEmpty ? ChatLoadState.empty : ChatLoadState.data;
      notifyListeners();
      await markIncomingRead();
    } catch (e) {
      _error = e.toString();
      _state = ChatLoadState.error;
      notifyListeners();
    }
  }

  /// Carga más mensajes antiguos (antes del más viejo cargado), para el
  /// scroll infinito hacia arriba. Los inserta al inicio (los más viejos).
  Future<void> loadOlderMessages() async {
    if (_loadingOlder || !_hasMore || _messages.isEmpty) return;
    final oldest = _messages.first.createdAt;
    if (oldest == null) return;
    _loadingOlder = true;
    notifyListeners();
    try {
      final data = await SupabaseConfig.client
          .from('messages')
          .select('*')
          .or('from_user.eq.$myId,to_user.eq.$myId')
          .lt('created_at', oldest.toUtc().toIso8601String())
          .order('created_at', ascending: false)
          .limit(100);
      final rows = List<Map<String, dynamic>>.from(data as List);
      if (rows.isEmpty) {
        _hasMore = false;
      } else {
        final older = rows.reversed.map((row) {
          final m = Message.fromMap(row);
          return m.copyWith(localPath: _localPaths[m.id]);
        }).toList();
        _messages.insertAll(0, older);
        _state = ChatLoadState.data;
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _loadingOlder = false;
      notifyListeners();
    }
  }

  void subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = SupabaseConfig.client
        .channel('chat-$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            final msg = Message.fromMap(
              row,
              localPath: _localPaths[Message.fromMap(row).id],
            );
            if (msg.fromUser != myId && msg.toUser != myId) return;
            if (_messages.any((m) => m.id == msg.id)) return;
            _messages.add(msg);
            _state = ChatLoadState.data;
            notifyListeners();
            if (msg.toUser == myId) {
              markIncomingDelivered();
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final row = payload.newRecord;
            final updated = Message.fromMap(row);
            final idx = _messages.indexWhere((m) => m.id == updated.id);
            if (idx < 0) return;
            final local = _messages[idx].localPath ?? _localPaths[updated.id];
            _messages[idx] = updated.copyWith(localPath: local);
            notifyListeners();
          },
        )
        .subscribe();
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
    await _insertMessage({
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
    if (partnerId.isEmpty) return;
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final cached = await media.copyToLocalCache(
        sourcePath: localPath,
        preferredName: fileName,
      );
      final storagePath = await media.uploadFile(
        localPath: cached,
        ownerId: myId,
        fileName: fileName,
      );
      final row = await SupabaseConfig.client
          .from('messages')
          .insert({
            'from_user': myId,
            'to_user': partnerId,
            'content': caption.trim().isEmpty ? fileName : caption.trim(),
            'message_type': messageType,
            'attachment_url': storagePath,
            'attachment_name': fileName,
            'attachment_mime': mimeType,
            'attachment_size': size,
            'cloud_deleted': false,
            if (_replyTo != null) 'reply_to_id': _replyTo!.id,
            if (_replyTo != null) 'reply_content': _replyTo!.previewText,
          })
          .select()
          .single();
      final inserted =
          Message.fromMap(Map<String, dynamic>.from(row as Map));
      await media.bindLocalPath(
        messageId: inserted.id,
        localPath: cached,
        fileName: fileName,
        mimeType: mimeType,
      );
      _localPaths[inserted.id] = cached;
      final withLocal = inserted.copyWith(localPath: cached);
      if (!_messages.any((m) => m.id == withLocal.id)) {
        _messages.add(withLocal);
      } else {
        final idx = _messages.indexWhere((m) => m.id == withLocal.id);
        _messages[idx] = withLocal;
      }
      _replyTo = null;
      _state = ChatLoadState.data;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<Message?> _insertMessage(Map<String, dynamic> payload) async {
    _sending = true;
    _error = null;
    notifyListeners();
    try {
      final row = await SupabaseConfig.client
          .from('messages')
          .insert(payload)
          .select()
          .single();
      final msg = Message.fromMap(Map<String, dynamic>.from(row as Map));
      if (!_messages.any((m) => m.id == msg.id)) {
        _messages.add(msg);
      }
      _replyTo = null;
      _state = ChatLoadState.data;
      notifyListeners();
      return msg;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> toggleReaction(Message msg, String key) async {
    final next = msg.toggleReaction(userId: myId, key: key);
    if (identical(next, msg) &&
        !msg.canAddReactionKey(key) &&
        msg.myReactionKey(myId) != key) {
      _error = 'Maximo 5 reacciones por mensaje';
      notifyListeners();
      return;
    }
    final idx = _messages.indexWhere((m) => m.id == msg.id);
    if (idx >= 0) {
      _messages[idx] = next;
      notifyListeners();
    }
    try {
      // Merge atómico en el servidor (RPC toggle_reaction): evita que dos
      // reacciones simultáneas se pisen (race de "último write gana").
      final res = await SupabaseConfig.client.rpc(
        'toggle_reaction',
        params: {
          'target_table': 'messages',
          'target_col': 'reactions',
          'row_id': msg.id,
          'reaction_key': key,
          'user_id': myId,
        },
      );
      if (res != null) {
        final authoritative = Message.parseReactions(res);
        final li = _messages.indexWhere((m) => m.id == msg.id);
        if (li >= 0) {
          _messages[li] = _messages[li].copyWith(reactions: authoritative);
          notifyListeners();
        }
      }
    } catch (e) {
      if (idx >= 0) {
        _messages[idx] = msg;
      }
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> downloadMedia(Message msg) async {
    if (!msg.needsCloudDownload || msg.attachmentUrl == null) return;
    if (_downloading.contains(msg.id)) return;
    _downloading.add(msg.id);
    notifyListeners();
    try {
      final local = await media.downloadAndKeepLocal(
        messageId: msg.id,
        storagePath: msg.attachmentUrl!,
        fileName: msg.attachmentName,
        mimeType: msg.attachmentMime,
      );
      _localPaths[msg.id] = local;
      final idx = _messages.indexWhere((m) => m.id == msg.id);
      if (idx >= 0) {
        _messages[idx] = _messages[idx].copyWith(localPath: local);
      }
      notifyListeners();

      // Solo el receptor borra de la nube tras descargar.
      if (msg.toUser == myId && !msg.cloudDeleted) {
        await media.deleteFromCloud(msg.attachmentUrl!);
        await SupabaseConfig.client.from('messages').update({
          'attachment_url': null,
          'cloud_deleted': true,
        }).eq('id', msg.id);
        if (idx >= 0) {
          _messages[idx] = _messages[idx].copyWith(
            cloudDeleted: true,
            clearAttachmentUrl: true,
            localPath: local,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _downloading.remove(msg.id);
      notifyListeners();
    }
  }

  Future<void> markIncomingRead() async {
    final unread = _messages
        .where((m) => m.toUser == myId && !m.read)
        .map((m) => m.id)
        .toList();
    if (unread.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await SupabaseConfig.client.from('messages').update({
        'read': true,
        'read_at': now,
      }).inFilter('id', unread);
      for (var i = 0; i < _messages.length; i++) {
        if (unread.contains(_messages[i].id)) {
          _messages[i] = _messages[i].copyWith(read: true, readAt: DateTime.now());
        }
      }
      notifyListeners();
    } catch (e) {
      developer.log('markIncomingRead fallo: $e');
    }
  }

  /// Marca como entregados (delivered_at) los mensajes recibidos por realtime
  /// que todavia no estan marcados. No los marca como leidos: eso solo ocurre
  /// cuando el usuario abre el chat (markIncomingRead).
  Future<void> markIncomingDelivered() async {
    final undelivered = _messages
        .where((m) => m.toUser == myId && m.deliveredAt == null)
        .map((m) => m.id)
        .toList();
    if (undelivered.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      await SupabaseConfig.client.from('messages').update({
        'delivered_at': now,
      }).inFilter('id', undelivered);
      for (var i = 0; i < _messages.length; i++) {
        if (undelivered.contains(_messages[i].id)) {
          _messages[i] =
              _messages[i].copyWith(deliveredAt: DateTime.now());
        }
      }
      notifyListeners();
    } catch (e) {
      developer.log('markIncomingDelivered fallo: $e');
    }
  }


  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Indicador "escribiendo...": escucha la fila de la pareja en `chat_typing`.
  void subscribeTyping() {
    if (partnerId.isEmpty) return;
    _typingChannel?.unsubscribe();
    _typingChannel = SupabaseConfig.client
        .channel('typing-$myId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_typing',
          callback: (payload) {
            final row = payload.newRecord as Map<String, dynamic>? ?? const {};
            if (row['user_id'] != partnerId) return;
            final active = row['is_typing'] == true;
            if (active) {
              // La pareja está escribiendo: encendemos el indicador y armamos
              // un timeout de seguridad. Si en 4s no llega un nuevo "true"
              // (p. ej. se perdió el "false" por red), lo apagamos solos para
              // no dejar "escribiendo..." eterno en pantalla.
              _typingReceiverTimer?.cancel();
              _typingReceiverTimer = Timer(const Duration(seconds: 4), () {
                if (_partnerTyping) {
                  _partnerTyping = false;
                  notifyListeners();
                }
              });
              if (!_partnerTyping) {
                _partnerTyping = true;
                notifyListeners();
              }
            } else {
              // "false" explícito: apagar en el acto y cancelar el timeout.
              _typingReceiverTimer?.cancel();
              if (_partnerTyping) {
                _partnerTyping = false;
                notifyListeners();
              }
            }
          },
        )
        .subscribe();
  }

  /// Publica mi estado de escritura. Con auto-clear tras 1.5s sin escribir.
  void notifyTyping(bool typing) {
    if (partnerId.isEmpty) return;
    _typingDebounce?.cancel();
    if (typing) {
      _typingDebounce = Timer(const Duration(milliseconds: 1500), _clearTyping);
    } else {
      _typingDebounce?.cancel();
    }
    _upsertTyping(typing);
  }

  Future<void> _upsertTyping(bool typing) async {
    try {
      await SupabaseConfig.client.from('chat_typing').upsert({
        'user_id': myId,
        'is_typing': typing,
      }, onConflict: 'user_id');
    } catch (e) {
      developer.log('notifyTyping fallo: $e');
    }
  }

  void _clearTyping() {
    _typingDebounce?.cancel();
    _upsertTyping(false);
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _typingReceiverTimer?.cancel();
    _typingChannel?.unsubscribe();
    _channel?.unsubscribe();
    super.dispose();
  }
}
