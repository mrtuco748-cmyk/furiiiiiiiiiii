import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../chat_style.dart';

/// Vista de teclado y categorías de emojis para el chat.
class ChatEmojiPickerView extends StatelessWidget {
  final TextEditingController textController;

  const ChatEmojiPickerView({super.key, required this.textController});

  static const Map<String, List<String>> _emojiCategories = {
    'Favoritos': [
      '❤️', '😂', '🥰', '😍', '🥺', '😭', '🔥', '👍',
      '💖', '✨', '💋', '🌹', '😘', '🤤', '🎉'
    ],
    'Caras': [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃', '😉', '😊',
      '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😋', '😛', '😜', '🤪', '😝',
      '🤑', '🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏', '😒',
      '🙄', '😬', '🤥', '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢',
      '🤮', '🥵', '🥶', '🥴', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐', '😕',
      '😟', '🙁', '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨', '😰', '😥',
      '😢', '😭', '😱', '😖', '😣', '😞', '😓', '😩', '😫', '🥱', '😤', '😡',
    ],
    'Amor': [
      '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕',
      '💞', '💓', '💗', '💖', '💘', '💝', '💟', '💌', '💋', '👩‍❤️‍👨', '💏', '💑',
      '💐', '🌹', '🥀', '🌺', '🌸', '🌷', '💍', '💎',
    ],
    'Gestos': [
      '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘', '👌', '🤏',
      '👈', '👉', '👆', '👇', '☝️', '✋', '🤚', '🖐️', '🖖', '👋', '🤙', '💪',
      '🙏', '🤝', '👏', '🙌', '👐', '🤲',
    ],
    'Animales': [
      '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮',
      '🐷', '🐸', '🐵', '🙈', '🙉', '🙊', '🐒', '🐔', '🐧', '🐦', '🐤', '🦆',
      '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋', '🐌', '🐞',
      '🐢', '🐍', '🦎', '🐙', '🦑', '🦐', '🦀', '🐬', '🐳', '🦈',
    ],
  };

  void _onEmojiTap(String emoji) {
    HapticFeedback.selectionClick();
    final text = textController.text;
    final selection = textController.selection;
    if (selection.start >= 0 && selection.end >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, emoji);
      textController.value = TextEditingValue(
        text: newText,
        selection:
            TextSelection.collapsed(offset: selection.start + emoji.length),
      );
    } else {
      textController.text += emoji;
    }
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    final text = textController.text;
    if (text.isEmpty) return;
    final characters = text.characters;
    textController.text = characters.skipLast(1).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: _emojiCategories.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6, top: 8, bottom: 4),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white38,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: entry.value.map((emoji) {
                      return InkWell(
                        onTap: () => _onEmojiTap(emoji),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          child: Text(emoji,
                              style: const TextStyle(fontSize: 26)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: ChatStyle.inputBg,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.backspace_outlined,
                    color: Colors.white70, size: 22),
                onPressed: _onBackspace,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
