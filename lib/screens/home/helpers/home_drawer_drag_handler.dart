import 'package:flutter/material.dart';
import '../widgets/home_notification_panel.dart';

class HomeDrawerDragHandler {
  final AnimationController notifCtrl;
  final AnimationController shortcutCtrl;
  final GlobalKey<NotificationPanelState> notifPanelKey;
  final VoidCallback onStateChanged;

  HomeDrawerDragHandler({
    required this.notifCtrl,
    required this.shortcutCtrl,
    required this.notifPanelKey,
    required this.onStateChanged,
  });

  void openNotificationDrawer() {
    if (shortcutCtrl.value > 0) closeShortcutPanel();
    notifCtrl.animateTo(1.0, curve: Curves.easeOutCubic).then((_) {
      onStateChanged();
    });
    Future.delayed(const Duration(milliseconds: 320), () => notifPanelKey.currentState?.refresh());
  }

  void closeNotificationDrawer() {
    notifCtrl.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
      onStateChanged();
    });
  }

  void openShortcutPanel() {
    if (notifCtrl.value > 0) closeNotificationDrawer();
    shortcutCtrl.animateTo(1.0, curve: Curves.easeOutCubic).then((_) {
      onStateChanged();
    });
  }

  void closeShortcutPanel() {
    shortcutCtrl.animateTo(0.0, curve: Curves.easeOutCubic).then((_) {
      onStateChanged();
    });
  }

  void handleNotifDragStart(DragStartDetails details) {
    notifCtrl.stop();
    if (shortcutCtrl.value > 0) closeShortcutPanel();
  }

  void handleNotifDragUpdate(DragUpdateDetails details, double panelWidth) {
    final delta = details.primaryDelta ?? 0;
    notifCtrl.value = (notifCtrl.value + delta / panelWidth).clamp(0.0, 1.0);
  }

  void handleNotifDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 280 || (velocity >= -280 && notifCtrl.value >= 0.35)) {
      openNotificationDrawer();
    } else {
      closeNotificationDrawer();
    }
  }

  void handleShortcutDragStart(DragStartDetails details) {
    shortcutCtrl.stop();
    if (notifCtrl.value > 0) closeNotificationDrawer();
  }

  void handleShortcutDragUpdate(DragUpdateDetails details, double panelWidth) {
    final delta = details.primaryDelta ?? 0;
    shortcutCtrl.value = (shortcutCtrl.value + delta / panelWidth).clamp(0.0, 1.0);
  }

  void handleShortcutDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 280 || (velocity >= -280 && shortcutCtrl.value >= 0.35)) {
      openShortcutPanel();
    } else {
      closeShortcutPanel();
    }
  }
}
