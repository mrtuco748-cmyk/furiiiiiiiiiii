import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/location_provider.dart';
import '../../../router.dart';
import '../../../services/sound_service.dart';
import '../../../theme/app_theme.dart';

class HomeShortcutHandler {
  static void execute(BuildContext context, String action, AppMode mode) {
    HapticFeedback.mediumImpact();
    switch (action) {
      case 'open_letters':
        context.push(RouterRoutes.cartas, extra: {'mode': mode});
        break;
      case 'write_letter':
        context.push(RouterRoutes.cartas, extra: {'create': true, 'mode': mode});
        break;
      case 'schedule_school':
        context.push(RouterRoutes.calendar, extra: {'create': true, 'createClass': true});
        break;
      case 'open_music':
        context.push(RouterRoutes.music, extra: {'tab': 0});
        break;
      case 'open_playlists':
        context.push(RouterRoutes.music, extra: {'tab': 1});
        break;
      case 'search_music':
        context.push(RouterRoutes.music, extra: {'tab': 2});
        break;
      case 'update_gps':
        quickUpdateGps(context);
        break;
      case 'open_map':
        context.push(RouterRoutes.mapa, extra: mode);
        break;
      case 'open_metas':
        context.push(RouterRoutes.metas);
        break;
      case 'open_retos':
        context.push(RouterRoutes.retos);
        break;
      case 'open_rewards':
        context.push(RouterRoutes.rewards);
        break;
      case 'open_achievements':
        context.push(RouterRoutes.logros);
        break;
      case 'log_workout':
        context.push(RouterRoutes.ejercicios, extra: mode);
        break;
      default:
        break;
    }
  }

  static Future<void> quickUpdateGps(BuildContext context) async {
    HapticFeedback.heavyImpact();
    SoundService().pop();
    final lpv = context.read<LocationProvider>();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF222222),
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF39FF14)),
              ),
              SizedBox(width: 12),
              Text('Actualizando ubicación GPS...', style: TextStyle(color: Colors.white)),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor activa la ubicación / GPS del dispositivo')),
          );
        }
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
        }
        return;
      }

      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await lpv.updateMyLocation(lastKnown.latitude, lastKnown.longitude);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
      );
      final ok = await lpv.updateMyLocation(pos.latitude, pos.longitude);
      if (context.mounted && ok) {
        SoundService().success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF39FF14),
            content: Text(
              '¡Ubicación actualizada con éxito!',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar GPS: $e')),
        );
      }
    }
  }
}
