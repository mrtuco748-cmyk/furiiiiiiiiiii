import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Diálogo interactivo para configurar dimensiones de lienzo en px o cm (300 DPI)
/// con presets estándar para dibujo digital y viñetas de cómic.
class CanvasDimensionsDialog extends StatefulWidget {
  final Size initialSize;
  final double? panelAspectRatio;

  const CanvasDimensionsDialog({
    super.key,
    this.initialSize = const Size(2048, 2048),
    this.panelAspectRatio,
  });

  static Future<Size?> show(BuildContext context, {Size? initialSize, double? panelAspectRatio}) {
    return showDialog<Size>(
      context: context,
      builder: (ctx) => CanvasDimensionsDialog(
        initialSize: initialSize ?? const Size(2048, 2048),
        panelAspectRatio: panelAspectRatio,
      ),
    );
  }

  @override
  State<CanvasDimensionsDialog> createState() => _CanvasDimensionsDialogState();
}

class _CanvasDimensionsDialogState extends State<CanvasDimensionsDialog> {
  bool _isCmMode = false;
  late final TextEditingController _widthCtrl;
  late final TextEditingController _heightCtrl;

  static const double dpi = 300.0;
  static const double cmToInch = 2.54;

  @override
  void initState() {
    super.initState();
    _widthCtrl = TextEditingController(text: widget.initialSize.width.round().toString());
    _heightCtrl = TextEditingController(text: widget.initialSize.height.round().toString());
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _switchUnit(bool cm) {
    if (_isCmMode == cm) return;
    final w = double.tryParse(_widthCtrl.text) ?? 2048.0;
    final h = double.tryParse(_heightCtrl.text) ?? 2048.0;
    setState(() {
      _isCmMode = cm;
      if (cm) {
        _widthCtrl.text = ((w / dpi) * cmToInch).toStringAsFixed(1);
        _heightCtrl.text = ((h / dpi) * cmToInch).toStringAsFixed(1);
      } else {
        _widthCtrl.text = ((w / cmToInch) * dpi).round().toString();
        _heightCtrl.text = ((h / cmToInch) * dpi).round().toString();
      }
    });
  }

  void _applyPreset(int pxW, int pxH) {
    setState(() {
      if (_isCmMode) {
        _widthCtrl.text = ((pxW / dpi) * cmToInch).toStringAsFixed(1);
        _heightCtrl.text = ((pxH / dpi) * cmToInch).toStringAsFixed(1);
      } else {
        _widthCtrl.text = pxW.toString();
        _heightCtrl.text = pxH.toString();
      }
    });
  }

  Size? _calculateResult() {
    final wVal = double.tryParse(_widthCtrl.text);
    final hVal = double.tryParse(_heightCtrl.text);
    if (wVal == null || hVal == null || wVal <= 0 || hVal <= 0) return null;

    final double pxW = _isCmMode ? (wVal / cmToInch) * dpi : wVal;
    final double pxH = _isCmMode ? (hVal / cmToInch) * dpi : hVal;

    return Size(pxW.clamp(100.0, 8000.0), pxH.clamp(100.0, 8000.0));
  }

  Widget _buildPresetChip(String label, int w, int h) {
    return GestureDetector(
      onTap: () => _applyPreset(w, h),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label\n${w}x$h',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.aspect_ratio, color: Color(0xFF00D4FF), size: 22),
          const SizedBox(width: 8),
          Text(
            'DIMENSIONES DEL LIENZO',
            style: GoogleFonts.bangers(color: Colors.white, fontSize: 18, letterSpacing: 0.8),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector de unidad (px / cm)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchUnit(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isCmMode ? const Color(0xFF00D4FF) : const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'PÍXELES (px)',
                        style: TextStyle(
                          color: !_isCmMode ? const Color(0xFF111111) : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchUnit(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isCmMode ? const Color(0xFF00D4FF) : const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'CENTÍMETROS (cm)',
                        style: TextStyle(
                          color: _isCmMode ? const Color(0xFF111111) : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campos Ancho y Alto
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Ancho (${_isCmMode ? 'cm' : 'px'})',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF262626),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Alto (${_isCmMode ? 'cm' : 'px'})',
                      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF262626),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Presets populares
            const Text('Presets Rápidos:', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildPresetChip('Cuadrado', 2048, 2048),
                _buildPresetChip('Hoja A4', 2480, 3508),
                _buildPresetChip('Manga B5', 1820, 2570),
                _buildPresetChip('Full HD', 1920, 1080),
                _buildPresetChip('Historia', 1080, 1920),
                if (widget.panelAspectRatio != null)
                  _buildPresetChip('Panel Viñeta', 1600, (1600 / widget.panelAspectRatio!).round()),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            foregroundColor: const Color(0xFF111111),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            final res = _calculateResult();
            if (res != null) {
              Navigator.of(context).pop(res);
            }
          },
          child: const Text('CREAR LIENZO', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
