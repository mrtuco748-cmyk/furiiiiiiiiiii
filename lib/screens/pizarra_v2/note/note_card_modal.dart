import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/board_provider_v2.dart';
import '../../../models/board_element_v2.dart';
import '../../../app_state.dart';
import 'note_toolbar.dart';
import 'note_audio_recorder.dart';

String _hexColor(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

class NoteCardModal extends StatefulWidget {
  final VoidCallback onClose;
  final int? noteId;
  final double initialX;
  final double initialY;

  const NoteCardModal({
    super.key,
    required this.onClose,
    this.noteId,
    this.initialX = 200,
    this.initialY = 200,
  });

  @override
  State<NoteCardModal> createState() => _NoteCardModalState();
}

class _NoteCardModalState extends State<NoteCardModal> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  String _shape = 'Rectángulo';
  Color _noteColor = const Color(0xFF5C2D91);
  final List<Color> _lastCustomColors = [];

  String? _imagePath;
  String _imagePosition = 'top';
  String? _audioPath;

  final Map<String, dynamic> _bgState = {
    'gradientType': 'Liso',
    'gradientStart': const Color(0xFF5C2D91),
    'gradientMid': const Color(0xFF3A7BD5),
    'gradientEnd': const Color(0xFF00D4FF),
    'bgImagePath': null,
    'selectedPattern': 'Puntos',
    'patternEnabled': false,
    'customPattern': null,
    'patternThickness': 1.5,
    'patternAngle': 0.0,
    'patternSize': 40.0,
    'patternOpacity': 0.25,
    'patternSpacing': 24.0,
    'patternSaturation': 1.0,
  };
  final Map<String, dynamic> _fontState = {
    'fontFamily': 'Roboto',
    'fontColor': Colors.white,
    'fontSize': 14.0,
  };
  final Map<String, dynamic> _borderState = {
    'borderEnabled': false,
    'borderColor': const Color(0xFF39FF14),
    'borderType': 'Sólido',
    'borderWidth': 2.0,
    'borderSpacing': 4.0,
  };

  void _handleBgChanged(String key, dynamic value) {
    setState(() => _bgState[key] = value);
  }

  void _handleFontChanged(String key, dynamic value) {
    setState(() => _fontState[key] = value);
  }

  void _handleBorderChanged(String key, dynamic value) {
    setState(() => _borderState[key] = value);
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    if (widget.noteId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    }
  }

  void _loadExisting() {
    final pv = context.read<BoardProviderV2>();
    final el = pv.elements.where((e) => e.id == widget.noteId).firstOrNull;
    if (el == null) return;
    setState(() {
      _titleCtrl.text = el.title;
      _bodyCtrl.text = el.content;
      if (el.color != null) {
        _noteColor = parseColor(el.color!) ?? _noteColor;
      }
      if (el.textColor != null) {
        _fontState['fontColor'] = parseColor(el.textColor!) ?? _fontState['fontColor'];
      }
      if (el.fontFamily != null) {
        _fontState['fontFamily'] = el.fontFamily;
      }
      if (el.fontSize != null) {
        _fontState['fontSize'] = el.fontSize;
      }
      final data = el.data;
      if (data['shape'] is String) _shape = data['shape'];
      if (data['imagePath'] is String) _imagePath = data['imagePath'];
      if (data['imagePosition'] is String) _imagePosition = data['imagePosition'];
      if (data['audioPath'] is String) _audioPath = data['audioPath'];
      if (data['bgState'] is Map) _loadStateMap(_bgState, data['bgState']);
      if (data['fontState'] is Map) _loadStateMap(_fontState, data['fontState']);
      if (data['borderState'] is Map) _loadStateMap(_borderState, data['borderState']);
    });
  }

  void _loadStateMap(Map<String, dynamic> target, Map<dynamic, dynamic> source) {
    for (final e in source.entries) {
      final key = e.key.toString();
      if (source[key] is int) {
        target[key] = Color(source[key] as int);
      } else {
        target[key] = source[key];
      }
    }
  }

  static Color? parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      final v = int.tryParse('FF$cleaned', radix: 16);
      return v != null ? Color(v) : null;
    }
    if (cleaned.length == 8) {
      final v = int.tryParse(cleaned, radix: 16);
      return v != null ? Color(v) : null;
    }
    return null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (xFile == null) return;
    setState(() => _imagePath = xFile.path);
    _showPositionSelector();
  }

  void _showPositionSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A0A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Posición de la imagen',
              style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14)),
            const SizedBox(height: 16),
            _posOption('Arriba del título', 'top'),
            _posOption('En el medio', 'middle'),
            _posOption('Abajo del cuerpo', 'bottom'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () { setState(() => _imagePath = null); Navigator.of(ctx).pop(); },
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: const Color(0xFFFF5757), borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF5757), width: 1.5)),
                child: const Center(
                  child: Text('Quitar imagen', style: TextStyle(color: Color(0xFF0A0A0A),
                    fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posOption(String label, String value) {
    final selected = _imagePosition == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () { setState(() => _imagePosition = value); Navigator.of(context).pop(); },
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF39FF14) : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? const Color(0xFF39FF14) : const Color(0xFF1A1A1A), width: 1.5),
          ),
          child: Text(label, style: TextStyle(color: selected ? const Color(0xFF0A0A0A) : Colors.white70,
            fontFamily: 'monospace', fontSize: 13)),
        ),
      ),
    );
  }

  void _save() {
    final provider = context.read<BoardProviderV2>();
    final data = {
      'shape': _shape,
      'imagePath': _imagePath,
      'imagePosition': _imagePosition,
      'audioPath': _audioPath,
      'lastCustomColors': _lastCustomColors.map((c) => c.toARGB32()).toList(),
      'bgState': _toSerializable(_bgState),
      'fontState': _toSerializable(_fontState),
      'borderState': _toSerializable(_borderState),
    };

    if (widget.noteId != null) {
      final el = provider.elements.where((e) => e.id == widget.noteId).firstOrNull;
      if (el != null) {
        provider.update(el.copyWith(
          title: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Sin título',
          content: _bodyCtrl.text,
          color: _hexColor(_noteColor),
          fontFamily: _fontState['fontFamily'] as String?,
          textColor: _hexColor((_fontState['fontColor'] as Color?) ?? Colors.white),
          fontSize: (_fontState['fontSize'] as double?) ?? 14,
          data: data,
        ));
      }
    } else {
      provider.add(BoardElementV2(
        type: BoardElementType.note,
        title: _titleCtrl.text.isNotEmpty ? _titleCtrl.text : 'Sin título',
        content: _bodyCtrl.text,
        x: widget.initialX, y: widget.initialY,
        color: _hexColor(_noteColor),
        userId: AppState.myId,
        isNew: true,
        fontFamily: _fontState['fontFamily'] as String?,
        textColor: _hexColor((_fontState['fontColor'] as Color?) ?? Colors.white),
        fontSize: (_fontState['fontSize'] as double?) ?? 14,
        data: data,
      ));
    }
    HapticFeedback.heavyImpact();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final cardW = (screenW * 0.65).clamp(280.0, 420.0);

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: cardW, child: _buildCard()),
                const SizedBox(width: 12),
                NoteToolbar(
                  currentShape: _shape,
                  currentColor: _noteColor,
                  lastCustomColors: _lastCustomColors,
                  onShapeChanged: (s) => setState(() => _shape = s),
                  onColorChanged: (c) => setState(() => _noteColor = c),
                  onCustomColorsChanged: (colors) {
                    setState(() { _lastCustomColors..clear()..addAll(colors); });
                  },
                  bgState: _bgState,
                  onBgChanged: _handleBgChanged,
                  fontState: _fontState,
                  onFontChanged: _handleFontChanged,
                  borderState: _borderState,
                  onBorderChanged: _handleBorderChanged,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ▸▸▸ CARD with live shape, gradient, pattern, border, font ▸▸▸

  Widget _buildCard() {
    final borderOn = _borderState['borderEnabled'] == true;
    final borderColor = (_borderState['borderColor'] as Color?) ?? const Color(0xFF39FF14);
    final borderW = (_borderState['borderWidth'] as double?) ?? 2.0;
    final borderType = (_borderState['borderType'] as String?) ?? 'Slido';
    final sp = (_borderState['borderSpacing'] as double?) ?? 4.0;

    return ClipPath(
      clipper: _ShapeClipper(_shape, _shapeRadius()),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _buildBgDecoration(
              borderOn: false, borderColor: borderColor, borderW: borderW, borderType: borderType),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                if (_imagePath != null && _imagePosition == 'top') ...[_buildImagePreview(), const SizedBox(height: 10)],
                _buildTitleField(),
                const SizedBox(height: 8),
                if (_imagePath != null && _imagePosition == 'middle') ...[_buildImagePreview(), const SizedBox(height: 8)],
                _buildBodyField(),
                if (_imagePath != null && _imagePosition == 'bottom') ...[const SizedBox(height: 10), _buildImagePreview()],
                const SizedBox(height: 12),
                _buildBottomBar(),
              ],
            ),
          ),
          _buildPatternLayer(),
          if (borderOn)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CardBorderPainter(
                    color: borderColor,
                    width: borderW,
                    type: borderType.toLowerCase(),
                    spacing: sp,
                    shape: _shape,
                    radius: _shapeRadius(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPatternLayer() {
    final enabled = (_bgState['patternEnabled'] as bool?) ?? false;
    if (!enabled) return const SizedBox.shrink();
    final pat = (_bgState['selectedPattern'] as String?) ?? 'Puntos';
    final thick = (_bgState['patternThickness'] as double?) ?? 1.0;
    final angle = (_bgState['patternAngle'] as double?) ?? 0.0;
    final size = (_bgState['patternSize'] as double?) ?? 20.0;
    final opacity = (_bgState['patternOpacity'] as double?) ?? 0.25;
    final spacing = (_bgState['patternSpacing'] as double?) ?? 24.0;
    final saturation = (_bgState['patternSaturation'] as double?) ?? 1.0;
    final cust = _bgState['customPattern'] as String?;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _PatternPainter(
          pattern: pat,
          thickness: thick,
          angle: angle,
          dotSize: size,
          opacity: opacity,
          spacing: spacing,
          saturation: saturation,
          customText: cust,
        ),
      ),
    );
  }

  BoxDecoration _buildBgDecoration({bool borderOn = false, Color? borderColor, double borderW = 2, String borderType = 'Sólido'}) {
    final gradientType = (_bgState['gradientType'] as String?) ?? 'Liso';
    final boxBorder = borderOn ? _makeBorder(borderColor ?? _noteColor, borderW, borderType) : null;
    if (gradientType == 'Lineal') {
      final gs = (_bgState['gradientStart'] as Color?) ?? _noteColor;
      final gm = (_bgState['gradientMid'] as Color?) ?? _noteColor;
      final ge = (_bgState['gradientEnd'] as Color?) ?? _noteColor;
      return BoxDecoration(
        borderRadius: _shapeRadius(),
        border: boxBorder,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gs, gm, ge]),
      );
    }
    if (gradientType == 'Radial') {
      final gs = (_bgState['gradientStart'] as Color?) ?? _noteColor;
      final gm = (_bgState['gradientMid'] as Color?) ?? _noteColor;
      final ge = (_bgState['gradientEnd'] as Color?) ?? _noteColor;
      return BoxDecoration(
        borderRadius: _shapeRadius(),
        border: boxBorder,
        gradient: RadialGradient(center: Alignment.center, radius: 0.8, colors: [gs, gm, ge]),
      );
    }
    return BoxDecoration(
      color: _noteColor,
      borderRadius: _shapeRadius(),
      border: boxBorder,
    );
  }

  BorderRadius _shapeRadius() {
    switch (_shape) {
      case 'Círculo':
        return BorderRadius.circular(200);
      case 'Óvalo':
        return BorderRadius.circular(80);
      case 'Cuadrado':
        return BorderRadius.circular(4);
      default:
        return BorderRadius.circular(16);
    }
  }

  Widget _buildHeader() {
    final pv = context.read<BoardProviderV2>();
    return Row(children: [
      if (!pv.isOnline)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFFF5757),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'OFFLINE',
            style: TextStyle(
              color: Color(0xFF0A0A0A),
              fontFamily: 'monospace',
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      const Spacer(),
      GestureDetector(
        onTap: widget.onClose,
        child: Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.close, color: Colors.white, size: 16)),
      ),
    ]);
  }

  Widget _buildTitleField() {
    final fontColor = (_fontState['fontColor'] as Color?) ?? Colors.white;
    final fontFam = (_fontState['fontFamily'] as String?) ?? 'Roboto';
    return TextField(
      controller: _titleCtrl, maxLines: 1,
      style: GoogleFonts.getFont(fontFam,
        color: fontColor, fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'Título...',
        hintStyle: GoogleFonts.getFont(fontFam, color: fontColor.withValues(alpha: 0.35)),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), isDense: true,
      ),
    );
  }

  Widget _buildBodyField() {
    final fontColor = (_fontState['fontColor'] as Color?) ?? Colors.white;
    final fontFam = (_fontState['fontFamily'] as String?) ?? 'Roboto';
    final fontSize = (_fontState['fontSize'] as double?) ?? 14.0;
    return Flexible(
      child: TextField(
        controller: _bodyCtrl, maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
        style: GoogleFonts.getFont(fontFam, color: fontColor, fontSize: fontSize, height: 1.5),
        decoration: InputDecoration(
          hintText: 'Nota...',
          hintStyle: GoogleFonts.getFont(fontFam, color: fontColor.withValues(alpha: 0.35)),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), isDense: true,
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(File(_imagePath!), fit: BoxFit.cover, height: 120, width: double.infinity),
    );
  }

  Widget _buildBottomBar() {
    final textColor = _textColorForBg(_noteColor);
    return Row(children: [
      NoteAudioRecorder(existingPath: _audioPath, onAudioSaved: (path) => setState(() => _audioPath = path)),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: _pickImage,
        child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
          child: Icon(_imagePath != null ? Icons.image : Icons.add_photo_alternate, color: textColor, size: 18)),
      ),
      if (_imagePath != null)
        GestureDetector(
          onTap: _showPositionSelector,
          child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.arrow_drop_down, color: textColor, size: 18)),
        ),
      const Spacer(),
      GestureDetector(
        onTap: _save,
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF39FF14), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF39FF14), width: 2)),
          child: const Icon(Icons.check, color: Color(0xFF0A0A0A), size: 22)),
      ),
    ]);
  }

  Color _textColorForBg(Color bg) {
    final luminance = (0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b);
    return luminance > 0.55 ? const Color(0xFF0A0A0A) : Colors.white70;
  }

  BoxBorder _makeBorder(Color color, double width, String type) {
    return Border.all(color: color, width: width);
  }

  Map<String, dynamic> _toSerializable(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final e in map.entries) {
      if (e.value is Color) {
        result[e.key] = (e.value as Color).toARGB32();
      } else {
        result[e.key] = e.value;
      }
    }
    return result;
  }
}

// ▸▸▸ SHAPE CLIPPER ▸▸▸

class _ShapeClipper extends CustomClipper<Path> {
  final String shape;
  final BorderRadius radius;
  _ShapeClipper(this.shape, this.radius);

  @override
  Path getClip(Size size) {
    final r = size.width < size.height ? size.width / 2 : size.height / 2;
    switch (shape) {
      case 'Círculo':
      case 'Óvalo':
        return Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height));
      case 'Diamante':
        return Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
      case 'Hexágono':
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60 - 30) * math.pi / 180;
          final x = size.width / 2 + r * math.cos(angle);
          final y = size.height / 2 + r * math.sin(angle);
          if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
        }
        path.close();
        return path;
      default:
        return Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, radius.topLeft));
    }
  }

  @override
  bool shouldReclip(covariant _ShapeClipper old) =>
      old.shape != shape || old.radius != radius;
}

// ▸▸▸ PATTERN PAINTER ▸▸▸

class _PatternPainter extends CustomPainter {
  final String pattern;
  final double thickness;
  final double angle;
  final double dotSize;
  final double opacity;
  final double spacing;
  final double saturation;
  final String? customText;

  _PatternPainter({
    required this.pattern,
    this.thickness = 1.5,
    this.angle = 0,
    this.dotSize = 40,
    this.opacity = 0.25,
    this.spacing = 24,
    this.saturation = 1.0,
    this.customText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = Colors.white;
    final paint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke;

    final spacingUse = spacing > 0 ? spacing : dotSize;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angle * math.pi / 180);

    switch (pattern) {
      case 'Puntos': _drawDots(canvas, size, paint, spacingUse);
      case 'Líneas H': _drawHLines(canvas, size, paint, spacingUse);
      case 'Líneas V': _drawVLines(canvas, size, paint, spacingUse);
      case 'Cuadrícula': _drawHLines(canvas, size, paint, spacingUse); _drawVLines(canvas, size, paint, spacingUse);
      case 'Diagonales': _drawHLines(canvas, size, paint, spacingUse); _drawDiagonals(canvas, size, paint, spacingUse);
      case 'Zigzag': _drawZigzag(canvas, size, paint, spacingUse);
      case 'Diamantes': _drawDiamonds(canvas, size, paint, spacingUse);
      case 'Ondas': _drawWaves(canvas, size, paint, spacingUse);
      case 'Círculos': _drawCircles(canvas, size, paint, spacingUse);
      case 'Triángulos': _drawTriangles(canvas, size, paint, spacingUse);
      case 'Rayas': _drawHLines(canvas, size, paint, spacingUse * 2);
      case 'Panal': _drawHexagons(canvas, size, paint, spacingUse);
      default:
        if (customText != null && customText!.isNotEmpty) {
          _drawCustom(canvas, size, customText!, opacity);
        }
    }
    canvas.restore();
  }

  void _drawDots(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    final h = size.width + size.height;
    for (double x = -w / 2; x < w / 2; x += sp) {
      for (double y = -h / 2; y < h / 2; y += sp) {
        canvas.drawCircle(Offset(x, y), dotSize / 8, Paint()..color = paint.color..style = PaintingStyle.fill);
      }
    }
  }

  void _drawHLines(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    for (double y = -w / 2; y < w / 2; y += sp) {
      canvas.drawLine(Offset(-w / 2, y), Offset(w / 2, y), paint);
    }
  }

  void _drawVLines(Canvas canvas, Size size, Paint paint, double sp) {
    final h = size.width + size.height;
    for (double x = -h / 2; x < h / 2; x += sp) {
      canvas.drawLine(Offset(x, -h / 2), Offset(x, h / 2), paint);
    }
  }

  void _drawZigzag(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    for (double y = -w / 2; y < w / 2; y += sp * 2) {
      final path = Path();
      path.moveTo(-w / 2, y);
      for (double x = -w / 2; x < w / 2; x += sp) {
        final dy = (x / sp).floor().isEven ? sp / 2 : -sp / 2;
        path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawDiamonds(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    final fillPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    for (double x = -w / 2; x < w / 2; x += sp) {
      for (double y = -w / 2; y < w / 2; y += sp) {
        final path = Path()
          ..moveTo(x, y - dotSize / 4)
          ..lineTo(x + dotSize / 4, y)
          ..lineTo(x, y + dotSize / 4)
          ..lineTo(x - dotSize / 4, y)
          ..close();
        canvas.drawPath(path, fillPaint);
      }
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint paint, double sp) {
    final w = size.width + size.height;
    for (double y = -w / 2; y < w / 2; y += sp * 1.5) {
      final path = Path();
      path.moveTo(-w / 2, y);
      for (double x = -w / 2; x <= w / 2; x += 2) {
        path.lineTo(x, y + math.sin(x / sp) * sp / 3);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawCustom(Canvas canvas, Size size, String text, double op) {
    final baseColor = Colors.white;
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: baseColor.withValues(alpha: op), fontSize: dotSize)),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: size.width + size.height);
    final w = size.width + size.height;
    final h = size.width + size.height;
    for (double x = -w / 2; x < w / 2; x += spacing * 2) {
      for (double y = -h / 2; y < h / 2; y += spacing * 2) {
        tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
      }
    }
  }

  void _drawDiagonals(Canvas canvas, Size size, Paint paint, double sp) {
    final d = size.width + size.height;
    for (double off = -d; off < d * 2; off += sp * 2) {
      canvas.drawLine(Offset(off, -d), Offset(off + d, d), paint);
    }
  }

  void _drawCircles(Canvas canvas, Size size, Paint paint, double sp) {
    final d = size.width + size.height;
    for (double x = -d / 2; x < d / 2; x += sp * 2) {
      for (double y = -d / 2; y < d / 2; y += sp * 2) {
        canvas.drawCircle(Offset(x, y), dotSize / 3, paint);
      }
    }
  }

  void _drawTriangles(Canvas canvas, Size size, Paint paint, double sp) {
    final fillPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    final d = size.width + size.height;
    for (double x = -d / 2; x < d / 2; x += sp * 1.5) {
      for (double y = -d / 2; y < d / 2; y += sp * 1.5) {
        final path = Path()
          ..moveTo(x, y - dotSize / 3)
          ..lineTo(x + dotSize / 3, y + dotSize / 4)
          ..lineTo(x - dotSize / 3, y + dotSize / 4)
          ..close();
        canvas.drawPath(path, fillPaint);
      }
    }
  }

  void _drawHexagons(Canvas canvas, Size size, Paint paint, double sp) {
    final fillPaint = Paint()..color = paint.color..style = PaintingStyle.stroke;
    final d = size.width + size.height;
    for (double cx = -d / 2; cx < d / 2; cx += sp * 1.8) {
      for (double cy = -d / 2; cy < d / 2; cy += sp * 1.6) {
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = (i * 60 - 30) * math.pi / 180;
          final px = cx + dotSize / 3 * math.cos(a);
          final py = cy + dotSize / 3 * math.sin(a);
          if (i == 0) { path.moveTo(px, py); } else { path.lineTo(px, py); }
        }
        path.close();
        canvas.drawPath(path, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) =>
      pattern != old.pattern || thickness != old.thickness ||
      angle != old.angle || dotSize != old.dotSize ||
      opacity != old.opacity || spacing != old.spacing ||
      saturation != old.saturation ||
      customText != old.customText;
}

// ▸▸▸ CUSTOM BORDER PAINTER ▸▸▸

class _CardBorderPainter extends CustomPainter {
  final Color color;
  final double width;
  final String type;
  final double spacing;
  final String shape;
  final BorderRadius radius;

  _CardBorderPainter({
    required this.color, required this.width, required this.type,
    required this.spacing, required this.shape, required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;

    final rect = RRect.fromRectAndRadius(Offset.zero & size, radius.topLeft);

    switch (type) {
      case 'punteado':
        _drawDotted(canvas, rect, paint);
        break;
      case 'dashed':
        _drawDashed(canvas, rect, paint);
        break;
      case 'doble':
        _drawDouble(canvas, rect, paint);
        break;
      case 'ondulado':
        _drawWavyBorder(canvas, rect, paint);
        break;
      case 'relieve':
        _drawRelief(canvas, rect, paint);
        break;
      default:
        _drawSolid(canvas, rect, paint);
    }
  }

  void _drawSolid(Canvas canvas, RRect rect, Paint paint) {
    canvas.drawRRect(rect, paint);
  }

  void _drawDotted(Canvas canvas, RRect rect, Paint paint) {
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final perim = _perimeter(rect);
    final dotCount = (perim / spacing).round().clamp(8, 200);
    for (int i = 0; i < dotCount; i++) {
      final t = i / dotCount;
      final p = _pointOnRRect(rect, t);
      canvas.drawCircle(p, width * 0.6, dotPaint);
    }
  }

  void _drawDashed(Canvas canvas, RRect rect, Paint paint) {
    final perim = _perimeter(rect);
    final dashLen = spacing * 2;
    final gapLen = spacing;
    final segmentLen = dashLen + gapLen;
    final segCount = (perim / segmentLen).round().clamp(4, 100);
    for (int i = 0; i < segCount; i++) {
      final tStart = i / segCount;
      final tEnd = (i / segCount) + (dashLen / perim);
      for (double t = tStart; t < tEnd && t <= 1.0; t += 0.002) {
        final p = _pointOnRRect(rect, t);
        canvas.drawCircle(p, width * 0.3, Paint()..color = color..style = PaintingStyle.fill);
      }
    }
  }

  void _drawDouble(Canvas canvas, RRect rect, Paint paint) {
    final inner = rect.deflate(width);
    canvas.drawRRect(rect, paint);
    canvas.drawRRect(inner, Paint()..color = color.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = width * 0.5);
  }

  void _drawWavyBorder(Canvas canvas, RRect rect, Paint paint) {
    final path = Path();
    for (double t = 0; t <= 1.0; t += 0.001) {
      final p = _pointOnRRect(rect, t);
      final n = _normalAt(rect, t);
      final offset = math.sin(t * 20 * math.pi) * width;
      final wp = Offset(p.dx + n.dx * offset, p.dy + n.dy * offset);
      if (t == 0) { path.moveTo(wp.dx, wp.dy); } else { path.lineTo(wp.dx, wp.dy); }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawRelief(Canvas canvas, RRect rect, Paint paint) {
    final outer = rect;
    final inner = rect.deflate(width * 1.5);
    canvas.drawRRect(outer, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = width);
    canvas.drawRRect(inner, Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = width * 0.6);
  }

  double _perimeter(RRect rect) {
    final w = rect.width, h = rect.height, r = rect.tlRadius.x;
    return 2 * (w + h) - (8 - 2 * math.pi) * r;
  }

  Offset _pointOnRRect(RRect rect, double t) {
    t = t % 1.0;
    final w = rect.width, h = rect.height, r = rect.tlRadius.x;
    final cornerArc = (math.pi / 2) * r;
    final sideL = w - 2 * r, sideR = h - 2 * r;
    final perim = 2 * sideL + 2 * sideR + 4 * cornerArc;
    double dist = t * perim;
    double cx, cy, startAngle;

    if (dist < sideL) {
      return Offset(r + dist, 0); // top edge
    }
    dist -= sideL;
    if (dist < cornerArc) {
      cx = w - r; cy = r; startAngle = -math.pi / 2;
      final angle = startAngle + dist / r;
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    dist -= cornerArc;
    if (dist < sideR) {
      return Offset(w, r + dist); // right edge
    }
    dist -= sideR;
    if (dist < cornerArc) {
      cx = w - r; cy = h - r; startAngle = 0;
      final angle = startAngle + dist / r;
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    dist -= cornerArc;
    if (dist < sideL) {
      return Offset(w - r - dist, h); // bottom edge
    }
    dist -= sideL;
    if (dist < cornerArc) {
      cx = r; cy = h - r; startAngle = math.pi / 2;
      final angle = startAngle + dist / r;
      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    }
    dist -= cornerArc;
    cx = r; cy = r; startAngle = math.pi;
    final angle = startAngle + dist / r;
    return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
  }

  Offset _normalAt(RRect rect, double t) {
    final epsilon = 0.001;
    final p1 = _pointOnRRect(rect, t);
    final p2 = _pointOnRRect(rect, t + epsilon);
    final tangent = Offset(p2.dx - p1.dx, p2.dy - p1.dy);
    return Offset(-tangent.dy, tangent.dx); // perpendicular
  }

  @override
  bool shouldRepaint(covariant _CardBorderPainter old) =>
      color != old.color || width != old.width || type != old.type ||
      spacing != old.spacing || shape != old.shape;
}
