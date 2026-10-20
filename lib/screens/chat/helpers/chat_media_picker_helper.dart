import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../providers/chat_provider.dart';
import '../../../services/chat_media_service.dart';
import '../widgets/chat_attachment_sheet.dart';

class ChatMediaPickerHelper {
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage({
    required bool fromCamera,
    required Future<void> Function({
      required String path,
      required String name,
      required String type,
      String? mime,
      int? size,
    }) onSend,
  }) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    await onSend(
      path: file.path,
      name: file.name,
      mime: file.mimeType ?? 'image/jpeg',
      type: 'image',
    );
  }

  Future<void> pickVideo({
    required Future<void> Function({
      required String path,
      required String name,
      required String type,
      String? mime,
      int? size,
    }) onSend,
  }) async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    await onSend(
      path: file.path,
      name: file.name,
      mime: file.mimeType ?? 'video/mp4',
      type: 'video',
    );
  }

  Future<void> pickFile({
    required Future<void> Function({
      required String path,
      required String name,
      required String type,
      String? mime,
      int? size,
    }) onSend,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    if (f.path == null) return;
    final type = ChatMediaService.guessMessageType(
      mime: f.extension == 'gif' ? 'image/gif' : null,
      fileName: f.name,
    );
    await onSend(
      path: f.path!,
      name: f.name,
      mime: f.extension != null ? chatMimeFromExt(f.extension!) : null,
      type: type,
      size: f.size,
    );
  }

  static Future<void> sendSticker({
    required File stickerFile,
    required ChatProvider chat,
    required VoidCallback onSent,
  }) async {
    HapticFeedback.mediumImpact();
    final name = 'sticker_${DateTime.now().millisecondsSinceEpoch}.webp';
    try {
      await chat.sendMedia(
        localPath: stickerFile.path,
        messageType: 'sticker',
        fileName: name,
        mimeType: 'image/webp',
        caption: 'Sticker',
      );
      onSent();
    } catch (_) {}
  }
}
