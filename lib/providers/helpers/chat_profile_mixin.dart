import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_state.dart';
import '../../supabase_config.dart';

mixin ChatProfileMixin on ChangeNotifier {
  String get myId;
  String get partnerId;

  String _partnerName = '';
  String? _myAvatarUrl;
  String? _partnerAvatarUrl;
  RealtimeChannel? _profilesChannel;

  String get partnerName => _partnerName;
  String? get myAvatarUrl => _myAvatarUrl ?? AppState.myAvatarUrl;
  String? get partnerAvatarUrl => _partnerAvatarUrl ?? AppState.partnerAvatarUrl;

  Future<void> loadProfiles() async {
    try {
      if (partnerId.isNotEmpty) {
        final pData = await SupabaseConfig.client
            .from('profiles')
            .select('name, avatar_url')
            .eq('id', partnerId)
            .maybeSingle();
        if (pData != null) {
          final n = pData['name'] as String?;
          if (n != null && n.isNotEmpty) _partnerName = n;
          _partnerAvatarUrl = pData['avatar_url'] as String?;
          AppState.partnerAvatarUrl = _partnerAvatarUrl;
        }
      }
      if (myId.isNotEmpty) {
        final mData = await SupabaseConfig.client
            .from('profiles')
            .select('avatar_url')
            .eq('id', myId)
            .maybeSingle();
        if (mData != null) {
          _myAvatarUrl = mData['avatar_url'] as String?;
          AppState.myAvatarUrl = _myAvatarUrl;
        }
      }
      await AppState.saveSession();
      notifyListeners();
    } catch (e) {
      developer.log('loadProfiles error: $e');
    }
  }

  Future<void> updateMyAvatar(String avatarData) async {
    if (myId.isEmpty) return;
    _myAvatarUrl = avatarData;
    AppState.myAvatarUrl = avatarData;
    await AppState.saveSession();
    notifyListeners();

    try {
      await SupabaseConfig.client
          .from('profiles')
          .update({'avatar_url': avatarData})
          .eq('id', myId);
    } catch (e) {
      developer.log('updateMyAvatar error: $e');
    }
  }

  void subscribeProfiles() {
    _profilesChannel?.unsubscribe();
    _profilesChannel = SupabaseConfig.client.channel('profiles-realtime');
    _profilesChannel!
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'profiles',
        callback: (payload) {
          final record = payload.newRecord;
          final id = record['id'] as String?;
          if (id == partnerId) {
            final newAvatar = record['avatar_url'] as String?;
            final newName = record['name'] as String?;
            if (newName != null && newName.isNotEmpty) _partnerName = newName;
            _partnerAvatarUrl = newAvatar;
            AppState.partnerAvatarUrl = newAvatar;
            notifyListeners();
          } else if (id == myId) {
            final newAvatar = record['avatar_url'] as String?;
            _myAvatarUrl = newAvatar;
            AppState.myAvatarUrl = newAvatar;
            notifyListeners();
          }
        },
      )
      .subscribe();
  }

  Future<void> loadPartnerName() => loadProfiles();

  void disposeProfiles() {
    _profilesChannel?.unsubscribe();
  }
}
