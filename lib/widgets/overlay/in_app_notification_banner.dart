import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/notification_service.dart';

class InAppNotificationBanner extends StatelessWidget {
  final InAppNotificationItem item;
  final VoidCallback onDismiss;
  final ValueChanged<InAppNotificationItem> onTap;

  const InAppNotificationBanner({
    super.key,
    required this.item,
    required this.onDismiss,
    required this.onTap,
  });

  static Color categoryColor(String type) {
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

  static IconData categoryIcon(String type) {
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

  static String categoryLabel(String type) {
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
    final type = (item.data['type'] as String?) ?? '';
    final color = categoryColor(type);
    final isDarkIcon = color == const Color(0xFFFFDE59) ||
        color == const Color(0xFF39FF14) ||
        color == const Color(0xFF00F0FF);
    final iconColor = isDarkIcon ? const Color(0xFF121212) : Colors.white;

    return Dismissible(
      key: ValueKey('in_app_notif_${item.timestamp.millisecondsSinceEpoch}'),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon(type),
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
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
                              categoryLabel(type),
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
                GestureDetector(
                  onTap: onDismiss,
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
}
