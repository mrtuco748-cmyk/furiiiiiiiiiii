import 'package:flutter/material.dart';

import '../../../providers/location_provider.dart';

class ManualLocationDialog {
  static Future<void> show(
    BuildContext context,
    LocationProvider lpv,
    VoidCallback onLocationUpdated,
  ) async {
    final mine = lpv.effectiveMyLocation;
    final latCtrl = TextEditingController(text: mine.lat.toString());
    final lngCtrl = TextEditingController(text: mine.lng.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        title: const Icon(Icons.my_location, color: Colors.white, size: 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Latitud'),
            ),
            TextField(
              controller: lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Longitud'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar',
                style: TextStyle(color: Color(0xFF00D4FF))),
          ),
        ],
      ),
    );
    final lat = double.tryParse(latCtrl.text);
    final lng = double.tryParse(lngCtrl.text);
    if (ok == true && lat != null && lng != null) {
      await lpv.updateMyLocation(lat, lng);
      onLocationUpdated();
    }
  }
}
