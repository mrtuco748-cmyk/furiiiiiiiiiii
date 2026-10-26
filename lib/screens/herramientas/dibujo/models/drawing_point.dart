import 'dart:ui';

/// Representa un punto capturado en el trazo del lienzo con posición,
/// presión estimada y marca de tiempo.
class DrawingPoint {
  final Offset offset;
  final double pressure;
  final int timestamp;

  DrawingPoint({
    required this.offset,
    this.pressure = 1.0,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  DrawingPoint copyWith({
    Offset? offset,
    double? pressure,
    int? timestamp,
  }) {
    return DrawingPoint(
      offset: offset ?? this.offset,
      pressure: pressure ?? this.pressure,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
