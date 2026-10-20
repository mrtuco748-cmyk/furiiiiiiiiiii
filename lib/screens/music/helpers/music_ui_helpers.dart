import 'package:flutter/material.dart';

Widget fallbackMusicCover({double width = 50, double height = 50}) {
  return Container(
    width: width,
    height: height,
    color: const Color(0xFF222222),
    child: const Icon(Icons.music_note, color: Colors.white38),
  );
}

String formatMusicDuration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
