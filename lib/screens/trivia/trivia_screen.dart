import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/trivia_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/add_question_screen.dart';
import 'widgets/history_screen.dart';
import 'widgets/trivia_deck.dart';
import 'widgets/trivia_status_screens.dart';

/// Trivia de pareja: interfaz limpia, moderna y sin bordes,
/// con selector de respuesta y predicción paso a paso.
class TriviaScreen extends StatefulWidget {
  final AppMode mode;
  const TriviaScreen({super.key, required this.mode});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  bool _showAdd = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TriviaProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = getTheme(widget.mode);
    return Consumer<TriviaProvider>(
      builder: (context, pv, _) {
        if (_showAdd) {
          return AddQuestionScreen(
            theme: t,
            provider: pv,
            onClose: () => setState(() => _showAdd = false),
          );
        }
        if (_showHistory) {
          return HistoryScreen(
            theme: t,
            provider: pv,
            onClose: () => setState(() => _showHistory = false),
          );
        }

        if (pv.loading && pv.questions.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            body: LoadingScreen(theme: t),
          );
        }
        if (pv.hasError && pv.questions.isEmpty) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0A),
            body: ErrorScreen(
              theme: t,
              message: pv.error ?? 'Error al cargar',
              onRetry: () => pv.load(),
            ),
          );
        }

        final unanswered = pv.unansweredQuestions;
        final answered = pv.answeredQuestions;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TRIVIA',
                  style: GoogleFonts.bangers(
                    fontSize: 22,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Vos ${pv.myScore} · ${pv.partnerScore} Pareja',
                    style: GoogleFonts.bangers(
                      fontSize: 13,
                      color: const Color(0xFF39FF14),
                    ),
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                tooltip: 'Historial',
                onPressed: answered.isEmpty ? null : () => setState(() => _showHistory = true),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Nueva pregunta',
                onPressed: () => setState(() => _showAdd = true),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: unanswered.isEmpty
              ? EmptyScreen(
                  theme: t,
                  onAdd: () => setState(() => _showAdd = true),
                  onHistory: answered.isNotEmpty ? () => setState(() => _showHistory = true) : null,
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: TriviaDeck(
                      questions: unanswered,
                      provider: pv,
                      theme: t,
                      onQuestionAnswered: () {
                        // Consumer se reconstruye automáticamente
                      },
                    ),
                  ),
                ),
        );
      },
    );
  }
}
