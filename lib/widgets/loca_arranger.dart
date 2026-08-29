import 'dart:math';

/// Rectángulo de un bloque en la grilla "loca".
class LocaRect {
  final double left;
  final double top;
  final double width;
  final double height;
  final double rotation;

  const LocaRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.rotation,
  });
}

class _Node {
  final double left, top, width, height;
  final List<int> indices;
  const _Node(this.left, this.top, this.width, this.height, this.indices);
  double get area => width * height;
}

/// Genera la distribución "apilada" de las pantallas estilo Nosotros.
///
/// Un bloque por ítem, sin solapamiento, en mosaico desordenado: slicing
/// recursivo que parte SIEMPRE el bloque de mayor área cortando la dimensión
/// más larga. Con [weights] (una por ítem, p. ej. según la cantidad de texto)
/// el corte reparte el área en proporción a los pesos: los ítems con más
/// contenido reciben bloques más grandes. Bloques rectos (rotación 0),
/// cuadrados/rectángulos equilibrados (tamaños variados, nunca tiras).
abstract final class LocaArranger {
  static List<LocaRect> arrange({
    required double width,
    required double height,
    required int cantidad,
    int seed = 0,
    List<double>? weights,
  }) {
    if (width <= 0 || height <= 0 || cantidad < 1) {
      return const <LocaRect>[];
    }
    final wts = weights ?? List<double>.filled(cantidad, 1);
    assert(wts.length == cantidad);
    final rnd = Random(seed);
    final minW = width * 0.14;
    final minH = height * 0.14;

    var nodes = <_Node>[
      _Node(0, 0, width, height, List.generate(cantidad, (i) => i)),
    ];
    while (nodes.any((n) => n.indices.length > 1)) {
      nodes.sort((a, b) {
        final ac = a.indices.length > 1 ? a.area : -1.0;
        final bc = b.indices.length > 1 ? b.area : -1.0;
        return bc.compareTo(ac);
      });
      final node = nodes.removeAt(0);
      final s = node.indices;
      final k = s.length ~/ 2;
      final aIdx = s.sublist(0, k);
      final bIdx = s.sublist(k);
      final wA = aIdx.fold<double>(0, (sum, i) => sum + wts[i]);
      final wB = bIdx.fold<double>(0, (sum, i) => sum + wts[i]);
      final sum = wA + wB;
      var f = sum > 0 ? wA / sum : 0.5;
      // Pequeño jitter aleatorio (por seed) + proporción de pesos, acotado
      // para que todo siga siendo rectángulo equilibrado.
      f = f * (0.9 + rnd.nextDouble() * 0.2);
      f = f.clamp(0.4, 0.6);
      if (node.width >= node.height) {
        // Si el nodo ya es más chico que 2*minW no se puede respetar minW en
        // ambos hijos sin producir un hijo de ancho <= 0 (y luego NaN en la
        // siguiente división). En ese caso se parte al medio (f=0.5) y se
        // aceptan bloques más chicos que minW pero SIEMPRE positivos.
        final lo = minW / node.width;
        final hi = (node.width - minW) / node.width;
        if (lo <= hi) { f = f.clamp(lo, hi); } else { f = 0.5; }
        final w1 = node.width * f;
        nodes.add(_Node(node.left, node.top, w1, node.height, aIdx));
        nodes.add(_Node(node.left + w1, node.top, node.width - w1, node.height, bIdx));
      } else {
        final lo = minH / node.height;
        final hi = (node.height - minH) / node.height;
        if (lo <= hi) { f = f.clamp(lo, hi); } else { f = 0.5; }
        final h1 = node.height * f;
        nodes.add(_Node(node.left, node.top, node.width, h1, aIdx));
        nodes.add(_Node(node.left, node.top + h1, node.width, node.height - h1, bIdx));
      }
    }

    nodes.sort((a, b) => a.indices.first.compareTo(b.indices.first));
    return [
      for (final n in nodes)
        LocaRect(left: n.left, top: n.top, width: n.width, height: n.height, rotation: 0),
    ];
  }
}