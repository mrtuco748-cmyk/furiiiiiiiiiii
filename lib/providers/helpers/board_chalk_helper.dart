import 'dart:math' as math;
import 'package:flutter/painting.dart';

import '../../models/board_element.dart';

class BoardChalkHelper {
  static BoardElement? buildChalkStrokeElement({
    int boardId = 1,
    required List<Offset> points,
    required String colorHex,
    double strokeWidth = 6.0,
  }) {
    if (points.isEmpty) return null;
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    final serializedPoints = <List<double>>[];
    for (final p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
      serializedPoints.add([
        double.parse(p.dx.toStringAsFixed(1)),
        double.parse(p.dy.toStringAsFixed(1)),
      ]);
    }

    final now = DateTime.now().toIso8601String();
    return BoardElement(
      boardId: boardId,
      userId: 'Facu',
      type: 'chalk_stroke',
      title: 'chalk',
      content: '',
      color: colorHex,
      x: minX,
      y: minY,
      width: math.max(1.0, maxX - minX),
      height: math.max(1.0, maxY - minY),
      data: {
        'points': serializedPoints,
        'strokeWidth': strokeWidth,
      },
      synced: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  static int? getLastChalkStrokeId(List<BoardElement> elements, int boardId) {
    final strokes = elements
        .where((e) => e.boardId == boardId && e.type == 'chalk_stroke')
        .toList();
    if (strokes.isEmpty) return null;
    return strokes.last.id;
  }

  static List<int> getAllChalkStrokeIds(
      List<BoardElement> elements, int boardId) {
    return elements
        .where((e) => e.boardId == boardId && e.type == 'chalk_stroke')
        .map((e) => e.id)
        .whereType<int>()
        .toList();
  }
}
