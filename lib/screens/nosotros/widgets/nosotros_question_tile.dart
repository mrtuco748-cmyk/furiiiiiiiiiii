import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';

class NosotrosQuestionTile extends StatelessWidget {
  final Map<String, dynamic> questionData;
  final ThemeSet theme;
  final String myId;
  final String myInitial;
  final String partnerInitial;
  final void Function(Map<String, dynamic> q) onSelectQuestion;
  final void Function(dynamic id) onDeleteQuestion;

  const NosotrosQuestionTile({
    super.key,
    required this.questionData,
    required this.theme,
    required this.myId,
    required this.myInitial,
    required this.partnerInitial,
    required this.onSelectQuestion,
    required this.onDeleteQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final q = questionData;
    final question = q['question'] as String? ?? '';
    final answer = q['answer'] as String?;
    final fromMe = q['from_user'] == myId;
    final isAnswered = answer != null && answer.isNotEmpty;
    final qToUser = q['to_user'] as String?;
    final answererInitial = qToUser == myId ? myInitial : partnerInitial;
    final askerInitial = fromMe ? myInitial : partnerInitial;

    return GestureDetector(
      onTap: () {
        if (!isAnswered && !fromMe) {
          HapticFeedback.heavyImpact();
          onSelectQuestion(q);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: t.dark.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fromMe ? const Color(0xFF00F0FF) : const Color(0xFFFF66C4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(askerInitial, style: GoogleFonts.bangers(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(width: 4),
              Expanded(child: Text(question, style: GoogleFonts.bangers(color: t.light, fontSize: 12))),
              if (fromMe)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    onDeleteQuestion(q['id']);
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.close, color: Color(0xFFFF4444), size: 16),
                  ),
                ),
            ]),
            if (isAnswered)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('$answererInitial: $answer', style: GoogleFonts.bangers(color: t.d, fontSize: 11)),
              ),
            if (!isAnswered && !fromMe)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Toca para responder', style: GoogleFonts.bangers(color: t.d.withValues(alpha: 0.7), fontSize: 10)),
              ),
          ]),
        ),
      ),
    );
  }
}
