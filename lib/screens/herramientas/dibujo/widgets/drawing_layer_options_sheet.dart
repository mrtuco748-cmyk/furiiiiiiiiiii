import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/drawing_controller.dart';
import '../models/drawing_layer.dart';

/// Modal para editar todas las propiedades de una capa de dibujo:
/// Opacidad en vivo, bloqueo, visibilidad, duplicado, fusión hacia abajo, renombrado y eliminación.
class DrawingLayerOptionsSheet extends StatefulWidget {
  final DrawingController controller;
  final int layerIndex;

  const DrawingLayerOptionsSheet({
    super.key,
    required this.controller,
    required this.layerIndex,
  });

  static Future<void> show(BuildContext context, DrawingController controller, int index) {
    if (index >= 0 && index < controller.layers.length) {
      controller.setActiveLayer(index);
    }
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DrawingLayerOptionsSheet(controller: controller, layerIndex: index),
    );
  }

  @override
  State<DrawingLayerOptionsSheet> createState() => _DrawingLayerOptionsSheetState();
}

class _DrawingLayerOptionsSheetState extends State<DrawingLayerOptionsSheet> {
  late double _opacity;

  DrawingLayer? get _layer {
    if (widget.layerIndex < 0 || widget.layerIndex >= widget.controller.layers.length) return null;
    return widget.controller.layers[widget.layerIndex];
  }

  @override
  void initState() {
    super.initState();
    _opacity = _layer?.opacity ?? 1.0;
  }

  Future<void> _renameLayer() async {
    final layer = _layer;
    if (layer == null) return;
    final textCtrl = TextEditingController(text: layer.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Renombrar Capa', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: const InputDecoration(hintText: 'Nombre de la capa', hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () { final t = textCtrl.text.trim(); if (t.isNotEmpty) Navigator.of(ctx).pop(t); },
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      widget.controller.renameLayer(widget.layerIndex, newName);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final layer = _layer;
    if (layer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }
    final canMergeDown = widget.layerIndex > 0;
    final totalLayers = widget.controller.layers.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con nombre editable y botón cerrar
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          layer.name,
                          style: GoogleFonts.bangers(color: Colors.white, fontSize: 20, letterSpacing: 0.8),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _renameLayer,
                        child: const Icon(Icons.edit, size: 16, color: Color(0xFF00D4FF)),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(color: Color(0xFF282828), shape: BoxShape.circle),
                    child: const Icon(Icons.close, color: Colors.white70, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Slider de Opacidad en vivo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Opacidad de Capa', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('${(_opacity * 100).round()}%', style: const TextStyle(color: Color(0xFF00D4FF), fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF00D4FF),
                inactiveTrackColor: const Color(0xFF2A2A2A),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _opacity.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                onChanged: (v) {
                  setState(() => _opacity = v);
                  widget.controller.setLayerOpacity(widget.layerIndex, v);
                },
              ),
            ),
            const SizedBox(height: 12),

            // Acciones Rápidas
            Row(
              children: [
                // Visibilidad
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.controller.toggleLayerVisibility(widget.layerIndex);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: layer.isVisible ? const Color(0xFF282828) : const Color(0xFF332020),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(layer.isVisible ? Icons.visibility : Icons.visibility_off, color: layer.isVisible ? Colors.white : Colors.white38, size: 20),
                          const SizedBox(height: 4),
                          Text(layer.isVisible ? 'Visible' : 'Oculta', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Bloqueo
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      widget.controller.toggleLayerLock(widget.layerIndex);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: layer.isLocked ? const Color(0xFF3A2B18) : const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(layer.isLocked ? Icons.lock : Icons.lock_open, color: layer.isLocked ? const Color(0xFFFFDE59) : Colors.white70, size: 20),
                          const SizedBox(height: 4),
                          Text(layer.isLocked ? 'Bloqueada' : 'Libre', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Duplicar
                Expanded(
                  child: GestureDetector(
                    onTap: () { Navigator.of(context).pop(); widget.controller.duplicateActiveLayer(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(10)),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_all, color: Colors.white70, size: 20),
                          SizedBox(height: 4),
                          Text('Duplicar', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Fusionar Abajo
                if (canMergeDown)
                  Expanded(
                    child: GestureDetector(
                      onTap: () { Navigator.of(context).pop(); widget.controller.mergeActiveLayerDown(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(10)),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_merge, color: Color(0xFF00D4FF), size: 20),
                            SizedBox(height: 4),
                            Text('Fusionar', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Eliminar Capa
            if (totalLayers > 1)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  widget.controller.removeLayer(widget.layerIndex);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xFF2D1616), borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, color: Color(0xFFFF453A), size: 18),
                      SizedBox(width: 8),
                      Text('ELIMINAR CAPA', style: TextStyle(color: Color(0xFFFF453A), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
