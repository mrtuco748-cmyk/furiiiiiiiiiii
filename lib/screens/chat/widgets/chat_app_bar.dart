import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app_state.dart';
import '../../../providers/chat_provider.dart';
import '../../../theme/app_theme.dart';
import '../chat_style.dart';
import 'chat_profile_dialog.dart';

/// AppBar para la pantalla de chat con foto, presencia y estado escribiendo
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatProvider chat;
  final ThemeSet theme;
  final VoidCallback onProfileTap;
  final VoidCallback onCameraTap;
  final VoidCallback onReloadTap;

  const ChatAppBar({
    super.key,
    required this.chat,
    required this.theme,
    required this.onProfileTap,
    required this.onCameraTap,
    required this.onReloadTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final partnerName = chat.partnerName.isNotEmpty
        ? chat.partnerName
        : (AppState.partnerName.isNotEmpty ? AppState.partnerName : 'Pareja');
    final initial = partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'P';
    final partnerAvatar = chat.partnerAvatarUrl;

    return AppBar(
      backgroundColor: ChatStyle.appbarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 44,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        onPressed: () => Navigator.of(context).maybePop(),
        padding: const EdgeInsets.only(left: 6),
      ),
      titleSpacing: 0,
      title: InkWell(
        onTap: onProfileTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: t.a,
                    backgroundImage: getAvatarImageProvider(partnerAvatar),
                    child: (partnerAvatar == null || partnerAvatar.isEmpty)
                        ? Text(
                            initial,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: t.dark,
                            ),
                          )
                        : null,
                  ),
                  if (chat.isPartnerOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1E1E1E),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      partnerName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    if (chat.partnerTyping)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF25D366),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'escribiendo...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF25D366),
                            ),
                          ),
                        ],
                      )
                    else if (chat.isPartnerOnline)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'en línea',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF25D366),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        chat.partnerStatusText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ChatStyle.subText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 22),
          tooltip: 'Cambiar mi foto de perfil',
          onPressed: onCameraTap,
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white70, size: 22),
          tooltip: 'Recargar mensajes',
          onPressed: onReloadTap,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
