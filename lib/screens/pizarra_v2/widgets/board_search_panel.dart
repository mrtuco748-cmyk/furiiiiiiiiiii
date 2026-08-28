import 'package:flutter/material.dart';
import '../../../models/board_element_v2.dart';
import '../../../providers/board_provider_v2.dart';

class BoardSearchPanel extends StatefulWidget {
  final BoardProviderV2 provider;
  final String searchText;
  final Function(String) onSearchChanged;
  final VoidCallback onClose;
  final Function(BoardElementV2) onGoToElement;

  const BoardSearchPanel({
    super.key,
    required this.provider,
    required this.searchText,
    required this.onSearchChanged,
    required this.onClose,
    required this.onGoToElement,
  });

  @override
  State<BoardSearchPanel> createState() => _BoardSearchPanelState();
}

class _BoardSearchPanelState extends State<BoardSearchPanel> {
  List<BoardElementV2> _pool = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPool();
  }

  Future<void> _loadPool() async {
    final pool = await widget.provider.loadSearchPool();
    if (mounted) {
      setState(() {
        _pool = pool;
        _loading = false;
      });
    }
  }

  List<BoardElementV2> get _results {
    final q = widget.searchText.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _pool.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.content.toLowerCase().contains(q);
    }).toList();
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autofocus: true,
                onChanged: widget.onSearchChanged,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar en todos los tableros...',
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                    fontFamily: 'monospace',
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF39FF14),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              if (!_loading && _results.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final el in _results)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            _typeIcon(el.type),
                            color: Colors.white70,
                            size: 18,
                          ),
                          title: Text(
                            el.title.isNotEmpty ? el.title : el.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                          ),
                          onTap: () => widget.onGoToElement(el),
                        ),
                    ],
                  ),
                ),
              if (!_loading &&
                  widget.searchText.isNotEmpty &&
                  _results.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Sin resultados',
                    style: TextStyle(
                      color: Colors.white54,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case BoardElementType.note:
        return Icons.note;
      case BoardElementType.checklist:
        return Icons.checklist;
      case BoardElementType.drawing:
        return Icons.draw;
      case BoardElementType.video:
        return Icons.videocam;
      case BoardElementType.audio:
        return Icons.mic;
      case BoardElementType.connector:
        return Icons.timeline;
      case BoardElementType.subBoard:
        return Icons.dashboard;
      default:
        return Icons.note;
    }
  }
}