import 'package:flutter/material.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../app_state.dart';

const _accentFacu = Color(0xFF4FC3F7);
const _accentRocio = Color(0xFFCE93D8);

/// Panel para gestionar tags personalizados.
class BoardTagManager extends StatefulWidget {
  final BoardProviderV2 provider;
  final VoidCallback onClose;

  const BoardTagManager({super.key, required this.provider, required this.onClose});

  @override
  State<BoardTagManager> createState() => _BoardTagManagerState();
}

class _BoardTagManagerState extends State<BoardTagManager> {
  final _nameCtrl = TextEditingController();
  String _selectedColor = '#39FF14';

  final List<String> _colors = [
    '#39FF14', '#FF5757', '#FFDE59', '#00F0FF',
    '#FF66C4', '#9D00FF', '#FF8800', '#0088FF',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    widget.provider.saveTag(name, _selectedColor);
    _nameCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 12,
      right: 12,
      top: 64,
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Gestionar tags',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Existing tags
              if (widget.provider.savedTags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.provider.savedTags
                      .map<Widget>(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _parseColor(tag['color'] as String?, const Color(0xFF333333))
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _parseColor(tag['color'] as String?, const Color(0xFF333333)),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            tag['name'] as String,
                            style: TextStyle(
                              color: _parseColor(tag['color'] as String?, Colors.white),
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              if (widget.provider.savedTags.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No hay tags guardados',
                    style: TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF333333)),
              const SizedBox(height: 12),
              // Add new tag
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Nombre del tag',
                  hintStyle: const TextStyle(color: Colors.white54, fontFamily: 'monospace'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF333333)),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: _addTag,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _userColor(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: Color(0xFF0A0A0A), size: 18),
                    ),
                  ),
                ),
                onSubmitted: (_) => _addTag(),
              ),
              const SizedBox(height: 8),
              // Color picker
              Row(
                children: [
                  const Text(
                    'Color: ',
                    style: TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 12),
                  ),
                  ..._colors.map(
                    (c) => GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: _parseColor(c, Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedColor == c
                                ? const Color(0xFF4FC3F7)
                                : const Color(0xFF333333),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _userColor() {
    final identity = (AppState.identity ?? '').toLowerCase();
    if (identity.contains('facu')) return _accentFacu;
    if (identity.contains('rocio')) return _accentRocio;
    return _accentFacu;
  }

  Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}
