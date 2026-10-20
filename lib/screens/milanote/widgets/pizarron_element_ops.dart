import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/board_element.dart';
import '../../../providers/board_data_provider.dart';
import '../models/note_style_config.dart';
import 'pizarron_camera_math.dart';

/// Operaciones de creación de elementos y selección de imágenes en el Pizarrón.
class PizarronElementOps {
  static final ImagePicker _imagePicker = ImagePicker();

  static Future<BoardElement> createNewElement({
    required int boardId,
    required String type,
    required Size screenSize,
    required Offset cameraPan,
    required double cameraScale,
    required BoardDataProvider provider,
  }) async {
    final center = PizarronCameraMath.screenToWorld(
      Offset(screenSize.width / 2, screenSize.height / 2),
      cameraPan,
      cameraScale,
    );
    const w = 260.0;
    const h = 220.0;
    final cfg = NoteStyleConfig(
      solidColor: type == 'checklist' ? '#1F2D1E' : '#1E2436',
      checklistItems:
          type == 'checklist' ? [{'text': '', 'done': false}] : const [],
    );
    return await provider.addElement(
      boardId: boardId,
      type: type,
      title: '',
      content: '',
      color: cfg.solidColor,
      x: center.dx - w / 2,
      y: center.dy - h / 2,
      width: w,
      height: h,
      data: cfg.toDataMap(),
    );
  }

  static Future<void> pickAndApplyImage({
    required bool isBackground,
    required BoardElement element,
    required BoardDataProvider provider,
  }) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1100,
        maxHeight: 1100,
        imageQuality: 78,
      );
      if (picked == null) return;
      final b64 = base64Encode(await picked.readAsBytes());
      final cfg = NoteStyleConfig.fromElement(
        fallbackColor: element.color,
        data: element.data,
      );
      final updated = isBackground
          ? cfg.copyWith(baseMode: 'image', bgImageBase64: b64)
          : cfg.copyWith(inlineImageBase64: b64);
      await provider.updateElement(
        element.copyWith(
          color: updated.solidColor,
          data: updated.toDataMap(),
        ),
      );
    } catch (_) {}
  }
}
