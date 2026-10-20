import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Renderizador optimizado con caché en memoria de imágenes inline en notas.
class PizarronInlineImageWidget extends StatelessWidget {
  final Uint8List? imageBytes;
  final double height;

  const PizarronInlineImageWidget({
    super.key,
    required this.imageBytes,
    required this.height,
  });

  static Uint8List? tryDecodeBase64(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;
    try {
      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageBytes == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Image.memory(
          imageBytes!,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}
