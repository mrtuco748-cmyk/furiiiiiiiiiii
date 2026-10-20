import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/concrete_painter.dart';
import '../../../widgets/tap_tile.dart';

const _cInbox = Color(0xFFFF1493);
const _dark = Color(0xFF1A1A1A);
const _mid = Color(0xFF2A2A2A);

class LetterComposeView extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(String title, String body, DateTime? scheduledOpen) onSend;

  const LetterComposeView({
    super.key,
    required this.onClose,
    required this.onSend,
  });

  @override
  State<LetterComposeView> createState() => _LetterComposeViewState();
}

class _LetterComposeViewState extends State<LetterComposeView> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  DateTime? _scheduledOpen;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _handleSend() {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;
    widget.onSend(title, body, _scheduledOpen);
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledOpen ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      helpText: '¿Cuándo se podrá abrir?',
    );
    if (picked != null && mounted) {
      setState(() => _scheduledOpen =
          DateTime(picked.year, picked.month, picked.day));
    }
  }

  Widget _fieldShell(Color color, Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: _mid,
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    const color = _cInbox;

    return Scaffold(
      backgroundColor: _dark,
      body: SafeArea(
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: ConcretePainter())),
              Positioned(
                left: 0,
                top: 0,
                width: w,
                height: h * 0.07,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        TapTile(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            widget.onClose();
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 28),
                          ),
                        ),
                        const Spacer(),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.edit_note,
                              color: Colors.white, size: 26),
                        ),
                        TapTile(
                          onTap: _handleSend,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(Icons.send,
                                color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: w * 0.05,
                top: h * 0.09,
                width: w * 0.90,
                height: h * 0.10,
                child: _fieldShell(
                  color,
                  Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.title, color: _cInbox, size: 24),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _titleCtrl,
                          style: GoogleFonts.bangers(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: w * 0.05,
                top: h * 0.21,
                width: w * 0.90,
                height: h * 0.63,
                child: _fieldShell(
                  color,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14, top: 14),
                        child: Icon(Icons.edit_note,
                            color: _cInbox, size: 24),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _bodyCtrl,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: GoogleFonts.bangers(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: w * 0.05,
                top: h * 0.86,
                width: w * 0.90,
                height: h * 0.07,
                child: _fieldShell(
                  color,
                  Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.schedule, color: color, size: 24),
                      ),
                      Expanded(
                        child: _scheduledOpen == null
                            ? Text(
                                'Programar apertura (opcional)',
                                style: GoogleFonts.bangers(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              )
                            : Text(
                                'Se abre el ${_scheduledOpen!.day}/${_scheduledOpen!.month}/${_scheduledOpen!.year}',
                                style: GoogleFonts.bangers(
                                  color: Colors.amberAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                      TapTile(
                        onTap: _pickSchedule,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.edit_calendar,
                              color: color, size: 22),
                        ),
                      ),
                      if (_scheduledOpen != null)
                        TapTile(
                          onTap: () =>
                              setState(() => _scheduledOpen = null),
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Icon(Icons.close,
                                color: Colors.white, size: 22),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
