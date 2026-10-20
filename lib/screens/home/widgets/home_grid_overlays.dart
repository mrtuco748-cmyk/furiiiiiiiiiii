import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../models/deck_card.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/rewards_provider.dart';
import '../../../theme/app_theme.dart';
import '../../mazo/deck_match_overlay.dart';
import '../../mazo/deck_overlay.dart';
import '../helpers/home_drawer_drag_handler.dart';
import 'home_grid_tiles.dart';
import 'home_notification_panel.dart';
import 'home_shortcut_panel.dart';
import 'home_sliding_drawer.dart';

class HomeGridOverlays extends StatelessWidget {
  final ThemeSet theme;
  final double drawerHeight;
  final double drawerWidth;
  final double c1;
  final double screenWidth;
  final double screenHeight;
  final HomeDrawerDragHandler drawerHandler;
  final List<String> userShortcuts;
  final ValueChanged<String> onShortcutAction;
  final VoidCallback onManageShortcuts;
  final bool showDeck;
  final bool showPoemas;
  final VoidCallback onCloseDeck;
  final VoidCallback onClosePoemas;

  const HomeGridOverlays({
    super.key,
    required this.theme,
    required this.drawerHeight,
    required this.drawerWidth,
    required this.c1,
    required this.screenWidth,
    required this.screenHeight,
    required this.drawerHandler,
    required this.userShortcuts,
    required this.onShortcutAction,
    required this.onManageShortcuts,
    required this.showDeck,
    required this.showPoemas,
    required this.onCloseDeck,
    required this.onClosePoemas,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Stack(
      children: [
        if (!showDeck && !showPoemas) ...[
          xFloating(screenWidth, screenHeight),
          HomeBottomSlidingDrawer(
            controller: drawerHandler.shortcutCtrl,
            theme: t,
            panelHeight: drawerHeight,
            panelWidth: drawerWidth,
            c1: c1,
            onClose: drawerHandler.closeShortcutPanel,
            onDragStart: drawerHandler.handleShortcutDragStart,
            onDragUpdate: (d) => drawerHandler.handleShortcutDragUpdate(d, drawerWidth),
            onDragEnd: drawerHandler.handleShortcutDragEnd,
            child: ShortcutPanel(
              theme: t,
              userShortcuts: userShortcuts,
              onAction: onShortcutAction,
              onManageShortcuts: onManageShortcuts,
            ),
          ),
          HomeTopSlidingDrawer(
            controller: drawerHandler.notifCtrl,
            theme: t,
            panelHeight: drawerHeight,
            panelWidth: drawerWidth,
            c1: c1,
            onClose: drawerHandler.closeNotificationDrawer,
            onDragStart: drawerHandler.handleNotifDragStart,
            onDragUpdate: (d) => drawerHandler.handleNotifDragUpdate(d, drawerWidth),
            onDragEnd: drawerHandler.handleNotifDragEnd,
            child: NotificationPanel(key: drawerHandler.notifPanelKey, theme: t),
          ),
        ],
        if (showDeck)
          Positioned.fill(
            child: DeckOverlay(onClose: onCloseDeck),
          ),
        if (showPoemas)
          Positioned.fill(
            child: DeckOverlay(
              category: DeckCategory.poemas,
              onClose: onClosePoemas,
            ),
          ),
        Consumer<DeckProvider>(
          builder: (context, deckPv, _) {
            final match = deckPv.pendingMatch;
            if (match == null) return const SizedBox.shrink();
            return Positioned.fill(
              child: DeckMatchOverlay(
                card: match,
                onDone: () {
                  final rw = context.read<RewardsProvider>();
                  final cid = match.id;
                  if (cid != null) {
                    rw.awardOnce(AppState.myId ?? '', 'match-$cid', 5);
                    final partner = AppState.partnerId;
                    if (partner != null) rw.awardOnce(partner, 'match-$cid', 5);
                  }
                  deckPv.consumeMatch();
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
