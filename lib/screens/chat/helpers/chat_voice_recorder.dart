import 'dart:async';
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class ChatVoiceRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  DateTime? _recordStarted;
  Timer? _recordTicker;

  bool get isRecording => _recording;
  DateTime? get recordStarted => _recordStarted;

  String get recordLabel {
    if (!_recording || _recordStarted == null) return '';
    return '${DateTime.now().difference(_recordStarted!).inSeconds}s';
  }

  void dispose() {
    _recordTicker?.cancel();
    _recorder.dispose();
  }

  Future<String?> toggleRecord(void Function() onTick) async {
    if (_recording) {
      final path = await _recorder.stop();
      _recordTicker?.cancel();
      _recording = false;
      _recordStarted = null;
      return path;
    }

    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return null;
    if (!await _recorder.hasPermission()) return null;

    final dir = Directory.systemTemp;
    final out = '${dir.path}/furi_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: out,
    );
    _recording = true;
    _recordStarted = DateTime.now();
    _recordTicker = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
    return null;
  }
}
