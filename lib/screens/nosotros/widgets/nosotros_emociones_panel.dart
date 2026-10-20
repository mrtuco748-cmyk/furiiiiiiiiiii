import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';
import '../models/nosotros_layout.dart';

const Color _purple = Color(0xFF7000FF);

class NosotrosEmocionesPanel extends StatefulWidget {
  final NosotrosLayout layout;
  final ThemeSet theme;
  final bool active;
  final Animation<double> scaleAnimation;
  final Animation<double> opacityAnimation;
  final List<Map<String, dynamic>> myMoods;
  final List<Map<String, dynamic>> partnerMoods;
  final String myId;
  final String partnerName;
  final Widget? emocionesContent;
  final VoidCallback onClose;
  final void Function(String emoji) onAddMood;
  final void Function(Map<String, dynamic> mood) onDeleteMood;

  const NosotrosEmocionesPanel({
    super.key,
    required this.layout,
    required this.theme,
    required this.active,
    required this.scaleAnimation,
    required this.opacityAnimation,
    required this.myMoods,
    required this.partnerMoods,
    required this.myId,
    required this.partnerName,
    this.emocionesContent,
    required this.onClose,
    required this.onAddMood,
    required this.onDeleteMood,
  });

  @override
  State<NosotrosEmocionesPanel> createState() => _NosotrosEmocionesPanelState();
}

class _NosotrosEmocionesPanelState extends State<NosotrosEmocionesPanel> {
  final _emojiCtrl = TextEditingController();
  final _mostUsedEmojis = ['😊', '😍', '😂', '🥰', '😢', '😡', '🥳', '❤️', '🔥', '😎', '🤗', '😴'];

  @override
  void dispose() {
    _emojiCtrl.dispose();
    super.dispose();
  }

  void _submitMood(String emoji) {
    if (emoji.trim().isEmpty) return;
    widget.onAddMood(emoji.trim());
    _emojiCtrl.clear();
  }

  Widget _buildDefaultEmociones(ThemeSet t) {
    if (widget.partnerMoods.isEmpty) {
      return FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(width: 120, height: 120, child: Icon(Icons.mood, color: t.light, size: 120)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.partnerMoods.map((m) => Text(m['mood'] as String? ?? '', style: const TextStyle(fontSize: 40))).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final lay = widget.layout;

    return IgnorePointer(
      ignoring: !widget.active,
      child: Opacity(
        opacity: widget.opacityAnimation.value,
        child: Transform.scale(
          scale: widget.scaleAnimation.value,
          alignment: Alignment.centerLeft,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: lay.iconW,
                    height: lay.r3H,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.rotate(
                          angle: -0.05,
                          alignment: Alignment.center,
                          child: widget.emocionesContent ?? _buildDefaultEmociones(t),
                        ),
                        const SizedBox(height: 8),
                        TapTile(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: t.e, borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.close, color: t.light, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: lay.gapW),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _emojiCtrl,
                                    style: const TextStyle(fontSize: 22),
                                    decoration: InputDecoration(
                                      hintText: '😊',
                                      hintStyle: TextStyle(color: t.light.withValues(alpha: 0.3), fontSize: 22),
                                      filled: true,
                                      fillColor: t.dark.withValues(alpha: 0.3),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                    ),
                                    onSubmitted: _submitMood,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TapTile(
                                  onTap: () => _submitMood(_emojiCtrl.text),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: t.c, borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.send, color: t.light, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _mostUsedEmojis.map((e) => TapTile(
                              onTap: () => _submitMood(e),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: t.dark.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                                child: Text(e, style: const TextStyle(fontSize: 20)),
                              ),
                            )).toList(),
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            flex: 3,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...widget.myMoods.map((m) => _moodRow(m, 'Yo', t)),
                                  ...widget.partnerMoods.map((m) => _moodRow(m, widget.partnerName, t)),
                                  if (widget.myMoods.isEmpty && widget.partnerMoods.isEmpty)
                                    Text('Sin emociones hoy', style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.5), fontSize: 12)),
                                ],
                              ),
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
        ),
      ),
    );
  }

  Widget _moodRow(Map<String, dynamic> m, String label, ThemeSet t) {
    final mood = m['mood'] as String? ?? '';
    final time = m['created_at'] != null
        ? DateTime.parse(m['created_at'] as String).toLocal().toString().substring(11, 16)
        : '';
    final isMine = m['user_id'] == widget.myId;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Text(mood, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 6),
        Text(time, style: GoogleFonts.bangers(color: t.light.withValues(alpha: 0.5), fontSize: 11)),
        if (isMine) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              widget.onDeleteMood(m);
            },
            child: Icon(Icons.close, color: t.light.withValues(alpha: 0.4), size: 14),
          ),
        ],
      ]),
    );
  }
}
