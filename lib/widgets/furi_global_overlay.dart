import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/music_player_provider.dart';
import '../router.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import 'overlay/floating_music_bar.dart';
import 'overlay/in_app_notification_banner.dart';

/// Overlay global de F.U.R.I.
/// Provee:
/// 1. Notificaciones flotantes in-app con estilo propio de la app.
/// 2. Botonera flotante del reproductor de música con controles.
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

    _vinylAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _notifSub = NotificationService.inAppNotificationStream
        .listen(_showInAppNotification);
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;
    final bottomPadding = media.padding.bottom;

    return Consumer<MusicPlayerProvider>(
      builder: (context, musicPv, _) {
        final currentTrack = musicPv.currentTrack;
        final trackId = currentTrack?.id ?? currentTrack?.cloudId;

        if (trackId != _lastTrackId && trackId != null) {
          _lastTrackId = trackId;
          _musicBarDismissed = false;
        }

        if (musicPv.isPlaying) {
          if (!_vinylAnimCtrl.isAnimating) {
            _vinylAnimCtrl.repeat();
          }
        } else {
          if (_vinylAnimCtrl.isAnimating) {
            _vinylAnimCtrl.stop();
          }
        }

        bool isMusicScreenActive = musicPv.isMusicScreenOpen;
        try {
          final uri = appRouter.routerDelegate.currentConfiguration.uri.path;
          if (uri.startsWith(RouterRoutes.music)) {
            isMusicScreenActive = true;
          }
        } catch (_) {}

        final showMusicBar = currentTrack != null &&
            !_musicBarDismissed &&
            !isMusicScreenActive;

        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (_currentNotif != null)
              Positioned(
                top: topPadding + 10,
                left: 14,
                right: 14,
                child: SlideTransition(
                  position: _notifSlideAnim,
                  child: FadeTransition(
                    opacity: _notifFadeAnim,
                    child: InAppNotificationBanner(
                      item: _currentNotif!,
                      onDismiss: _dismissNotification,
                      onTap: _onNotificationTap,
                    ),
                  ),
                ),
              ),
            if (showMusicBar)
              Positioned(
                bottom: bottomPadding + 10,
                left: 14,
                right: 14,
                child: FloatingMusicBar(
                  musicPv: musicPv,
                  vinylTurns: _vinylAnimCtrl,
                  onDismiss: () => setState(() => _musicBarDismissed = true),
                  onOpenMusicScreen: () => appRouter.push(RouterRoutes.music),
                ),
              ),
          ],
        );
      },
    );
  }
}
