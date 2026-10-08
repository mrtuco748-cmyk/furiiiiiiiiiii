import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/trivia_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/add_question_screen.dart';
import 'widgets/history_screen.dart';
import 'widgets/trivia_deck.dart';
import 'widgets/trivia_status_screens.dart';

/// Trivia de pareja estilo "Nosotros": mazo de preguntas sin responder,
/// se deslizan para navegar. Al responder, pasan al historial.
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
        final unanswered = pv.unansweredQuestions;
        final answered = pv.answeredQuestions;

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

        if (pv.loading) {
          return LoadingScreen(theme: t);
        }
        if (pv.hasError) {
          return ErrorScreen(
            theme: t,
            message: pv.error ?? 'Error al cargar',
            onRetry: () => pv.load(),
          );
        }

        if (unanswered.isEmpty && answered.isEmpty) {
          return EmptyScreen(theme: t, onAdd: () => setState(() => _showAdd = true));
        }

        return Stack(
          children: [
            // Fondo
            Container(color: const Color(0xFF0A0A0A)),
            // Mazo de preguntas sin responder
            if (unanswered.isNotEmpty)
              TriviaDeck(
                questions: unanswered,
                provider: pv,
                theme: t,
                onQuestionAnswered: () {
                  // La UI se actualiza automáticamente via provider
                },
              ),
            // Botones de acción flotantes
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ActionButton(
                    icon: Icons.add,
                    label: 'Agregar',
                    color: const Color(0xFF9D00FF),
                    onTap: () => setState(() => _showAdd = true),
                  ),
                  ActionButton(
                    icon: Icons.history,
                    label: 'Historial',
                    color: const Color(0xFF9D00FF),
                    onTap: answered.isEmpty ? null : () => setState(() => _showHistory = true),
                  ),
                ],
              ),
            ),
            // Indicador de puntuación arriba
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Scoreboard(theme: t, provider: pv),
            ),
          ],
        );
      },
    );
  }
}
