import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';
import '../models/nosotros_layout.dart';
import 'nosotros_question_tile.dart';

const Color _purple = Color(0xFF7000FF);
const Color _black = Color(0xFF000000);

class NosotrosPreguntasPanel extends StatefulWidget {
  final NosotrosLayout layout;
  final ThemeSet theme;
  final bool active;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final List<Map<String, dynamic>> allQuestions;
  final String myId;
  final String myInitial;
  final String partnerInitial;
  final VoidCallback onClose;
  final void Function(dynamic questionId, String answer) onAnswer;
  final void Function(String text) onSendNewQuestion;
  final void Function(dynamic questionId) onDeleteQuestion;

  const NosotrosPreguntasPanel({
    super.key,
    required this.layout,
    required this.theme,
    required this.active,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.allQuestions,
    required this.myId,
    required this.myInitial,
    required this.partnerInitial,
    required this.onClose,
    required this.onAnswer,
    required this.onSendNewQuestion,
    required this.onDeleteQuestion,
  });

  @override
  State<NosotrosPreguntasPanel> createState() => _NosotrosPreguntasPanelState();
}

class _NosotrosPreguntasPanelState extends State<NosotrosPreguntasPanel> {
  bool _answeringQuestion = false;
  Map<String, dynamic>? _questionToAnswer;
  final _answerController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;
    if (_questionToAnswer == null) {
      widget.onSendNewQuestion(text);
    } else {
      widget.onAnswer(_questionToAnswer!['id'], text);
    }
    setState(() {
      _answeringQuestion = false;
      _questionToAnswer = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.active,
      child: Opacity(
        opacity: widget.opacityAnimation.value,
        child: Transform.scale(
          scale: widget.scaleAnimation.value,
          alignment: Alignment.topCenter,
          child: _answeringQuestion
              ? _buildAnswerPanelContent()
              : _buildPreguntasPanelContent(),
        ),
      ),
    );
  }

  Widget _buildPreguntasPanelContent() {
    final t = widget.theme;
    final lay = widget.layout;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _purple,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              height: lay.preguntasH,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(child: SizedBox()),
                    TapTile(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: t.e, borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.close, color: t.light, size: 16),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.allQuestions.map((q) => NosotrosQuestionTile(
                          questionData: q,
                          theme: t,
                          myId: widget.myId,
                          myInitial: widget.myInitial,
                          partnerInitial: widget.partnerInitial,
                          onSelectQuestion: (question) {
                            setState(() {
                              _answeringQuestion = true;
                              _questionToAnswer = question;
                            });
                          },
                          onDeleteQuestion: widget.onDeleteQuestion,
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 3, color: _black),
            Padding(
              padding: const EdgeInsets.all(8),
              child: TapTile(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  setState(() {
                    _answeringQuestion = true;
                    _questionToAnswer = null;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(color: t.d, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Icon(Icons.add, color: t.dark, size: 28)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerPanelContent() {
    final t = widget.theme;
    final isNewQuestion = _questionToAnswer == null;
    final question = _questionToAnswer?['question'] as String? ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _purple,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  isNewQuestion ? 'Nueva pregunta' : 'Responder pregunta',
                  style: GoogleFonts.bangers(color: t.light, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              TapTile(
                onTap: () => setState(() {
                  _answeringQuestion = false;
                  _questionToAnswer = null;
                  _answerController.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: t.e, borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.close, color: t.light, size: 16),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            if (!isNewQuestion)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: t.dark.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                child: Text(question, style: GoogleFonts.bangers(color: t.light, fontSize: 14)),
              ),
            if (!isNewQuestion) const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              maxLines: 4,
              style: GoogleFonts.bangers(color: t.light, fontSize: 14),
              decoration: InputDecoration(
                hintText: isNewQuestion ? 'Escribe tu pregunta...' : 'Escribe tu respuesta...',
                hintStyle: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.4), fontSize: 14),
                filled: true,
                fillColor: t.dark.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
            const SizedBox(height: 8),
            TapTile(
              onTap: _submit,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: t.d, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    isNewQuestion ? 'Enviar pregunta' : 'Enviar respuesta',
                    style: GoogleFonts.bangers(color: t.dark, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
