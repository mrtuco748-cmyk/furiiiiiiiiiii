import 'package:flutter/material.dart';
import '../controllers/comic_controller.dart';
import 'comic_add_bubbles_tab.dart';
import 'comic_add_panels_tab.dart';
import 'comic_add_sfx_tab.dart';

/// Modal deslizable inferior no invasivo para agregar Viñetas, Globos y SFX individualmente.
class ComicAddDrawer extends StatefulWidget {
  final ComicController controller;

  const ComicAddDrawer({super.key, required this.controller});

  static Future<void> show(BuildContext context, ComicController controller) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ComicAddDrawer(controller: controller),
    );
  }

  @override
  State<ComicAddDrawer> createState() => _ComicAddDrawerState();
}

class _ComicAddDrawerState extends State<ComicAddDrawer> {
  int _activeTab = 0; // 0: Viñetas, 1: Globos, 2: SFX

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.58;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Tirador superior deslizable
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Selector de pestañas grandes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton(index: 0, label: 'Viñeta', icon: Icons.crop_square, color: const Color(0xFF00D4FF)),
                const SizedBox(width: 8),
                _buildTabButton(index: 1, label: 'Globo', icon: Icons.chat_bubble_outline, color: const Color(0xFFFF6B00)),
                const SizedBox(width: 8),
                _buildTabButton(index: 2, label: 'SFX', icon: Icons.flash_on, color: const Color(0xFFFFDE59)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Contenido de la pestaña activa
          Expanded(
            child: IndexedStack(
              index: _activeTab,
              children: [
                ComicAddPanelsTab(controller: widget.controller),
                ComicAddBubblesTab(controller: widget.controller),
                ComicAddSfxTab(controller: widget.controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? color : const Color(0xFF262626),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isActive ? Colors.black : Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
