import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/trivia.dart';
import '../../../providers/trivia_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';

/// Pantalla de historial
class HistoryScreen extends StatefulWidget {
  final ThemeSet theme;
  final TriviaProvider provider;
  final VoidCallback onClose;
  const HistoryScreen({
    super.key,
    required this.theme,
    required this.provider,
    required this.onClose,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final pv = widget.provider;
    final t = widget.theme;
    final myAnswers = pv.answers.where((a) => a.userId == pv.myId).toList();
    myAnswers.sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

    // Agrupar por pregunta para mostrar respuesta de la pareja
    final partnerAnswers = <int, TriviaAnswer>{};
    for (final a in pv.answers) {
      if (a.userId == pv.partnerId && a.answer.isNotEmpty) {
        partnerAnswers[a.questionId] = a;
      }
    }

    final questionsMap = <int, TriviaQuestion>{};
    for (final q in pv.questions) {
      if (q.id != null) questionsMap[q.id!] = q;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: TapTile(
          onTap: widget.onClose,
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF9D00FF),
              border: Border.all(color: const Color(0xFF9D00FF), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
        ),
        title: Text('Historial', style: GoogleFonts.bangers(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: myAnswers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history, color: Colors.white54, size: 56),
                  const SizedBox(height: 16),
                  Text('Sin respuestas aún',
                      style: GoogleFonts.bangers(color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Respondé preguntas para ver el historial',
                      style: GoogleFonts.bangers(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: myAnswers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => HistoryItem(
                theme: t,
                myAnswer: myAnswers[i],
                question: questionsMap[myAnswers[i].questionId],
                partnerAnswer: partnerAnswers[myAnswers[i].questionId],
              ),
            ),
    );
  }
}

class HistoryItem extends StatelessWidget {
  final ThemeSet theme;
  final TriviaAnswer myAnswer;
  final TriviaQuestion? question;
  final TriviaAnswer? partnerAnswer;
  const HistoryItem({
    super.key,
    required this.theme,
    required this.myAnswer,
    this.question,
    this.partnerAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final guessed = myAnswer.guess;
    final real = partnerAnswer?.answer;
    final hit = real != null && guessed != null && real == guessed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(color: const Color(0xFF333333), width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pregunta
          Text(question?.question ?? 'Pregunta',
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // Mi respuesta
          HistoryRow(
            label: 'Tu respuesta',
            value: myAnswer.answer,
            color: const Color(0xFF9D00FF),
          ),
          const SizedBox(height: 6),
          // Mi predicción
          HistoryRow(
            label: 'Tu predicción',
            value: guessed ?? '—',
            color: const Color(0xFF00D4FF),
          ),
          const SizedBox(height: 6),
          // Respuesta de la pareja
          HistoryRow(
            label: 'Respuesta de tu pareja',
            value: real ?? 'Sin responder',
            color: const Color(0xFFFF1493),
          ),
          if (guessed != null && real != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: hit ? const Color(0xFF39FF14) : const Color(0xFFFF0000),
                border: Border.all(color: hit ? const Color(0xFF39FF14) : const Color(0xFFFF0000), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(hit ? Icons.check_circle : Icons.cancel,
                      color: hit ? const Color(0xFF0A0A0A) : Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(hit ? '¡Acertaste!' : 'No acertaste',
                      style: GoogleFonts.bangers(
                          color: hit ? const Color(0xFF0A0A0A) : Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
          // Fecha
          if (myAnswer.date != null) ...[
            const SizedBox(height: 8),
            Text('Respondido el ${_formatDate(myAnswer.date!)}',
                style: GoogleFonts.bangers(color: Colors.white38, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${dt.day} ${meses[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class HistoryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const HistoryRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.bangers(color: color, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
