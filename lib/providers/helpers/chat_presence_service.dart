import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../supabase_config.dart';

class ChatPresenceService {
  final String myId;
  final String partnerId;
  final VoidCallback onNotify;

  ChatPresenceService({
    required this.myId,
    required this.partnerId,
    required this.onNotify,
  });

  bool _isPartnerOnline = false;
  DateTime? _partnerLastSeen;
  bool _partnerTyping = false;
  Timer? _typingDebounce;
  Timer? _typingReceiverTimer;
  RealtimeChannel? _typingChannel;
  RealtimeChannel? _presenceChannel;
  Timer? _presenceHeartbeatTimer;

  bool get isPartnerOnline => _isPartnerOnline;
  DateTime? get partnerLastSeen => _partnerLastSeen;
  bool get partnerTyping => _partnerTyping;

  String get partnerStatusText {
    if (partnerTyping) return 'escribiendo...';
    if (_isPartnerOnline) return 'en línea';
    final lastSeen = _partnerLastSeen;
    if (lastSeen == null) return 'desconectado';
    return formatLastSeen(lastSeen);
  }

  static String formatLastSeen(DateTime dt, {DateTime? clockNow}) {
    final now = clockNow ?? DateTime.now();
    final localDt = dt.toLocal();
    final localNow = now.toLocal();

    final isToday = localDt.year == localNow.year &&
        localDt.month == localNow.month &&
        localDt.day == localNow.day;

    final yesterday = localNow.subtract(const Duration(days: 1));
    final isYesterday = localDt.year == yesterday.year &&
        localDt.month == yesterday.month &&
        localDt.day == yesterday.day;

    final hour = localDt.hour.toString().padLeft(2, '0');
    final minute = localDt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    if (isToday) {
      return 'últ. vez hoy a las $timeStr';
    } else if (isYesterday) {
      return 'últ. vez ayer a las $timeStr';
    } else if (localDt.year == localNow.year) {
      final day = localDt.day.toString().padLeft(2, '0');
      final month = localDt.month.toString().padLeft(2, '0');
      return 'últ. vez $day/$month a las $timeStr';
    } else {
      final day = localDt.day.toString().padLeft(2, '0');
      final month = localDt.month.toString().padLeft(2, '0');
      final year = localDt.year.toString();
      return 'últ. vez $day/$month/$year';
    }
  }

  void setPartnerOnlineForTest(bool online, {DateTime? lastSeen}) {
    _isPartnerOnline = online;
    if (lastSeen != null) {
      _partnerLastSeen = lastSeen;
    }
    onNotify();
  }

  void setPartnerTypingForTest(bool typing) {
    _partnerTyping = typing;
    onNotify();
  }

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

            if (row['updated_at'] != null) {
              final dt = DateTime.tryParse(row['updated_at'] as String);
              if (dt != null) {
                _partnerLastSeen = dt.toLocal();
              }
            }

            final active = row['is_typing'] == true;
            if (active) {
              _typingReceiverTimer?.cancel();
              _typingReceiverTimer = Timer(const Duration(seconds: 4), () {
                if (_partnerTyping) {
                  _partnerTyping = false;
                  onNotify();
                }
              });
              if (!_partnerTyping) {
                _partnerTyping = true;
                onNotify();
              }
            } else {
              _typingReceiverTimer?.cancel();
              if (_partnerTyping) {
                _partnerTyping = false;
                onNotify();
              }
            }
          },
        )
        .subscribe();
  }

  Future<void> loadPartnerPresence() async {
    if (partnerId.isEmpty) return;
    try {
      final row = await SupabaseConfig.client
          .from('chat_typing')
          .select('updated_at')
          .eq('user_id', partnerId)
          .maybeSingle();
      if (row != null && row['updated_at'] != null) {
        final dt = DateTime.tryParse(row['updated_at'] as String);
        if (dt != null) {
          _partnerLastSeen = dt.toLocal();
          onNotify();
        }
      }
    } catch (e) {
      developer.log('loadPartnerPresence error: $e');
    }
  }

  void subscribePresence() {
    if (myId.isEmpty) return;
    _presenceChannel?.unsubscribe();
    _presenceChannel = SupabaseConfig.client.channel('presence-furi');

    _presenceChannel!
        .onPresenceSync((_) {
          _updatePresenceFromState();
        })
        .onPresenceJoin((payload) {
          final joinedPartner =
              payload.newPresences.any((p) => p.payload['user_id'] == partnerId);
          if (joinedPartner) {
            _isPartnerOnline = true;
            onNotify();
          }
        })
        .onPresenceLeave((payload) {
          final leftPartner =
              payload.leftPresences.any((p) => p.payload['user_id'] == partnerId);
          if (leftPartner) {
            _isPartnerOnline = false;
            _partnerLastSeen = DateTime.now();
            onNotify();
          }
        })
        .subscribe((status, [err]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _trackMyPresence(true);
          }
        });

    _startPresenceHeartbeat();
  }

  void _updatePresenceFromState() {
    if (_presenceChannel == null) return;
    final states = _presenceChannel!.presenceState();
    bool foundPartner = false;
    for (final s in states) {
      for (final p in s.presences) {
        if (p.payload['user_id'] == partnerId) {
          foundPartner = true;
          break;
        }
      }
      if (foundPartner) break;
    }
    if (_isPartnerOnline != foundPartner) {
      _isPartnerOnline = foundPartner;
      if (!foundPartner && _partnerLastSeen == null) {
        _partnerLastSeen = DateTime.now();
      }
      onNotify();
    }
  }

  Future<void> _trackMyPresence(bool online) async {
    if (myId.isEmpty) return;
    try {
      if (online) {
        await _presenceChannel?.track({
          'user_id': myId,
          'online_at': DateTime.now().toUtc().toIso8601String(),
        });
        await _touchMyLastSeen();
      } else {
        await _presenceChannel?.untrack();
        await _touchMyLastSeen();
      }
    } catch (e) {
      developer.log('trackMyPresence error: $e');
    }
  }

  Future<void> _touchMyLastSeen() async {
    if (myId.isEmpty) return;
    try {
      await SupabaseConfig.client.from('chat_typing').upsert({
        'user_id': myId,
        'is_typing': false,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      developer.log('touchMyLastSeen error: $e');
    }
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (myId.isNotEmpty) {
        _touchMyLastSeen();
      }
    });
  }

  void handleLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _trackMyPresence(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _trackMyPresence(false);
    }
  }

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
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id');
    } catch (e) {
      developer.log('notifyTyping fallo: $e');
    }
  }

  void _clearTyping() {
    _typingDebounce?.cancel();
    _upsertTyping(false);
  }

  void dispose() {
    _presenceHeartbeatTimer?.cancel();
    _presenceChannel?.untrack();
    _presenceChannel?.unsubscribe();
    _typingDebounce?.cancel();
    _typingReceiverTimer?.cancel();
    _typingChannel?.unsubscribe();
  }
}
