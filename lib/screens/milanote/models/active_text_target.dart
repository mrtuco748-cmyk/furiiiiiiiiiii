/// Indica qué parte del texto de una nota está enfocada actualmente durante la edición
/// para que el sidebar derecho aplique fuentes, colores y formatos al bloque exacto.
class ActiveTextTarget {
  final bool isTitle;
  final int? paragraphIndex;

  const ActiveTextTarget.title()
      : isTitle = true,
        paragraphIndex = null;

  const ActiveTextTarget.bodyDefault()
      : isTitle = false,
        paragraphIndex = null;

  const ActiveTextTarget.paragraph(int index)
      : isTitle = false,
        paragraphIndex = index;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveTextTarget &&
        other.isTitle == isTitle &&
        other.paragraphIndex == paragraphIndex;
  }

  @override
  int get hashCode => Object.hash(isTitle, paragraphIndex);
}
