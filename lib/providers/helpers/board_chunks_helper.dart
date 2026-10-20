import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../../models/board_element.dart';

class BoardChunksHelper {
  /// Obtiene los elementos correspondientes a un tablero específico
  static List<BoardElement> getElementsByBoard(
    List<BoardElement> elements,
    int boardId,
  ) {
    return elements
        .where((e) =>
            e.boardId == boardId &&
            e.type != 'board_config' &&
            e.type != 'chalk_stroke')
        .toList();
  }

  /// Filtra los elementos interactivos (notas y listas de tareas) que caen dentro
  /// del chunk activo (2x el tamaño de lo mostrado en pantalla).
  static List<BoardElement> getInteractiveElementsInChunk(
    List<BoardElement> elements,
    int boardId,
    Rect activeChunkWorldRect, {
    int? alwaysIncludeId,
  }) {
    final result = <BoardElement>[];
    for (final e in elements) {
      if (e.boardId != boardId) continue;
      if (e.type == 'board_config' ||
          e.type == 'chalk_stroke' ||
          e.type == 'connection') {
        continue;
      }
      if (alwaysIncludeId != null && e.id == alwaysIncludeId) {
        result.add(e);
        continue;
      }
      final elRect = Rect.fromLTWH(e.x, e.y, e.width, e.height);
      if (activeChunkWorldRect.overlaps(elRect)) {
        result.add(e);
      }
    }
    return result;
  }

  /// Obtiene los trazos de tiza en el fondo del pizarrón que intersectan el chunk activo (2x viewport).
  static List<BoardElement> getChalkStrokesInChunk(
    List<BoardElement> elements,
    int boardId,
    Rect activeChunkWorldRect,
  ) {
    final result = <BoardElement>[];
    for (final e in elements) {
      if (e.boardId != boardId || e.type != 'chalk_stroke') continue;
      final elRect = Rect.fromLTWH(
        e.x - 20,
        e.y - 20,
        math.max(40.0, e.width + 40),
        math.max(40.0, e.height + 40),
      );
      if (activeChunkWorldRect.overlaps(elRect)) {
        result.add(e);
      }
    }
    return result;
  }

  /// Obtiene todos los trazos de tiza del tablero.
  static List<BoardElement> getAllChalkStrokes(
    List<BoardElement> elements,
    int boardId,
  ) {
    return elements
        .where((e) => e.boardId == boardId && e.type == 'chalk_stroke')
        .toList();
  }

  /// Obtiene el color sólido de fondo configurado para el pizarrón (por defecto #141820).
  static String getBoardBackgroundColor(
    List<BoardElement> elements,
    int boardId,
  ) {
    for (final e in elements) {
      if (e.boardId == boardId && e.type == 'board_config') {
        if (e.color.isNotEmpty) return e.color;
      }
    }
    return '#141820';
  }
}
