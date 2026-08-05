import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/message.dart';

enum GroupPos { solo, first, middle, last }

class DateDividerPill extends StatelessWidget {
  final String label;
  final ThemeSet t;
  const DateDividerPill({super.key, required this.label, required this.t});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: t.dark,
            border: Border.all(color: t.light.withValues(alpha: 0.15), width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(
              fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold,
              color: t.light.withValues(alpha: 0.6))),
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final GroupPos groupPos;
  final ThemeSet theme;
  final String partnerName;
  final VoidCallback onReply;
  final void Function(String emoji) onReact;
  final VoidCallback onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.groupPos,
    required this.theme,
    required this.partnerName,
    required this.onReply,
    required this.onReact,
    required this.onLongPress,
  });

  bool get isFirst => groupPos == GroupPos.first || groupPos == GroupPos.solo;
  bool get showAvatar => groupPos == GroupPos.last || groupPos == GroupPos.solo;

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt != null
        ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
        : '';
    return Padding(
      padding: EdgeInsets.only(
        top: groupPos == GroupPos.first || groupPos == GroupPos.solo ? 4 : 1,
        bottom: showAvatar ? 6 : 1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: isMine ? TextDirection.rtl : TextDirection.ltr,
        children: [
          if (!isMine && showAvatar)
            Padding(padding: const EdgeInsets.only(right: 6),
              child: CircleAvatar(radius: 14, backgroundColor: theme.b,
                child: Text(partnerName.isNotEmpty ? partnerName[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.dark, fontFamily: 'monospace')),
              ),
            )
          else const SizedBox(width: 34),
          Flexible(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  child: ClipPath(
                    clipper: BubbleClipper(isMine: isMine, isFirst: isFirst),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                      decoration: BoxDecoration(
                        color: isMine ? theme.a : theme.mid,
                        border: Border.all(color: isMine ? theme.dark : theme.light.withValues(alpha: 0.15), width: isMine ? 3 : 1),
                        borderRadius: isFirst
                            ? BorderRadius.only(
                                topLeft: Radius.circular(isMine ? 16 : 4),
                                topRight: Radius.circular(isMine ? 4 : 16),
                                bottomLeft: const Radius.circular(16),
                                bottomRight: const Radius.circular(16),
                              )
                            : BorderRadius.only(
                                topLeft: const Radius.circular(4), topRight: const Radius.circular(4),
                                bottomLeft: const Radius.circular(16), bottomRight: const Radius.circular(16),
                              ),
                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.replyToId != null && message.replyContent != null && message.replyContent!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(bottom: 4),
                              decoration: BoxDecoration(
                                color: (isMine ? theme.dark : theme.dark).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                                border: Border(left: BorderSide(color: theme.c, width: 3)),
                              ),
                              child: Text(message.replyContent!, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: (isMine ? theme.dark : theme.light).withValues(alpha: 0.7), fontFamily: 'monospace')),
                            ),
                          Text(message.content, style: TextStyle(
                              fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 14,
                              color: isMine ? theme.dark : theme.light)),
                          const SizedBox(height: 2),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(time, style: TextStyle(fontSize: 10, fontFamily: 'monospace',
                                color: (isMine ? theme.dark : theme.light).withValues(alpha: 0.6))),
                            if (isMine) ...[
                              const SizedBox(width: 4),
                              Icon(message.read ? Icons.done_all : Icons.done, size: 14,
                                color: message.read ? theme.c : (isMine ? theme.dark : theme.light).withValues(alpha: 0.5)),
                            ],
                            if (message.edited) ...[
                              const SizedBox(width: 4),
                              Text('editado', style: TextStyle(fontSize: 9, fontFamily: 'monospace',
                                  color: (isMine ? theme.dark : theme.light).withValues(alpha: 0.5))),
                            ],
                            if (message.starred) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.star, size: 12, color: theme.d),
                            ],
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isFirst && isMine)
                  Positioned(top: 6, right: -2, child: CustomPaint(
                    size: const Size(10, 10),
                    painter: TailPainter(color: isMine ? theme.a : theme.mid, isMine: isMine,
                        borderColor: isMine ? theme.dark : theme.light.withValues(alpha: 0.15)),
                  )),
                if (isFirst && !isMine)
                  Positioned(top: 6, left: -2, child: CustomPaint(
                    size: const Size(10, 10),
                    painter: TailPainter(color: isMine ? theme.a : theme.mid, isMine: isMine,
                        borderColor: isMine ? theme.dark : theme.light.withValues(alpha: 0.15)),
                  )),
              ],
            ),
          ),
          if (isMine && showAvatar)
            Padding(padding: const EdgeInsets.only(left: 6),
              child: CircleAvatar(radius: 14, backgroundColor: theme.a,
                child: Text('T', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.dark, fontFamily: 'monospace')),
              ),
            )
          else const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class BubbleClipper extends CustomClipper<Path> {
  final bool isMine;
  final bool isFirst;
  BubbleClipper({required this.isMine, required this.isFirst});

  @override
  Path getClip(Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      isFirst ? const Radius.circular(16) : const Radius.circular(4),
    ));
    return path;
  }

  @override
  bool shouldReclip(covariant BubbleClipper old) =>
      old.isMine != isMine || old.isFirst != isFirst;
}

class TailPainter extends CustomPainter {
  final Color color;
  final bool isMine;
  final Color borderColor;

  TailPainter({required this.color, required this.isMine, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = isMine ? 3 : 1;
    final path = Path();
    if (isMine) {
      path.moveTo(0, 0); path.lineTo(size.width, 0); path.lineTo(size.width, size.height * 0.8);
    } else {
      path.moveTo(size.width, 0); path.lineTo(0, 0); path.lineTo(0, size.height * 0.8);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant TailPainter old) =>
      old.color != color || old.isMine != isMine;
}
