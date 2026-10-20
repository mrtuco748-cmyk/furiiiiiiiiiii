import 'package:flutter/material.dart';
import '../../../providers/board_data_provider.dart';
import '../models/note_style_config.dart';
import 'pizarron_color_picker_area.dart';

/// Cluster de botón único '+' abajo a la derecha del Pizarrón:
/// - Despliegue de opciones (Nota, Checklist, Tuerca)
/// - Ajustes de color de fondo del tablero y modo Tiza
class PizarronBottomCluster extends StatelessWidget {
  final int boardId;
  final bool plusMenuOpen;
  final bool settingsOpen;
  final bool chalkMode;
  final String chalkColorHex;
  final double chalkStrokeWidth;
  final String currentBoardBgHex;
  final BoardDataProvider provider;
  final VoidCallback onTogglePlus;
  final VoidCallback onToggleSettings;
  final VoidCallback onToggleChalk;
  final ValueChanged<String> onChalkColorChanged;
  final ValueChanged<double> onChalkWidthChanged;
  final VoidCallback onCreateNote;
  final VoidCallback onCreateChecklist;

  const PizarronBottomCluster({
    super.key,
    required this.boardId,
    required this.plusMenuOpen,
    required this.settingsOpen,
    required this.chalkMode,
    required this.chalkColorHex,
    required this.chalkStrokeWidth,
    required this.currentBoardBgHex,
    required this.provider,
    required this.onTogglePlus,
    required this.onToggleSettings,
    required this.onToggleChalk,
    required this.onChalkColorChanged,
    required this.onChalkWidthChanged,
    required this.onCreateNote,
    required this.onCreateChecklist,
  });

  static const _vibrantGreen = Color(0xFF2EE50F);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (settingsOpen || chalkMode) ...[
          Container(
            width: 228,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSmallOptionButton(
                      icon: Icons.palette_rounded,
                      active: !chalkMode,
                      onTap: onToggleChalk,
                    ),
                    _buildSmallOptionButton(
                      icon: Icons.edit_rounded,
                      active: chalkMode,
                      activeColor: _vibrantGreen,
                      activeIconColor: const Color(0xFF141820),
                      onTap: onToggleChalk,
                    ),
                    if (chalkMode) ...[
                      _buildSmallOptionButton(
                        icon: Icons.undo_rounded,
                        active: false,
                        onTap: () => provider.undoLastChalkStroke(boardId),
                      ),
                      _buildSmallOptionButton(
                        icon: Icons.cleaning_services_rounded,
                        active: false,
                        onTap: () => provider.clearChalkStrokes(boardId),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (!chalkMode) ...[
                  PizarronColorPickerArea(
                    currentColorHex: currentBoardBgHex,
                    sampledColors: PizarronPalette.boardColors,
                    onColorChanged: (hex) =>
                        provider.setBoardBackgroundColor(boardId, hex),
                  ),
                ] else ...[
                  PizarronColorPickerArea(
                    currentColorHex: chalkColorHex,
                    sampledColors: PizarronPalette.chalkColors,
                    onColorChanged: onChalkColorChanged,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.line_weight_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            activeTrackColor: _vibrantGreen,
                            inactiveTrackColor: const Color(0xFF252C40),
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: chalkStrokeWidth,
                            min: 3.0,
                            max: 20.0,
                            onChanged: onChalkWidthChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (plusMenuOpen) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOptionOrb(
                  key: const ValueKey('pizarron_opt_settings'),
                  icon: Icons.settings_rounded,
                  bgColor: settingsOpen
                      ? const Color(0xFF7B2CBF)
                      : const Color(0xFF252C40),
                  iconColor: Colors.white,
                  onTap: onToggleSettings,
                ),
                const SizedBox(height: 10),
                _buildOptionOrb(
                  key: const ValueKey('pizarron_opt_checklist'),
                  icon: Icons.checklist_rounded,
                  bgColor: const Color(0xFF252C40),
                  iconColor: Colors.white,
                  onTap: onCreateChecklist,
                ),
                const SizedBox(height: 10),
                _buildOptionOrb(
                  key: const ValueKey('pizarron_opt_note'),
                  icon: Icons.sticky_note_2_rounded,
                  bgColor: const Color(0xFF252C40),
                  iconColor: Colors.white,
                  onTap: onCreateNote,
                ),
              ],
            ),
          ),
        ],
        GestureDetector(
          key: const ValueKey('pizarron_main_plus_button'),
          onTap: onTogglePlus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _vibrantGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              (plusMenuOpen || chalkMode)
                  ? Icons.close_rounded
                  : Icons.add_rounded,
              color: const Color(0xFF141820),
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionOrb({
    Key? key,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  Widget _buildSmallOptionButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
    Color activeColor = const Color(0xFF7B2CBF),
    Color activeIconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 40,
        decoration: BoxDecoration(
          color: active ? activeColor : const Color(0xFF252C40),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: active ? activeIconColor : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
