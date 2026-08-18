import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';

/// Renderer para audio con waveform visual.
/// Reproduce el audio local grabado (localPath) o el storagePath.
class BoardAudioRenderer extends StatefulWidget {
  final BoardElementV2 element;

  const BoardAudioRenderer({super.key, required this.element});

  @override
  State<BoardAudioRenderer> createState() => _BoardAudioRendererState();
}

class _BoardAudioRendererState extends State<BoardAudioRenderer> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _hasError = false;
  double _progress = 0;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  @override
  void initState() {
    super.initState();
    _positionSub = _player.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _progress = pos.inMilliseconds / 1000.0);
      }
    });
    _durationSub = _player.onDurationChanged.listen((dur) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    final data = AudioData.fromMap(widget.element.data);
    if (data.localPath == null && data.storagePath == null) {
      setState(() => _hasError = true);
      return;
    }

    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    try {
      if (data.localPath != null) {
        await _player.play(DeviceFileSource(data.localPath!));
      } else if (data.storagePath != null) {
        await _player.play(UrlSource(data.storagePath!));
      }
      setState(() => _isPlaying = true);
      setState(() => _hasError = false);
    } catch (e) {
      debugPrint('BoardAudioRenderer.play error: $e');
      setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = AudioData.fromMap(widget.element.data);
    final w = widget.element.width ?? 280;
    final h = widget.element.height ?? 80;

    return Container(
      width: w,
      height: h,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: const Color(0xFF0A0A0A),
                size: 24,
              ),
            ),
          ),
          if (_hasError)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.error, color: Colors.red, size: 20),
            ),
          const SizedBox(width: 12),
          // Waveform
          Expanded(
            child: CustomPaint(
              painter: _WaveformPainter(
                waveform: data.waveform,
                progress: _isPlaying ? _progress / (data.duration == 0 ? 1 : data.duration) : 0,
                color: const Color(0xFF4FC3F7),
              ),
              size: Size(w - 62, h - 20),
            ),
          ),
          // Duration
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _formatDuration(data.duration),
              style: const TextStyle(
                color: Colors.white54,
                fontFamily: 'monospace',
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double seconds) {
    final mins = seconds ~/ 60;
    final secs = (seconds % 60).toInt();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final double progress;
  final Color color;

  _WaveformPainter({
    required this.waveform,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) {
      _drawPlaceholderBars(canvas, size);
      return;
    }

    final barWidth = size.width / waveform.length;
    final maxBarHeight = size.height * 0.8;

    for (int i = 0; i < waveform.length; i++) {
      final x = i * barWidth;
      final amplitude = waveform[i].clamp(0.0, 1.0);
      final barHeight = amplitude * maxBarHeight;
      final isPlayed = i / waveform.length < progress;

      final paint = Paint()
        ..color = isPlayed ? color : color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + barWidth / 2, size.height / 2),
            width: barWidth * 0.6,
            height: barHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  void _drawPlaceholderBars(Canvas canvas, Size size) {
    const count = 30;
    final barWidth = size.width / count;
    final maxBarHeight = size.height * 0.6;

    for (int i = 0; i < count; i++) {
      final x = i * barWidth;
      final amplitude = 0.3 + (i % 5) * 0.15;
      final barHeight = amplitude * maxBarHeight;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x + barWidth / 2, size.height / 2),
            width: barWidth * 0.6,
            height: barHeight,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveform != waveform;
  }
}
