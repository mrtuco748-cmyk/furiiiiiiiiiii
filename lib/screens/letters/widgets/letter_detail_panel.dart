import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../widgets/brutal_style.dart';
import '../../../widgets/loca_screen.dart';
import 'letter_dialogs.dart';

const _cInbox = Color(0xFFFF1493);
const _cSealed = Color(0xFFFFB300);
const _mid = Color(0xFF2A2A2A);

const _letterPalette = [
  Color(0xFFFF6B00), // naranja
  Color(0xFF00D4FF), // cian
  Color(0xFF9D00FF), // violeta
  Color(0xFFFF1493), // rosa
  Color(0xFFFFDE59), // amarillo
  Color(0xFFFF00FF), // fucsia
  Color(0xFF7000FF), // morado
  Color(0xFFFF5757), // rojo
];

class LetterDetailPanel extends StatefulWidget {
  final VoidCallback close;
  final Map<String, dynamic> letter;
  final bool isSealed;
  final DateTime? openAt;
  final VoidCallback? onOpened;

  const LetterDetailPanel({
    super.key,
    required this.close,
    required this.letter,
    required this.isSealed,
    this.openAt,
    this.onOpened,
  });

  static IconData iconFor({required bool isSealed, required bool isRead}) {
    if (isSealed) return Icons.mail_lock;
    return isRead ? Icons.mark_email_read : Icons.markunread;
  }

  static Color colorFor({required int index, required bool isSealed}) {
    if (isSealed) return _cSealed;
    return _letterPalette[index % _letterPalette.length];
  }

  static Color iconColorFor({required bool isSealed}) {
    if (isSealed) return Colors.black;
    return Colors.white;
  }

  @override
  State<LetterDetailPanel> createState() => _LetterDetailPanelState();
}

class _LetterDetailPanelState extends State<LetterDetailPanel> {
  @override
  void initState() {
    super.initState();
    if (!widget.isSealed && widget.onOpened != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onOpened!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.letter['title']?.toString() ?? '';
    final body = widget.letter['content']?.toString() ?? '';
    final date = widget.letter['created_at']?.toString() ?? '';
    final color = widget.isSealed ? _cSealed : _cInbox;

    return LocaScreen.panel(
      color: _mid,
      borderColor: color,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
            child: Row(
              children: [
                Icon(
                  widget.isSealed ? Icons.mail_lock : Icons.mark_email_read,
                  color: color,
                  size: 22,
                ),
                const Spacer(),
                LocaScreen.closeIcon(widget.close, color, Icons.close),
              ],
            ),
          ),
          Expanded(
            child: widget.isSealed
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mail_lock,
                              color: _cSealed, size: 56),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.bangers(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (widget.openAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Se podrá abrir el ${widget.openAt!.day}/${widget.openAt!.month}/${widget.openAt!.year}',
                              style: GoogleFonts.bangers(
                                color: _cSealed,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.bangers(
                                color: color,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              body,
                              style: GoogleFonts.bangers(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              LetterDialogs.formatDate(date),
                              style: GoogleFonts.bangers(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class LetterMosaicChild extends StatelessWidget {
  final Map<String, dynamic> letter;
  final IconData icon;
  final Color iconColor;
  final bool isSealed;

  const LetterMosaicChild({
    super.key,
    required this.letter,
    required this.icon,
    required this.iconColor,
    required this.isSealed,
  });

  @override
  Widget build(BuildContext context) {
    final title = letter['title']?.toString() ?? '';
    final body = letter['content']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(child: BrutalStyle.fillIcon(icon, iconColor)),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.bangers(
              color: iconColor,
              fontSize: 21,
              height: 1.1,
            ),
          ),
          if (!isSealed && body.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              body.length > 40 ? '${body.substring(0, 40)}…' : body,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.bangers(
                color: Colors.white,
                fontSize: 11,
                height: 1.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
