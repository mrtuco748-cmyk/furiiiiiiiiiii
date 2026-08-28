import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/trivia.dart';
import '../../providers/trivia_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/loca_screen.dart';
import '../../widgets/tap_tile.dart';

/// Trivia de pareja estilo "Nosotros": un tile grande que swapea al marcador
/// ("X â€“ Y") y abre el juego completo (pregunta + opciones + predicciÃ³n +
/// puntaje) en un panel swink.
class TriviaScreen extends StatefulWidget {
  final AppMode mode;
  const TriviaScreen({super.key, required this.mode});

  @override
  State<TriviaScreen> createState() => _TriviaScreenState();
}

class _TriviaScreenState extends State<TriviaScreen> {
  String? _myAnswer;
  String? _myGuess;
  bool _saving = false;
  bool _showDeck = false;

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
        if (_showDeck) {
          return TriviaDeckOverlay(
            provider: pv,
            theme: t,
            onClose: () => setState(() => _showDeck = false),
          );
        }
        final q = pv.todayQuestion;
        final answered = pv.myAnswerToday != null;
        final entries = <LocaEntry>[
          LocaEntry(
            icon: answered ? Icons.check_circle : Icons.interpreter_mode,
            color: const Color(0xFF9D00FF),
            iconColor: answered ? const Color(0xFF39FF14) : Colors.white,
            label: 'Trivia',
            onTap: () => setState(() => _showDeck = true),
            swapBuilder: q == null ? null : (_) => _scoreSwap(pv, t),
            autoPlaySwap: q != null && pv.bothAnsweredToday,
          ),
          if (pv.hasError)
            LocaEntry(
              icon: Icons.cloud_off,
              color: const Color(0xFFFF0000),
              onTap: () => context.read<TriviaProvider>().load(),
            ),
          if (!pv.loading && !pv.hasError && q == null)
            LocaEntry(icon: Icons.question_answer, color: const Color(0xFF9D00FF), iconColor: Colors.white54),
        ];
        return LocaScreen(
          seed: 83,
          theme: t,
          entries: entries,
          panels: [(_, close) => _gamePanel(close, t, pv, q)],
        );
      },
    );
  }

  Widget _scoreSwap(TriviaProvider pv, ThemeSet t) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(pv.scoreboard,
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _gamePanel(VoidCallback close, ThemeSet t, TriviaProvider pv, TriviaQuestion? q) {
    if (q == null) {
      return LocaScreen.panel(
        color: const Color(0xFF2A2A2A),
        borderColor: const Color(0xFF9D00FF),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(children: [
              Icon(Icons.question_answer, color: const Color(0xFF9D00FF), size: 22),
              const Spacer(),
              LocaScreen.closeIcon(close, const Color(0xFF9D00FF), Icons.close),
            ]),
          ),
          const Expanded(child: Center(child: Icon(Icons.schedule, color: Colors.white54, size: 56))),
        ]),
      );
    }
    return LocaScreen.panel(
      color: const Color(0xFF2A2A2A),
      borderColor: const Color(0xFF9D00FF),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
          child: Row(children: [
            Icon(Icons.interpreter_mode, color: const Color(0xFF9D00FF), size: 22),
            const Spacer(),
            LocaScreen.closeIcon(close, const Color(0xFF9D00FF), Icons.close),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _gameBody(t, pv, q),
          ),
        ),
      ]),
    );
  }

  Widget _gameBody(ThemeSet t, TriviaProvider pv, TriviaQuestion q) {
    final my = pv.myAnswerToday;
    final shownAnswer = _myAnswer ?? my?.answer;
    final shownGuess = _myGuess ?? my?.guess;
    final canSave = shownAnswer != null && shownGuess != null;
    final both = pv.bothAnsweredToday;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(q.question,
          style: GoogleFonts.bangers(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Tu respuesta', style: GoogleFonts.bangers(color: t.c, fontSize: 14)),
      _optionChips(t, q.options, shownAnswer, (o) => setState(() => _myAnswer = o)),
      const SizedBox(height: 10),
      Text('PredicciÃ³n: Â¿quÃ© responderÃ¡ tu pareja?', style: GoogleFonts.bangers(color: t.c, fontSize: 14)),
      const SizedBox(height: 8),
      _optionChips(t, q.options, shownGuess, (o) => setState(() => _myGuess = o)),
      const SizedBox(height: 14),
      if (!both)
        TapTile(
          onTap: () { if (canSave && !_saving) _submit(); },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: canSave ? t.c : const Color(0xFF111111),
              border: Border.all(color: canSave ? t.c : const Color(0xFF111111), width: 3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(_saving ? 'Guardandoâ€¦' : my?.id != null ? 'Actualizar respuesta' : 'Confirmar',
                  style: GoogleFonts.bangers(color: canSave ? Colors.white : const Color(0xFF888888), fontSize: 16)),
            ),
          ),
        ),
      if (both) ...[
        _scoreboard(t, pv),
        const SizedBox(height: 8),
        Text('Puntaje acumulado de predicciones acertadas',
            textAlign: TextAlign.center, style: GoogleFonts.bangers(color: Colors.white54, fontSize: 12)),
      ],
    ]);
  }

  Widget _optionChips(ThemeSet t, List<String> options, String? selected, ValueChanged<String> onTap) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final o in options)
        TapTile(
          onTap: () { HapticFeedback.selectionClick(); onTap(o); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected == o ? t.c : const Color(0xFF111111),
              border: Border.all(color: selected == o ? t.c : const Color(0xFF111111), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(o,
                style: GoogleFonts.bangers(
                    color: selected == o ? Colors.white : const Color(0xFFAAAAAA),
                    fontSize: 13,
                    fontWeight: selected == o ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
    ]);
  }

  Widget _scoreboard(ThemeSet t, TriviaProvider pv) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pv.partnerScore > pv.myScore ? const Color(0xFFFF1493) : t.c,
        border: Border.all(color: pv.partnerScore > pv.myScore ? const Color(0xFFFF1493) : t.c, width: 3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        Column(children: [
          Text('TU', style: GoogleFonts.bangers(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('${pv.myScore}', style: GoogleFonts.bangers(color: Colors.white, fontSize: 30)),
        ]),
        const Text('ðŸ…', style: TextStyle(fontSize: 26)),
        Column(children: [
          Text('PAREJA', style: GoogleFonts.bangers(color: Colors.white, fontWeight: FontWeight.bold)),
          Text('${pv.partnerScore}', style: GoogleFonts.bangers(color: Colors.white, fontSize: 30)),
        ]),
      ]),
    );
  }

  Future<void> _submit() async {
    final pv = context.read<TriviaProvider>();
    final q = pv.todayQuestion;
    final shownAnswer = _myAnswer ?? pv.myAnswerToday?.answer;
    final shownGuess = _myGuess ?? pv.myAnswerToday?.guess;
    if (q?.id == null || shownAnswer == null || shownGuess == null) return;
    setState(() => _saving = true);
    await pv.submit(questionId: q!.id!, answer: shownAnswer, guess: shownGuess);
    if (!mounted) return;
    setState(() { _saving = false; _myAnswer = null; _myGuess = null; });
  }
}

/// Trivia con aspecto de MAZO APILADO (tipo tarjetas de poemas): las preguntas
/// del banco se presentan como cards de gradiente apiladas, y se deslizan
/// a la izquierda/derecha para navegar. En la card frontal se responde
/// (Tu respuesta + PredicciÃ³n) y se confirma.
class TriviaDeckOverlay extends StatefulWidget {
  final TriviaProvider provider;
  final ThemeSet theme;
  final VoidCallback onClose;
  const TriviaDeckOverlay({
    super.key,
    required this.provider,
    required this.theme,
    required this.onClose,
  });

  @override
  State<TriviaDeckOverlay> createState() => _TriviaDeckOverlayState();
}

class _TriviaDeckOverlayState extends State<TriviaDeckOverlay> {
  int _index = 0;
  String? _answer;
  String? _guess;
  bool _saving = false;
  static const double _cardW = 340;
  static const double _cardH = 520;

  List<TriviaQuestion> get _questions => widget.provider.questions;

  @override
  void initState() {
    super.initState();
    final today = widget.provider.todayQuestion;
    if (today?.id != null && _questions.isNotEmpty) {
      final i = _questions.indexWhere((q) => q.id == today!.id);
      if (i >= 0) _index = i;
    }
  }

  void _submit(TriviaQuestion q) {
    final ans = _answer ?? widget.provider.myAnswerToday?.answer;
    final gss = _guess ?? widget.provider.myAnswerToday?.guess;
    if (ans == null || gss == null || _saving) return;
    setState(() => _saving = true);
    widget.provider
        .submit(questionId: q.id!, answer: ans, guess: gss)
        .whenComplete(() {
      if (mounted) setState(() => _saving = false);
    });
  }

  void _swipe(double dx) {
    if (dx < -40 && _index < _questions.length - 1) {
      setState(() { _index++; _answer = null; _guess = null; });
    } else if (dx > 40 && _index > 0) {
      setState(() { _index--; _answer = null; _guess = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final total = _questions.length;
    return Material(
      color: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (d) => _swipe(d.primaryVelocity ?? 0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: Container(color: const Color(0xFF0A0A0A))),
              if (total == 0)
                const Center(child: Text('Sin preguntas',
                    style: TextStyle(color: Colors.white54, fontFamily: 'monospace')))
              else ...[
                // Cards apiladas detrÃ¡s (efecto mazo)
                for (var d = 2; d >= 1; d--)
                  if (_index + d < total)
                    _cardShell(d, offsetY: -9.0 * d, scale: 1.0 - 0.05 * d),
                if (_index < total)
                  _cardShell(0, child: _frontCard(_questions[_index], t)),
              ],
              Positioned(
                top: 12,
                left: 12,
                child: GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D00FF),
                      border: Border.all(color: const Color(0xFF9D00FF), width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
              ),
              if (_questions.isNotEmpty)
                Positioned(
                  bottom: 16,
                  child: Text('${_index + 1} / $total Â· deslizÃ¡',
                      style: GoogleFonts.bangers(fontSize: 14, color: Colors.white54)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardShell(int depth, {double? offsetY, double? scale, Widget? child}) {
    return Transform.translate(
      offset: Offset(0, offsetY ?? 0),
      child: Transform.scale(
        scale: scale ?? 1,
        child: Opacity(
          opacity: depth == 0 ? 1 : 0.7 - depth * 0.1,
          child: Container(
            width: _cardW,
            height: _cardH,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF9D00FF), Color(0xFF7000FF), Color(0xFFB23BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _frontCard(TriviaQuestion q, ThemeSet t) {
    final my = widget.provider.myAnswerToday;
    final shownAnswer = _answer ?? my?.answer;
    final shownGuess = _guess ?? my?.guess;
    final canSave = shownAnswer != null && shownGuess != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Â¿CuÃ¡nto conocÃ©s a tu pareja?',
            textAlign: TextAlign.center,
            style: GoogleFonts.bangers(color: Colors.white54, fontSize: 14)),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Text(q.question,
                textAlign: TextAlign.center,
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 22, height: 1.35, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        Text('Tu respuesta', style: GoogleFonts.bangers(color: t.c, fontSize: 13)),
        const SizedBox(height: 6),
        _chips(q.options, shownAnswer, (o) => setState(() => _answer = o)),
        const SizedBox(height: 12),
        Text('PredicciÃ³n', style: GoogleFonts.bangers(color: t.c, fontSize: 13)),
        const SizedBox(height: 6),
        _chips(q.options, shownGuess, (o) => setState(() => _guess = o)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _submit(q),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: canSave ? const Color(0xFF39FF14) : const Color(0xFF2A2A2A),
              border: Border.all(color: canSave ? const Color(0xFF39FF14) : const Color(0xFF2A2A2A), width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(_saving ? 'Guardandoâ€¦' : (my?.id != null ? 'Actualizar respuesta' : 'Confirmar'),
                  style: GoogleFonts.bangers(color: canSave ? const Color(0xFF0A0A0A) : Colors.white54, fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chips(List<String> options, String? selected, ValueChanged<String> onTap) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final o in options)
        GestureDetector(
          onTap: () { HapticFeedback.selectionClick(); onTap(o); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected == o ? const Color(0xFF9D00FF) : const Color(0xFF2A2A2A),
              border: Border.all(color: selected == o ? const Color(0xFF9D00FF) : const Color(0xFF2A2A2A), width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(o, style: GoogleFonts.bangers(color: selected == o ? Colors.white : Colors.white70, fontSize: 12)),
          ),
        ),
    ]);
  }
}