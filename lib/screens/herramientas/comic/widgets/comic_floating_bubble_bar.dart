import 'package:flutter/material.dart';
import '../models/comic_bubble.dart';

/// Barra de edición de globos de texto compacta, acoplada y no invasiva.
/// En solo 2 filas limpias integra: texto en vivo, dirección de cola, forma y borrado.
class ComicFloatingBubbleBar extends StatefulWidget {
  final ComicBubble? bubble;
  final ValueChanged<ComicBubble> onSave;
  final ValueChanged<String>? onDelete;
  final VoidCallback onClose;

  const ComicFloatingBubbleBar({
    super.key,
    this.bubble,
    required this.onSave,
    this.onDelete,
    required this.onClose,
  });

  @override
  State<ComicFloatingBubbleBar> createState() => _ComicFloatingBubbleBarState();
}

class _ComicFloatingBubbleBarState extends State<ComicFloatingBubbleBar> {
  late final TextEditingController _textCtrl;
  late ComicBubbleType _type;
  late ComicTailDirection _tailDirection;
  late Color _backgroundColor;
  late Color _borderColor;
  late Color _textColor;

  @override
  void initState() {
    super.initState();
    final b = widget.bubble;
    _textCtrl = TextEditingController(text: b?.text ?? '¡Hola!');
    _type = b?.type ?? ComicBubbleType.mangaOval;
    _tailDirection = b?.tailDirection ?? ComicTailDirection.bottom;
    _backgroundColor = b?.backgroundColor ?? const Color(0xFFFFFFFF);
    _borderColor = b?.borderColor ?? const Color(0xFF111111);
    _textColor = b?.textColor ?? const Color(0xFF111111);
  }

  @override
  void didUpdateWidget(covariant ComicFloatingBubbleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bubble?.id != widget.bubble?.id) {
      final b = widget.bubble;
      _textCtrl.text = b?.text ?? '¡Hola!';
      _type = b?.type ?? ComicBubbleType.mangaOval;
      _tailDirection = b?.tailDirection ?? ComicTailDirection.bottom;
      _backgroundColor = b?.backgroundColor ?? const Color(0xFFFFFFFF);
      _borderColor = b?.borderColor ?? const Color(0xFF111111);
      _textColor = b?.textColor ?? const Color(0xFF111111);
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _applyLiveChanges() {
    final text = _textCtrl.text.trim();
    final b = widget.bubble;
    final result = (b ??
            ComicBubble(
              id: 'bubble_${DateTime.now().microsecondsSinceEpoch}',
              type: _type,
              text: text.isEmpty ? '...' : text,
            ))
        .copyWith(
      text: text.isEmpty ? '...' : text,
      type: _type,
      tailDirection: _tailDirection,
      backgroundColor: _backgroundColor,
      borderColor: _borderColor,
      textColor: _textColor,
    );
    widget.onSave(result);
  }

  void _cycleTailDirection() {
    const order = [
      ComicTailDirection.bottom,
      ComicTailDirection.left,
      ComicTailDirection.top,
      ComicTailDirection.right,
      ComicTailDirection.none,
    ];
    final nextIdx = (order.indexOf(_tailDirection) + 1) % order.length;
    setState(() => _tailDirection = order[nextIdx]);
    _applyLiveChanges();
  }

  IconData _tailIcon(ComicTailDirection dir) {
    switch (dir) {
      case ComicTailDirection.bottom:
        return Icons.south;
      case ComicTailDirection.top:
        return Icons.north;
      case ComicTailDirection.left:
        return Icons.west;
      case ComicTailDirection.right:
        return Icons.east;
      case ComicTailDirection.none:
        return Icons.do_not_disturb_alt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 196,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF333333), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(-2, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera: Título + Cola + Borrar + Confirmar
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF00D4FF)),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'GLOBO',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                  ),
                ),
                // Botón rápido de cola
                GestureDetector(
                  onTap: _cycleTailDirection,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF444444)),
                    ),
                    child: Icon(_tailIcon(_tailDirection), size: 14, color: const Color(0xFFFFDE59)),
                  ),
                ),
                const SizedBox(width: 4),
                // Eliminar
                if (widget.bubble != null && widget.onDelete != null) ...[
                  GestureDetector(
                    onTap: () => widget.onDelete!(widget.bubble!.id),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E1A1A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_outline, color: Color(0xFFFF453A), size: 16),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                // Confirmar / Cerrar
                GestureDetector(
                  onTap: widget.onClose,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF39FF14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.check, color: Colors.black, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Input de texto integrado
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF262626),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TextField(
                controller: _textCtrl,
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Escribe diálogo...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 11),
                ),
                onChanged: (_) => _applyLiveChanges(),
              ),
            ),
            const SizedBox(height: 8),

            // Selector horizontal / envolvente de forma
            const Text(
              'FORMA DE GLOBO',
              style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildShapeChip('Óvalo', ComicBubbleType.mangaOval),
                _buildShapeChip('Grito', ComicBubbleType.screamSpiky),
                _buildShapeChip('Pensar', ComicBubbleType.thoughtCloud),
                _buildShapeChip('Eléctrico', ComicBubbleType.electricShonen),
                _buildShapeChip('Onda', ComicBubbleType.dizzyWavy),
                _buildShapeChip('Narrador', ComicBubbleType.narratorBox),
                _buildShapeChip('Chat', ComicBubbleType.furiChat),
                _buildShapeChip('Impacto', ComicBubbleType.impactExplosion),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeChip(String label, ComicBubbleType type) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () {
        setState(() => _type = type);
        _applyLiveChanges();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF262626),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF3A3A3A),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
