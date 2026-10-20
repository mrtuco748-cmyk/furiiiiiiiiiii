import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/tap_tile.dart';

/// Reproductor de notas de voz embebido en la burbuja de chat.
class ChatAudioPlayerTile extends StatefulWidget {
  final String path;
  final Color textColor;
  const ChatAudioPlayerTile({super.key, required this.path, required this.textColor});

  @override
  State<ChatAudioPlayerTile> createState() => _ChatAudioPlayerTileState();
}

class _ChatAudioPlayerTileState extends State<ChatAudioPlayerTile> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
      return;
    }
    await _player.play(DeviceFileSource(widget.path));
    setState(() => _playing = true);
  }

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: _toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _playing ? Icons.stop : Icons.play_arrow,
            color: widget.textColor,
            size: 26,
          ),
          const SizedBox(width: 6),
          Icon(Icons.graphic_eq, color: widget.textColor, size: 20),
          const SizedBox(width: 6),
          Text(
            'Audio',
            style: GoogleFonts.bangers(
              fontSize: 13,
              color: widget.textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
