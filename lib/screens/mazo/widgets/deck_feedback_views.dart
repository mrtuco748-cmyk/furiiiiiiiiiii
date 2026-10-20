import 'package:flutter/material.dart';
import '../create_deck_card_modal.dart';

/// Vistas de estado vacío o con error para el mazo.
class DeckEmptyView extends StatelessWidget {
  final VoidCallback onAdd;

  const DeckEmptyView({super.key, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🃏', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'No hay tarjetas para deslizar',
            style: TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 16,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => showCreateDeckCardModal(context),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF39FF14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.add,
                  color: Color(0xFF1A1A1A), size: 34),
            ),
          ),
        ],
      ),
    );
  }
}

class DeckErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const DeckErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF5A0000),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No se pudieron cargar las tarjetas',
              style: TextStyle(
                color: Color(0xFFFFCACA),
                fontSize: 14,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.refresh,
                    color: Color(0xFF1A1A1A), size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
