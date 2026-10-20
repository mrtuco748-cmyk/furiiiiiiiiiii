import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/tap_tile.dart';
import '../models/home_shortcut_models.dart';

class ShortcutPanel extends StatelessWidget {
  final ThemeSet theme;
  final List<String> userShortcuts;
  final ValueChanged<String> onAction;
  final VoidCallback onManageShortcuts;

  const ShortcutPanel({
    super.key,
    required this.theme,
    required this.userShortcuts,
    required this.onAction,
    required this.onManageShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final activeDefs = <ShortcutDef>[];
    for (final action in userShortcuts) {
      final def = homeShortcuts.firstWhere(
        (s) => s.action == action,
        orElse: () => const ShortcutDef('', Icons.help_outline, ''),
      );
      if (def.action.isNotEmpty) {
        activeDefs.add(def);
      }
    }

    return Material(
      color: const Color(0xFF101010),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(height: 1, color: t.d),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Icon(Icons.stars_rounded, color: t.b, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'ATAJOS',
                      style: GoogleFonts.bangers(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: activeDefs.isEmpty
                    ? Center(
                        child: TapTile(
                          onTap: onManageShortcuts,
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: t.b,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_rounded, color: Colors.white, size: 44),
                                const SizedBox(height: 6),
                                Text(
                                  'ATAJOS',
                                  style: GoogleFonts.bangers(
                                    color: Colors.white,
                                    fontSize: 14,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : GridView.count(
                        crossAxisCount: 3,
                        padding: const EdgeInsets.all(12),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        children: [
                          for (var i = 0; i < activeDefs.length; i++)
                            ShortcutTile(
                              icon: activeDefs[i].icon,
                              label: activeDefs[i].label,
                              color: shortcutColor(t, i),
                              onTap: () => onAction(activeDefs[i].action),
                            ),
                          TapTile(
                            onTap: onManageShortcuts,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF242424),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, color: t.b, size: 30),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ATAJOS',
                                    style: GoogleFonts.bangers(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ShortcutTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapTile(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFFFFFFF), size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.bangers(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
