import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import '../models/comic_bubble.dart';

/// Pestaña de Globos de Diálogo para ComicAddDrawer
class ComicAddBubblesTab extends StatefulWidget {
  final ComicController controller;

  const ComicAddBubblesTab({super.key, required this.controller});

  @override
  State<ComicAddBubblesTab> createState() => _ComicAddBubblesTabState();
}

class _ComicAddBubblesTabState extends State<ComicAddBubblesTab> {
  ComicBubbleType _selectedBubbleType = ComicBubbleType.mangaOval;
  final TextEditingController _bubbleTextCtrl = TextEditingController(text: '¡Hola!');

  @override
  void dispose() {
    _bubbleTextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input y botón agregar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _bubbleTextCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Escribe tu diálogo...',
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B00),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onPressed: () {
                  final text = _bubbleTextCtrl.text.trim().isEmpty ? '¡Hola!' : _bubbleTextCtrl.text.trim();
                  widget.controller.addBubble(type: _selectedBubbleType, text: text);
                  Navigator.of(context).pop();
                },
                child: const Text('AGREGAR', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Chips de sugerencia rápida
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: ['¡Hola!', '¡¿QUÉ?!', '...', '¡NO PUEDE SER!', 'Te amo ❤️', '¡ZAS!'].map((phrase) {
              return GestureDetector(
                onTap: () => setState(() => _bubbleTextCtrl.text = phrase),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(phrase, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Grilla visual de 12 estilos de globo
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.5,
            ),
            itemCount: ComicBubbleType.values.length,
            itemBuilder: (context, index) {
              final type = ComicBubbleType.values[index];
              final isSel = _selectedBubbleType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedBubbleType = type),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFFF6B00).withValues(alpha: 0.25) : const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(type.icon, color: isSel ? const Color(0xFFFF6B00) : Colors.white70, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          color: isSel ? const Color(0xFFFF6B00) : Colors.white70,
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
