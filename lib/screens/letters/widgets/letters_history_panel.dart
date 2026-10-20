import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/loca_screen.dart';
import '../../../widgets/tap_tile.dart';

const _cInbox = Color(0xFFFF1493);
const _cRead = Color(0xFF7A3E5A);
const _cSealed = Color(0xFFFFB300);
const _cSent = Color(0xFF00F0FF);
const _dark = Color(0xFF1A1A1A);
const _mid = Color(0xFF2A2A2A);

class LettersHistoryPanel extends StatelessWidget {
  final VoidCallback close;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;
  final List<Map<String, dynamic>> inboxLetters;
  final List<Map<String, dynamic>> sentLetters;
  final bool Function(Map<String, dynamic> letter, {required bool incoming})
      isSealed;
  final bool Function(Map<String, dynamic> letter) isReadByMe;
  final void Function(Map<String, dynamic> letter, bool incoming) onTapCard;

  const LettersHistoryPanel({
    super.key,
    required this.close,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.inboxLetters,
    required this.sentLetters,
    required this.isSealed,
    required this.isReadByMe,
    required this.onTapCard,
  });

  Widget _sectionHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Icon(Icons.label, color: _cSent.withValues(alpha: 0.7), size: 14),
          const SizedBox(width: 6),
          Text(
            '$label  ·  $count',
            style: GoogleFonts.bangers(color: _cSent, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(Map<String, dynamic> letter, {required bool incoming}) {
    final title = letter['title']?.toString() ?? '';
    final body = letter['content']?.toString() ?? '';
    final sealed = incoming && isSealed(letter, incoming: true);
    final read = incoming && isReadByMe(letter);
    final color =
        incoming ? (sealed ? _cSealed : (read ? _cRead : _cInbox)) : _cSent;

    return TapTile(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTapCard(letter, incoming);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _dark,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Icon(
                incoming
                    ? (sealed
                        ? Icons.mail_lock
                        : (read ? Icons.mark_email_read : Icons.markunread))
                    : Icons.mail,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body.length > 60 ? '${body.substring(0, 60)}...' : body,
                        style: GoogleFonts.bangers(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: color.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyBody() {
    if (isLoading) {
      return const Center(
        child: Icon(Icons.hourglass_top, color: _cSent, size: 60),
      );
    }
    if (hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: _cSent, size: 60),
            const SizedBox(height: 12),
            TapTile(
              onTap: () {
                HapticFeedback.heavyImpact();
                onRetry();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _cSent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        _sectionHeader('RECIBIDAS', inboxLetters.length),
        if (inboxLetters.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Icon(Icons.markunread,
                  color: Color(0x66FFFFFF), size: 48),
            ),
          )
        else
          ...inboxLetters.map((l) => _historyCard(l, incoming: true)),
        const SizedBox(height: 12),
        _sectionHeader('ENVIADAS', sentLetters.length),
        if (sentLetters.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Icon(Icons.send_outlined,
                  color: Color(0x66FFFFFF), size: 48),
            ),
          )
        else
          ...sentLetters.map((l) => _historyCard(l, incoming: false)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LocaScreen.panel(
      color: _mid,
      borderColor: _cSent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                const Icon(Icons.history, color: _cSent, size: 22),
                const Spacer(),
                LocaScreen.closeIcon(close, _cSent, Icons.close),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _historyBody()),
        ],
      ),
    );
  }
}
