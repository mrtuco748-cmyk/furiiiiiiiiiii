import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/deck_card.dart';
import '../../providers/deck_provider.dart';
import 'deck_style.dart';

Future<void> showCreateDeckCardModal(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const CreateDeckCardModal(),
  );
}

class CreateDeckCardModal extends StatefulWidget {
  const CreateDeckCardModal({super.key});

  @override
  State<CreateDeckCardModal> createState() => _CreateDeckCardModalState();
}

class _CreateDeckCardModalState extends State<CreateDeckCardModal> {
  String _category = DeckCategory.ideas;
  bool _saving = false;
  final TextEditingController _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    final pv = context.read<DeckProvider>();
    final ok = await pv.add(_category, text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Text('NUEVA TARJETA',
                style: GoogleFonts.bangers(
                    color: const Color(0xFFFFDE59),
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  border: Border.all(color: const Color(0xFFFF0000), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.close,
                    color: Color(0xFF1A1A1A), size: 18),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DeckCategory.all.map((cat) {
              final style = DeckCategoryStyle.of(cat);
              final selected = cat == _category;
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: style.color,
                    border: Border.all(color: style.color, width: 2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(style.emoji,
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(style.label,
                        style: TextStyle(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold)),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.check,
                          color: Color(0xFF1A1A1A), size: 16),
                    ],
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              border: Border.all(color: const Color(0xFF2D2D2D), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 5,
              maxLength: 1000,
              style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 15,
                  fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: 'Escribí la idea, chiste, poema...',
                hintStyle: TextStyle(
                    color: Color(0xFF8A8A8A), fontFamily: 'monospace'),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(14),
                counterStyle: TextStyle(color: Color(0xFF8A8A8A)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            GestureDetector(
              onTap: _ctrl.text.trim().isEmpty || _saving ? null : _save,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _ctrl.text.trim().isEmpty || _saving
                      ? const Color(0xFF3A3A3A)
                      : const Color(0xFF39FF14),
                  border: Border.all(
                      color: _ctrl.text.trim().isEmpty || _saving
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFF39FF14),
                      width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: _saving
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF1A1A1A)),
                      )
                    : const Icon(Icons.check,
                        color: Color(0xFF1A1A1A), size: 28),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
