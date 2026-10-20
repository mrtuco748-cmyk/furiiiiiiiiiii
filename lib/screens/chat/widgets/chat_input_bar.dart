import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../chat_style.dart';

/// Barra de entrada inferior de chat con texto, multimedia, emojis y grabación de voz
class ChatInputBar extends StatelessWidget {
  final TextEditingController msgCtrl;
  final FocusNode focusNode;
  final bool recording;
  final DateTime? recordStarted;
  final bool hasText;
  final bool sending;
  final ThemeSet theme;
  final VoidCallback onEmojiTap;
  final VoidCallback onAttachTap;
  final VoidCallback onCameraTap;
  final VoidCallback onSendText;
  final VoidCallback onToggleRecord;
  final ValueChanged<String> onChanged;

  const ChatInputBar({
    super.key,
    required this.msgCtrl,
    required this.focusNode,
    required this.recording,
    required this.recordStarted,
    required this.hasText,
    required this.sending,
    required this.theme,
    required this.onEmojiTap,
    required this.onAttachTap,
    required this.onCameraTap,
    required this.onSendText,
    required this.onToggleRecord,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final recLabel = recording && recordStarted != null
        ? '${DateTime.now().difference(recordStarted!).inSeconds}s'
        : '';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ChatStyle.inputBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.white70, size: 24),
                      onPressed: onEmojiTap,
                    ),
                    Expanded(
                      child: recording
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.fiber_manual_record, color: Color(0xFFFF1744), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Grabando $recLabel...',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : TextField(
                              controller: msgCtrl,
                              focusNode: focusNode,
                              minLines: 1,
                              maxLines: 5,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Mensaje...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                              ),
                              onSubmitted: (_) => onSendText(),
                              onChanged: onChanged,
                            ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.white70, size: 22),
                      onPressed: sending ? null : onAttachTap,
                    ),
                    if (!hasText && !recording)
                      IconButton(
                        icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 22),
                        onPressed: onCameraTap,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                if (recording) {
                  onToggleRecord();
                } else if (hasText) {
                  onSendText();
                } else {
                  onToggleRecord();
                }
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: recording ? const Color(0xFFFF1744) : t.a,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: sending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: t.dark,
                          ),
                        )
                      : Icon(
                          recording
                              ? Icons.stop
                              : (hasText ? Icons.send : Icons.mic),
                          color: recording ? Colors.white : t.dark,
                          size: 22,
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
