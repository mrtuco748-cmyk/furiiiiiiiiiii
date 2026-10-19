import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/music_player_provider.dart';
import '../router.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';

/// Overlay global de F.U.R.I.
/// Provee:
/// 1. Notificaciones flotantes in-app con estilo brutalista propio de la app (tipo WhatsApp).
/// 2. Botonera flotante del reproductor de música con controles (como YouTube Music / Spotify).
class FuriGlobalOverlay extends StatefulWidget {
  final Widget child;
  const FuriGlobalOverlay({super.key, required this.child});

  @override
  State<FuriGlobalOverlay> createState() => _FuriGlobalOverlayState();
}

class _FuriGlobalOverlayState extends State<FuriGlobalOverlay>
    with TickerProviderStateMixin {
  // Notificaciones In-App
  StreamSubscription<InAppNotificationItem>? _notifSub;
  InAppNotificationItem? _currentNotif;
  late final AnimationController _notifAnimCtrl;
  late final Animation<Offset> _notifSlideAnim;
  late final Animation<double> _notifFadeAnim;
  Timer? _notifDismissTimer;

  // Mini reproductor de música flotante
  bool _musicBarDismissed = false;
  int? _lastTrackId;
  late final AnimationController _vinylAnimCtrl;

  @override
  void initState() {
    super.initState();

    // Animación de notificación in-app (cae desde arriba con suavidad)
    _notifAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _notifSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _notifAnimCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
    _notifFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _notifAnimCtrl, curve: Curves.easeOut),
    );

    // Animación de giro de disco para la botonera musical
    _vinylAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _notifSub = NotificationService.inAppNotificationStream.listen(_showInAppNotification);
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _notifDismissTimer?.cancel();
    _notifAnimCtrl.dispose();
    _vinylAnimCtrl.dispose();
    super.dispose();
  }

  void _showInAppNotification(InAppNotificationItem item) {
    if (!mounted) return;
    _notifDismissTimer?.cancel();
    setState(() => _currentNotif = item);
    _notifAnimCtrl.forward(from: 0.0);
    try {
      SoundService().pop();
    } catch (_) {}

    // Auto-descarte después de 4.5 segundos
    _notifDismissTimer = Timer(const Duration(milliseconds: 4500), () {
      _dismissNotification();
    });
  }

  void _dismissNotification() {
    if (!mounted || _currentNotif == null) return;
    _notifDismissTimer?.cancel();
    _notifAnimCtrl.reverse().then((_) {
      if (mounted) {
        setState(() => _currentNotif = null);
      }
    });
  }

  void _onNotificationTap(InAppNotificationItem item) {
    _dismissNotification();
    final type = (item.data['type'] as String?) ?? '';
    final route = routeForNotificationType(type) ?? RouterRoutes.notifications;
    appRouter.push(route);
  }

  Color _categoryColor(String type) {
    switch (type) {
      case 'message':
        return const Color(0xFF7000FF); // Violeta
      case 'letter':
      case 'mood':
      case 'custom_question':
      case 'timeline':
        return const Color(0xFFFF1493); // Rosa FURI
      case 'trivia':
        return const Color(0xFFFFDE59); // Amarillo
      case 'music':
        return const Color(0xFF00F0FF); // Cian
      case 'workout_log':
      case 'workout_completion':
      case 'workout_challenge':
      case 'ejercicios':
        return const Color(0xFF39FF14); // Verde lima
      case 'schedule':
      case 'class_schedule':
      case 'anniversary':
        return const Color(0xFFFF6B00); // Naranja
      case 'goal':
      case 'challenge':
        return const Color(0xFF10B981); // Esmeralda
      case 'favorite':
        return const Color(0xFFFF2A6D); // Coral
      case 'mapa':
        return const Color(0xFF3B82F6); // Azul
      default:
        return const Color(0xFF00F0FF); // Cian default
    }
  }

  IconData _categoryIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'letter':
      case 'mood':
        return Icons.favorite_rounded;
      case 'trivia':
        return Icons.quiz_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'workout_log':
      case 'workout_completion':
      case 'ejercicios':
        return Icons.fitness_center_rounded;
      case 'schedule':
      case 'class_schedule':
      case 'anniversary':
        return Icons.calendar_month_rounded;
      case 'goal':
      case 'challenge':
        return Icons.emoji_events_rounded;
      case 'mapa':
        return Icons.location_on_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  String _categoryLabel(String type) {
    switch (type) {
      case 'message':
        return 'MENSAJE';
      case 'letter':
        return 'CARTA';
      case 'mood':
        return 'ESTADO';
      case 'trivia':
        return 'TRIVIA';
      case 'music':
        return 'MÚSICA';
      case 'ejercicios':
      case 'workout_log':
        return 'EJERCICIOS';
      case 'schedule':
      case 'class_schedule':
        return 'CALENDARIO';
      case 'goal':
        return 'META';
      case 'challenge':
        return 'RETO';
      default:
        return 'F.U.R.I';
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;
    final bottomPadding = media.padding.bottom;

    return Consumer<MusicPlayerProvider>(
      builder: (context, musicPv, _) {
        final currentTrack = musicPv.currentTrack;
        final trackId = currentTrack?.id ?? currentTrack?.cloudId;

        // Si cambió la canción que suena, restauramos la visibilidad de la botonera
        if (trackId != _lastTrackId && trackId != null) {
          _lastTrackId = trackId;
          _musicBarDismissed = false;
        }

        // Control del giro del disco
        if (musicPv.isPlaying) {
          if (!_vinylAnimCtrl.isAnimating) {
            _vinylAnimCtrl.repeat();
          }
        } else {
          if (_vinylAnimCtrl.isAnimating) {
            _vinylAnimCtrl.stop();
          }
        }

        // Verificamos si la ruta activa es la pantalla completa de música
        bool isMusicScreenActive = false;
        try {
          final uri = appRouter.routerDelegate.currentConfiguration.uri.path;
          isMusicScreenActive = uri.startsWith(RouterRoutes.music);
        } catch (_) {}

        final showMusicBar = currentTrack != null &&
            !_musicBarDismissed &&
            !isMusicScreenActive;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Pantalla activa de la app
            widget.child,

            // 1. Notificación In-App Flotante Personalizada (Estilo WhatsApp con identidad F.U.R.I)
            if (_currentNotif != null)
              Positioned(
                top: topPadding + 10,
                left: 14,
                right: 14,
                child: SlideTransition(
                  position: _notifSlideAnim,
                  child: FadeTransition(
                    opacity: _notifFadeAnim,
                    child: _buildInAppNotificationBanner(_currentNotif!),
                  ),
                ),
              ),

            // 2. Botonera Flotante del Reproductor de Música (Estilo Spotify / YouTube Music con identidad F.U.R.I)
            if (showMusicBar)
              Positioned(
                bottom: bottomPadding + 10,
                left: 14,
                right: 14,
                child: _buildFloatingMusicBar(musicPv),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInAppNotificationBanner(InAppNotificationItem item) {
    final type = (item.data['type'] as String?) ?? '';
    final color = _categoryColor(type);
    final isDarkIcon = color == const Color(0xFFFFDE59) ||
        color == const Color(0xFF39FF14) ||
        color == const Color(0xFF00F0FF);
    final iconColor = isDarkIcon ? const Color(0xFF121212) : Colors.white;

    return Dismissible(
      key: ValueKey('in_app_notif_${item.timestamp.millisecondsSinceEpoch}'),
      direction: DismissDirection.up,
      onDismissed: (_) => _dismissNotification(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onNotificationTap(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), // Bloque sólido sin bordes (skill_visual.md)
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Icono temático de categoría
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _categoryIcon(type),
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Contenido textual
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _categoryLabel(type),
                              style: GoogleFonts.bangers(
                                fontSize: 10,
                                color: iconColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Botón de cierre rápido
                GestureDetector(
                  onTap: _dismissNotification,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingMusicBar(MusicPlayerProvider musicPv) {
    final track = musicPv.currentTrack!;
    final progress = musicPv.duration.inMilliseconds > 0
        ? (musicPv.position.inMilliseconds / musicPv.duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Bloque sólido sin bordes (skill_visual.md)
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Vinilo giratorio animado / Cover
                  GestureDetector(
                    onTap: () => appRouter.push(RouterRoutes.music),
                    child: RotationTransition(
                      turns: _vinylAnimCtrl,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF282828),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00F0FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.music_note,
                                size: 10,
                                color: Color(0xFF121212),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Título y Artista (tocar abre el reproductor)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => appRouter.push(RouterRoutes.music),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: GoogleFonts.bangers(
                              fontSize: 15,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            track.artist.isNotEmpty ? track.artist : 'F.U.R.I Música',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botonera de control (Anterior, Play/Pausa, Siguiente, Cerrar)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón Anterior
                      GestureDetector(
                        onTap: musicPv.playPrevious,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C2C2C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.skip_previous_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Botón Play / Pausa (destacado en cian sólido)
                      GestureDetector(
                        onTap: musicPv.togglePlayPause,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00F0FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            musicPv.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 24,
                            color: const Color(0xFF121212),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Botón Siguiente
                      GestureDetector(
                        onTap: musicPv.playNext,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C2C2C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.skip_next_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botón Minimizar / Cerrar barra flotante
                      GestureDetector(
                        onTap: () {
                          setState(() => _musicBarDismissed = true);
                        },
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: Color(0xFF262626),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Barra de progreso delgada al pie de la botonera
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFF282828),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  color: const Color(0xFF00F0FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
