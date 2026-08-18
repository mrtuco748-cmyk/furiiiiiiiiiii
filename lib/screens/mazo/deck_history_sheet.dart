import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/deck_card.dart';
import '../../providers/deck_provider.dart';
import 'deck_style.dart';

Future<void> showDeckHistorySheet(
  BuildContext context, {
  required void Function(DeckCard card) onReswipe,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => DeckHistorySheet(onReswipe: onReswipe),
  );
}

class DeckHistorySheet extends StatelessWidget {
  final void Function(DeckCard card) onReswipe;
  const DeckHistorySheet({super.key, required this.onReswipe});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeckProvider>(
      builder: (context, pv, _) {
        final history = pv.historyFor(AppState.myId);
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            border: Border(
                top: BorderSide(color: Color(0xFF1A1A1A), width: 3)),
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(children: [
                Text('HISTORIAL',
                    style: GoogleFonts.bangers(
                        color: const Color(0xFF9D00FF),
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D00FF),
                      border:
                          Border.all(color: const Color(0xFF9D00FF), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close,
                        color: Color(0xFF1A1A1A), size: 18),
                  ),
                ),
              ]),
            ),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Text('Todavía no deslizaste ninguna tarjeta',
                    style: TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 13,
                        fontFamily: 'monospace')),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                  itemCount: history.length,
                  itemBuilder: (context, i) => _historyRow(
                      context, pv, history[i]),
                ),
              ),
          ]),
        );
      },
    );
  }

  Widget _historyRow(BuildContext context, DeckProvider pv, DeckCard card) {
    final cat = DeckCategoryStyle.of(card.category);
    final mine = card.reactionOf(AppState.myId);
    final partnerReactions = card.reactions.entries
        .where((e) => e.key != AppState.myId)
        .map((e) => e.value)
        .toList();
    final myStyle =
        mine == null ? null : DeckReactionStyle.of(mine);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cat.color,
        border: Border.all(color: cat.color, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(cat.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(card.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          if (myStyle != null) ...[
            Icon(myStyle.icon,
                color: const Color(0xFF1A1A1A), size: 18),
            const SizedBox(width: 6),
            Text(myStyle.label,
                style: const TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 11,
                    fontFamily: 'monospace')),
          ],
          const SizedBox(width: 12),
          if (partnerReactions.isNotEmpty) ...[
            const Text('tu pareja: ',
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 11,
                    fontFamily: 'monospace')),
            ...partnerReactions
                .map((r) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(DeckReactionStyle.of(r).icon,
                          color: const Color(0xFF1A1A1A), size: 16),
                    )),
          ],
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onReswipe(card);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF9D00FF),
                border: Border.all(color: const Color(0xFF9D00FF), width: 2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.swap_horiz,
                  color: Color(0xFF1A1A1A), size: 20),
            ),
          ),
        ]),
      ]),
    );
  }
}
