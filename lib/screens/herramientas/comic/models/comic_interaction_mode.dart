/// Modos de interacción táctil y gestual sobre la página del cómic.
enum ComicInteractionMode {
  normal,
  drawPanel,
  slicePanel,
  frameContent;

  bool get isNormal => this == ComicInteractionMode.normal;
  bool get isDrawPanel => this == ComicInteractionMode.drawPanel;
  bool get isSlicePanel => this == ComicInteractionMode.slicePanel;
  bool get isFrameContent => this == ComicInteractionMode.frameContent;
}
