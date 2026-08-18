import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

class NoteAudioRecorder extends StatefulWidget {
  final String? existingPath;
  final ValueChanged<String?> onAudioSaved;

  const NoteAudioRecorder({
    super.key,
    this.existingPath,
    required this.onAudioSaved,
  });

  @override
  State<NoteAudioRecorder> createState() => _NoteAudioRecorderState();
}

class _NoteAudioRecorderState extends State<NoteAudioRecorder> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  int _elapsed = 0;
  Timer? _timer;
  bool _hasAudio = false;
  String? _lastRecordedPath;

  @override
  void initState() {
    super.initState();
    _hasAudio = widget.existingPath != null;
    _lastRecordedPath = widget.existingPath;
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_isRecording) {
      _recorder.stop();
    }
    _cleanupTempFile();
    _recorder.dispose();
    super.dispose();
  }

  void _cleanupTempFile() {
    if (_lastRecordedPath != null && widget.existingPath == null) {
      try {
        final file = File(_lastRecordedPath!);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      _timer?.cancel();
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _hasAudio = true;
          _lastRecordedPath = path;
        }
      });
      widget.onAudioSaved(path);
    } else {
      HapticFeedback.mediumImpact();
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Permiso de micrófono denegado',
              style: TextStyle(fontFamily: 'monospace')),
            backgroundColor: Color(0xFF1A1A1A)));
        }
        return;
      }
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: '${Directory.systemTemp.path}/note_audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
      );
      setState(() => _isRecording = true);
      _elapsed = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed++);
      });
    }
  }

  String _formatDuration(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleRecording,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _isRecording ? const Color(0xFFFF5757) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isRecording ? const Color(0xFFFF5757) : const Color(0xFF1A1A1A),
                width: 1.5,
              ),
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording ? const Color(0xFF0A0A0A) : Colors.white70,
              size: 18,
            ),
          ),
        ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              _formatDuration(_elapsed),
              style: const TextStyle(
                color: Color(0xFFFF5757),
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        if (_hasAudio && !_isRecording) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_circle, color: Color(0xFF39FF14), size: 18),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              setState(() => _hasAudio = false);
              widget.onAudioSaved(null);
            },
            child: const Icon(Icons.close, color: Colors.white38, size: 16),
          ),
        ],
      ],
    );
  }
}
