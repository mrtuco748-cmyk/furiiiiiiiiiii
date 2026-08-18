import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../models/board_element_v2.dart';
import '../../../models/board_element_data.dart';
import '../../../providers/board_provider_v2.dart';

/// Editor de audio que permite grabar una nota de voz.
class BoardAudioEditor extends StatefulWidget {
  final BoardProviderV2 provider;
  final VoidCallback onClose;
  final int? targetId;

  const BoardAudioEditor({
    super.key,
    required this.provider,
    required this.onClose,
    this.targetId,
  });

  @override
  State<BoardAudioEditor> createState() => _BoardAudioEditorState();
}

class _BoardAudioEditorState extends State<BoardAudioEditor> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Duration _duration = Duration.zero;
  List<double> _waveform = [];

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        final duration = _duration.inMilliseconds / 1000.0;
        final data = AudioData(
          localPath: path,
          duration: duration,
          waveform: _waveform.isEmpty ? _generatePlaceholderWaveform() : _waveform,
        );
        // Find latest audio element and update it
        final elements = widget.provider.elements
            .where((e) => e.type == BoardElementType.audio)
            .toList();
        BoardElementV2? target;
        if (widget.targetId != null) {
          for (final e in elements) {
            if (e.id == widget.targetId) target = e;
          }
        }
        target ??= elements.isNotEmpty ? elements.last : null;
        if (target != null) {
          widget.provider.update(target.copyWith(
            data: data.toMap(),
          ));
        }
      }
    } else {
      // Start recording
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/board_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _duration = Duration.zero;
          _waveform = [];
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      if (!_isRecording) return false;
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() {
          _duration += const Duration(milliseconds: 100);
          _waveform.add(0.3 + (DateTime.now().millisecond % 100) / 150);
        });
      }
      return true;
    });
  }

  List<double> _generatePlaceholderWaveform() {
    return List.generate(30, (i) => 0.3 + (i % 5) * 0.15);
  }

  void _finish() {
    if (_isRecording) {
      _audioRecorder.stop();
    }
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Waveform
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: CustomPaint(
                  painter: _WaveformPreviewPainter(
                    waveform: _waveform,
                    isRecording: _isRecording,
                  ),
                  size: const Size(double.infinity, 80),
                ),
              ),
              const SizedBox(height: 16),
              // Duration
              Text(
                _formatDuration(_duration),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              // Record button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? const Color(0xFFFF5757)
                            : const Color(0xFF4FC3F7),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: const Color(0xFF0A0A0A),
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isRecording ? 'Toca para detener' : 'Toca para grabar',
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              // Finish button
              GestureDetector(
                onTap: _finish,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.toString().padLeft(2, '0');
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

class _WaveformPreviewPainter extends CustomPainter {
  final List<double> waveform;
  final bool isRecording;

  _WaveformPreviewPainter({
    required this.waveform,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) {
      _drawPlaceholder(canvas, size);
      return;
    }

    final barWidth = size.width / waveform.length;
    final maxBarHeight = size.height * 0.8;

    for (int i = 0; i < waveform.length; i++) {
      final x = i * barWidth;
      final amplitude = waveform[i].clamp(0.0, 1.0);
      final barHeight = amplitude * maxBarHeight;

      final paint = Paint()
        ..color = isRecording
            ? const Color(0xFFFF5757)
            : const Color(0xFF4FC3F7)
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

  void _drawPlaceholder(Canvas canvas, Size size) {
    const count = 30;
    final barWidth = size.width / count;
    final maxBarHeight = size.height * 0.6;

    for (int i = 0; i < count; i++) {
      final x = i * barWidth;
      final amplitude = 0.3 + (i % 5) * 0.15;
      final barHeight = amplitude * maxBarHeight;

      final paint = Paint()
        ..color = const Color(0xFF333333)
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
  bool shouldRepaint(covariant _WaveformPreviewPainter oldDelegate) {
    return oldDelegate.waveform != waveform ||
        oldDelegate.isRecording != isRecording;
  }
}
