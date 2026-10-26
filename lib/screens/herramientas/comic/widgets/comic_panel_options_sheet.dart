import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/comic_panel.dart';

/// Modal con opciones de viñeta: dibujar a tamaño real, insertar dibujo existente,
/// ajustar escala/encuadre o limpiar viñeta.
class ComicPanelOptionsSheet extends StatefulWidget {
  final ComicPanel panel;
  final VoidCallback onDrawInPanel;
  final VoidCallback onInsertDrawing;
  final void Function(double scale, double dx, double dy) onTransform;
  final VoidCallback onClearPanel;

  const ComicPanelOptionsSheet({
    super.key,
    required this.panel,
    required this.onDrawInPanel,
    required this.onInsertDrawing,
    required this.onTransform,
    required this.onClearPanel,
  });

  @override
  State<ComicPanelOptionsSheet> createState() => _ComicPanelOptionsSheetState();
}

class _ComicPanelOptionsSheetState extends State<ComicPanelOptionsSheet> {
  late double _scale;
  late double _offsetX;
  late double _offsetY;

  @override
  void initState() {
    super.initState();
    _scale = widget.panel.scale;
    _offsetX = widget.panel.offsetX;
    _offsetY = widget.panel.offsetY;
  }

  void _updateTransform() {
    widget.onTransform(_scale, _offsetX, _offsetY);
  }

  @override
  Widget build(BuildContext context) {
    final hasDrawing = widget.panel.drawingPngBase64 != null;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.crop_square_outlined, color: Color(0xFF00D4FF), size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'OPCIONES DE VIÑETA',
                      style: GoogleFonts.bangers(fontSize: 22, color: Colors.white, letterSpacing: 1),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Acción 1: Dibujar a tamaño real de esta viñeta
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).pop();
                widget.onDrawInPanel();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.brush, color: Colors.black, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'DIBUJAR EN ESTA VIÑETA',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Lienzo a proporción exacta del panel',
                            style: TextStyle(color: Colors.black87, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Acción 2: Elegir de Dibujos Guardados
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.of(context).pop();
                widget.onInsertDrawing();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF39FF14),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_outlined, color: Colors.black, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'INSERTAR DIBUJO GUARDADO',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Cargar desde tus obras de dibujo digital',
                            style: TextStyle(color: Colors.black87, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black),
                  ],
                ),
              ),
            ),

            if (hasDrawing) ...[
              const SizedBox(height: 20),
              const Text(
                'ENCUADRE Y ESCALA',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // Control Escala
              Row(
                children: [
                  const Text('ESCALA', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Expanded(
                    child: SliderTheme(
                      data: const SliderThemeData(
                        thumbColor: Color(0xFFFF00FF),
                        activeTrackColor: Color(0xFFFF00FF),
                        inactiveTrackColor: Color(0xFF333333),
                      ),
                      child: Slider(
                        value: _scale.clamp(0.5, 3.0),
                        min: 0.5,
                        max: 3.0,
                        onChanged: (val) {
                          setState(() => _scale = val);
                          _updateTransform();
                        },
                      ),
                    ),
                  ),
                  Text('${(_scale * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),

              // Control Eje X
              Row(
                children: [
                  const Text('PAN X', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Expanded(
                    child: SliderTheme(
                      data: const SliderThemeData(
                        thumbColor: Color(0xFFFFDE59),
                        activeTrackColor: Color(0xFFFFDE59),
                        inactiveTrackColor: Color(0xFF333333),
                      ),
                      child: Slider(
                        value: _offsetX.clamp(-200.0, 200.0),
                        min: -200,
                        max: 200,
                        onChanged: (val) {
                          setState(() => _offsetX = val);
                          _updateTransform();
                        },
                      ),
                    ),
                  ),
                  Text('${_offsetX.toInt()} px', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),

              // Control Eje Y
              Row(
                children: [
                  const Text('PAN Y', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Expanded(
                    child: SliderTheme(
                      data: const SliderThemeData(
                        thumbColor: Color(0xFFFFDE59),
                        activeTrackColor: Color(0xFFFFDE59),
                        inactiveTrackColor: Color(0xFF333333),
                      ),
                      child: Slider(
                        value: _offsetY.clamp(-200.0, 200.0),
                        min: -200,
                        max: 200,
                        onChanged: (val) {
                          setState(() => _offsetY = val);
                          _updateTransform();
                        },
                      ),
                    ),
                  ),
                  Text('${_offsetY.toInt()} px', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),

              // Botón Quitar Dibujo
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C1515),
                  foregroundColor: const Color(0xFFFF453A),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onClearPanel();
                },
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('QUITAR DIBUJO DE ESTA VIÑETA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
