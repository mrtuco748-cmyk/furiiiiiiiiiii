import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../models/letter.dart';
import '../theme/app_theme.dart';
import '../widgets/loca_screen.dart';
import '../widgets/app_feedback.dart';
import 'letters/helpers/letters_service.dart';
import 'letters/widgets/letter_compose_view.dart';
import 'letters/widgets/letter_detail_panel.dart';
import 'letters/widgets/letter_dialogs.dart';
import 'letters/widgets/letters_history_panel.dart';

const _cSent = Color(0xFF00F0FF);
const _black = Color(0xFF000000);
const _gold = Color(0xFFFFD700);

class LettersScreen extends StatefulWidget {
  final AppMode mode;
  final String name;
  const LettersScreen({super.key, required this.mode, required this.name});

  @override
  State<LettersScreen> createState() => _LettersScreenState();
}

enum _PageState { loading, error, data }

class _LettersScreenState extends State<LettersScreen> {
  _PageState _state = _PageState.loading;
  List<Map<String, dynamic>> _inboxLetters = const [];
  List<Map<String, dynamic>> _sentLetters = const [];
  final Set<int> _readLocal = {};
  bool _composing = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadReadLocal();
    _loadLetters();
    _channel = LettersService.subscribeToChanges(() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _loadLetters();
      });
    });
  }

  Future<void> _loadReadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs
          .getKeys()
          .where((k) => k.startsWith('readLetter-'))
          .map((k) => int.tryParse(k.replaceFirst('readLetter-', '')))
          .whereType<int>()
          .where((v) => v > 0)
          .toList();
      if (!mounted) return;
      setState(() => _readLocal.addAll(ids));
    } catch (_) {}
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadLetters() async {
    if (_inboxLetters.isEmpty && _sentLetters.isEmpty) {
      final inbox = await LettersService.getCachedInbox();
      final sent = await LettersService.getCachedSent();
      if (mounted && (inbox.isNotEmpty || sent.isNotEmpty)) {
        setState(() {
          if (inbox.isNotEmpty) _inboxLetters = inbox;
          if (sent.isNotEmpty) _sentLetters = sent;
          _state = _PageState.data;
        });
      }
    }
    try {
      final results = await Future.wait([
        LettersService.loadInbox(),
        LettersService.loadSent(),
      ]);
      if (!mounted) return;
      _inboxLetters = results[0];
      _sentLetters = results[1];
      setState(() => _state = _PageState.data);
      await LettersService.cacheLetters(
        inbox: _inboxLetters,
        sent: _sentLetters,
      );
    } catch (e) {
      if (!mounted) return;
      if (_inboxLetters.isEmpty && _sentLetters.isEmpty) {
        setState(() => _state = _PageState.error);
      }
    }
  }

  Future<void> _sendLetter(
      String title, String body, DateTime? scheduledOpen) async {
    HapticFeedback.heavyImpact();
    try {
      await LettersService.sendLetter(
        title: title,
        body: body,
        scheduledOpen: scheduledOpen,
      );
      setState(() => _composing = false);
      _loadLetters();
      if (mounted) AppFeedback.saved(context, 'Carta enviada');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo enviar la carta',
                style: GoogleFonts.bangers(color: Colors.white)),
            backgroundColor: const Color(0xFFCC0000),
          ),
        );
      }
    }
  }

  DateTime? _scheduledOpenOf(Map<String, dynamic> letter) {
    final raw = letter['scheduled_open'];
    return raw == null ? null : DateTime.tryParse(raw.toString());
  }

  bool _isSealed(Map<String, dynamic> letter, {required bool incoming}) =>
      Letter.isSealed(
        scheduledOpen: _scheduledOpenOf(letter),
        isIncoming: incoming,
      );

  bool _isReadByMe(Map<String, dynamic> letter) {
    final id = (letter['id'] as num?)?.toInt();
    if (id != null && _readLocal.contains(id)) return true;
    final seen = (letter['seen_by'] as List?)?.cast<String>() ?? <String>[];
    return seen.contains(AppState.myId);
  }

  Future<void> _markReadLocal(int id) async {
    if (id <= 0 || _readLocal.contains(id)) return;
    setState(() => _readLocal.add(id));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('readLetter-$id', true);
    } catch (_) {}
  }

  Future<void> _finishEditLetter(int id, String newTitle, String newBody) async {
    if (newTitle.isEmpty || newBody.isEmpty) return;
    try {
      await LettersService.updateLetter(
        id: id,
        title: newTitle,
        content: newBody,
      );
      _loadLetters();
      if (mounted) AppFeedback.saved(context, 'Carta editada');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar la edición',
                style: GoogleFonts.bangers(color: Colors.white)),
            backgroundColor: const Color(0xFFCC0000),
          ),
        );
      }
    }
  }

  void _onTapHistoryCard(Map<String, dynamic> letter, bool incoming) {
    LetterDialogs.handleCardTap(
      context: context,
      letter: letter,
      incoming: incoming,
      isSealed: _isSealed(letter, incoming: true),
      isReadByMe: _isReadByMe(letter),
      myId: AppState.myId,
      onMarkRead: _markReadLocal,
      onSaveSent: _finishEditLetter,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_composing) {
      return LetterComposeView(
        onClose: () => setState(() => _composing = false),
        onSend: _sendLetter,
      );
    }
    final t = getTheme(widget.mode);
    final shownInbox = _inboxLetters.take(6).toList();
    final entries = <LocaEntry>[
      if (_state == _PageState.error)
        LocaEntry(
          icon: Icons.cloud_off,
          color: const Color(0xFFFF4444),
          iconColor: Colors.white,
          label: 'reintentar',
          onTap: () {
            HapticFeedback.heavyImpact();
            _loadLetters();
          },
          isAction: true,
        ),
      for (var i = 0; i < shownInbox.length; i++)
        LocaEntry(
          icon: LetterDetailPanel.iconFor(
            isSealed: _isSealed(shownInbox[i], incoming: true),
            isRead: _isReadByMe(shownInbox[i]),
          ),
          color: LetterDetailPanel.colorFor(
            index: i,
            isSealed: _isSealed(shownInbox[i], incoming: true),
          ),
          iconColor: LetterDetailPanel.iconColorFor(
            isSealed: _isSealed(shownInbox[i], incoming: true),
          ),
          label: shownInbox[i]['title']?.toString() ?? '',
          childBuilder: (_) => LetterMosaicChild(
            letter: shownInbox[i],
            icon: LetterDetailPanel.iconFor(
              isSealed: _isSealed(shownInbox[i], incoming: true),
              isRead: _isReadByMe(shownInbox[i]),
            ),
            iconColor: LetterDetailPanel.iconColorFor(
              isSealed: _isSealed(shownInbox[i], incoming: true),
            ),
            isSealed: _isSealed(shownInbox[i], incoming: true),
          ),
          panel: i,
        ),
      LocaEntry(
        icon: Icons.history,
        color: _cSent,
        iconColor: _black,
        label: 'historial',
        panel: shownInbox.length,
        isAction: true,
      ),
      LocaEntry(
        icon: Icons.create,
        color: _gold,
        iconColor: _black,
        label: 'escribir',
        onTap: () {
          HapticFeedback.heavyImpact();
          setState(() => _composing = true);
        },
        isAction: true,
      ),
    ];
    return LocaScreen(
      seed: 13,
      theme: t,
      entries: entries,
      panels: [
        for (var i = 0; i < shownInbox.length; i++)
          (_, close) => LetterDetailPanel(
                close: close,
                letter: shownInbox[i],
                isSealed: _isSealed(shownInbox[i], incoming: true),
                openAt: _scheduledOpenOf(shownInbox[i]),
                onOpened: () => _markReadLocal(
                    (shownInbox[i]['id'] as num?)?.toInt() ?? -1),
              ),
        (_, close) => LettersHistoryPanel(
              close: close,
              isLoading: _state == _PageState.loading,
              hasError: _state == _PageState.error,
              onRetry: _loadLetters,
              inboxLetters: _inboxLetters,
              sentLetters: _sentLetters,
              isSealed: _isSealed,
              isReadByMe: _isReadByMe,
              onTapCard: _onTapHistoryCard,
            ),
      ],
    );
  }
}
