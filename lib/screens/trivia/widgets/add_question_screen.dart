import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../providers/trivia_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_feedback.dart';
import '../../../widgets/tap_tile.dart';

/// Pantalla para agregar pregunta
class AddQuestionScreen extends StatefulWidget {
  final ThemeSet theme;
  final TriviaProvider provider;
  final VoidCallback onClose;
  const AddQuestionScreen({
    super.key,
    required this.theme,
    required this.provider,
    required this.onClose,
  });

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _qCtrl = TextEditingController();
  final List<TextEditingController> _optCtrls = List.generate(4, (_) => TextEditingController());
  bool _saving = false;

  @override
  void dispose() {
    _qCtrl.dispose();
    for (final c in _optCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _opts => _optCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
  bool get _canSave => _qCtrl.text.trim().isNotEmpty && _opts.length >= 2 && !_saving;

  InputDecoration _dec(ThemeSet t, String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.bangers(color: t.c, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF111111),
        border: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF333333), width: 2), borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF333333), width: 2), borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: t.c, width: 2), borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final ok = await widget.provider.addQuestion(question: _qCtrl.text.trim(), options: _opts);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      AppFeedback.saved(context, 'Pregunta agregada');
      widget.onClose();
    } else {
      AppFeedback.error(context, 'No se pudo agregar');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
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
        title: Text('Nueva pregunta', style: GoogleFonts.bangers(color: Colors.white, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _qCtrl,
            maxLines: 3,
            maxLength: 200,
            autocorrect: false,
            enableSuggestions: false,
            decoration: _dec(t, 'Pregunta'),
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text('Opciones (mínimo 2)', style: GoogleFonts.bangers(color: t.c, fontSize: 14)),
          const SizedBox(height: 10),
          for (var i = 0; i < 4; i++) ...[
            TextField(
              controller: _optCtrls[i],
              maxLength: 60,
              autocorrect: false,
              enableSuggestions: false,
              decoration: _dec(t, 'Opción ${i + 1}'),
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 13),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 16),
          TapTile(
            onTap: _canSave ? _save : () {},
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _canSave ? t.c : const Color(0xFF111111),
                border: Border.all(color: _canSave ? t.c : const Color(0xFF111111), width: 3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.check, color: _canSave ? Colors.white : const Color(0xFF888888), size: 24),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
