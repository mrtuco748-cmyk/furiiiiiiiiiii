import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static String? myId;
  static String? partnerId;
  static String? myName;
  static String? identity; // 'Rocio' or 'Facu'
  static String? myAvatarUrl;
  static String? partnerAvatarUrl;

  static String get partnerName => identity == 'Facu' ? 'Rocío' : 'Facu';

  static Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (identity != null) prefs.setString('identity', identity!);
    if (myId != null) prefs.setString('myId', myId!);
    if (partnerId != null) prefs.setString('partnerId', partnerId!);
    if (myName != null) prefs.setString('myName', myName!);
    if (myAvatarUrl != null) prefs.setString('myAvatarUrl', myAvatarUrl!);
    if (partnerAvatarUrl != null) prefs.setString('partnerAvatarUrl', partnerAvatarUrl!);
  }

  static Future<bool> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('identity');
    if (id == null) return false;
    identity = id;
    myId = prefs.getString('myId');
    partnerId = prefs.getString('partnerId');
    myName = prefs.getString('myName');
    myAvatarUrl = prefs.getString('myAvatarUrl');
    partnerAvatarUrl = prefs.getString('partnerAvatarUrl');
    return true;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    myId = null;
    partnerId = null;
    myName = null;
    identity = null;
    myAvatarUrl = null;
    partnerAvatarUrl = null;
  }
}
