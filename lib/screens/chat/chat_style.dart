import 'package:flutter/material.dart';

/// Paleta compartida del chat. Antes eran constantes privadas de chat_screen;
/// al extraer los widgets a archivos propios viven acá para que todos los usen.
class ChatStyle {
  static const primary = Color(0xFFFF6B00);
  static const bg = Color(0xFF1A0F08);
  static const panel = Color(0xFF2A1810);
  static const inputBg = Color(0xFFFF6B00);
  static const darkText = Color(0xFF1A0F08);
  static const errorBg = Color(0xFF5A1010);
  static const mediaBg = Color(0xFF3A2418);
}