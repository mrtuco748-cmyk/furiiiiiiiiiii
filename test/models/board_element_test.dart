import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:furi_app/models/board_element.dart';
import 'package:furi_app/screens/milanote/models/note_style_config.dart';
import 'package:furi_app/screens/milanote/painters/note_shape_utils.dart';

void main() {
  group('BoardElement model tests', () {
    test('instantiates with defaults and converts to/from SQLite map', () {
      final now = DateTime.now().toIso8601String();
      final element = BoardElement(
        id: 1,
        cloudId: 101,
        boardId: 1,
        userId: 'Facu',
        type: 'note',
        title: 'Mi Idea',
        content: 'Recordar comprar flores',
        color: '#9D00FF',
        x: 150.0,
        y: 220.5,
        width: 220.0,
        height: 180.0,
        data: {'noteType': 'postit'},
        synced: 1,
        createdAt: now,
        updatedAt: now,
      );

      final map = element.toMap();
      expect(map['id'], 1);
      expect(map['cloud_id'], 101);
      expect(map['board_id'], 1);
      expect(map['user_id'], 'Facu');
      expect(map['type'], 'note');
      expect(map['title'], 'Mi Idea');
      expect(map['content'], 'Recordar comprar flores');
      expect(map['color'], '#9D00FF');
      expect(map['x'], 150.0);
      expect(map['y'], 220.5);
      expect(map['width'], 220.0);
      expect(map['height'], 180.0);
      expect(map['synced'], 1);
      expect(map['data'], contains('postit'));

      final fromMap = BoardElement.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.cloudId, 101);
      expect(fromMap.title, 'Mi Idea');
      expect(fromMap.x, 150.0);
      expect(fromMap.y, 220.5);
      expect(fromMap.data['noteType'], 'postit');
    });

    test('toSupabaseMap and fromCloudRow map properly', () {
      final element = BoardElement(
        cloudId: 55,
        boardId: 1,
        userId: 'Rocio',
        type: 'checklist',
        title: 'Supermercado',
        content: '',
        color: '#39FF14',
        x: -50.0,
        y: 80.0,
        width: 250.0,
        height: 200.0,
        data: {
          'items': [
            {'text': 'Frutas', 'done': true}
          ]
        },
        createdAt: '2026-10-14T10:00:00Z',
        updatedAt: '2026-10-14T10:00:00Z',
      );

      final supaMap = element.toSupabaseMap();
      expect(supaMap['user_id'], 'Rocio');
      expect(supaMap['board_id'], 1);
      expect(supaMap['type'], 'checklist');
      expect(supaMap['x'], -50.0);
      expect(supaMap['y'], 80.0);
      expect(supaMap['data'], isA<Map>());

      final cloudRow = {
        'id': 55,
        'board_id': 1,
        'user_id': 'Rocio',
        'type': 'checklist',
        'title': 'Supermercado',
        'content': '',
        'color': '#39FF14',
        'x': -50.0,
        'y': 80.0,
        'width': 250.0,
        'height': 200.0,
        'data': {
          'items': [
            {'text': 'Frutas', 'done': true}
          ]
        },
        'created_at': '2026-10-14T10:00:00Z',
        'updated_at': '2026-10-14T10:00:00Z',
      };

      final fromCloud = BoardElement.fromCloudRow(cloudRow);
      expect(fromCloud.cloudId, 55);
      expect(fromCloud.userId, 'Rocio');
      expect(fromCloud.x, -50.0);
      expect(fromCloud.data['items'].first['text'], 'Frutas');
    });

    test('copyWith updates fields as expected', () {
      final original = BoardElement(
        id: 10,
        title: 'Original',
        x: 10,
        y: 10,
      );

      final moved = original.copyWith(x: 100, y: 200, title: 'Movido');
      expect(moved.id, 10);
      expect(moved.x, 100);
      expect(moved.y, 200);
      expect(moved.title, 'Movido');
    });
  });

  group('NoteStyleConfig & NoteShapeUtils tests', () {
    test('serializes and deserializes 3-stop gradient, patterns, shapes, borders, and paragraph overrides', () {
      final config = NoteStyleConfig(
        baseMode: 'gradient',
        gradientStartColor: '#FF2A85',
        gradientMidColor: '#7B2CBF',
        gradientEndColor: '#00F5D4',
        gradientAngle: 45.0,
        patternType: NotePatternType.waves,
        patternStrokeWidth: 3.5,
        patternSpacing: 28.0,
        patternScale: 20.0,
        patternOpacity: 0.45,
        patternUseGradient: true,
        shapeType: NoteShapeType.diamond,
        borderType: NoteBorderType.dashed,
        borderWidth: 4.0,
        borderSpacing: 10.0,
        borderColor: '#2EE50F',
        hasShine: true,
        titleFont: 'Cinzel',
        titleFormat: TextBlockFormat.escuadra,
        bodyFont: 'Space Mono',
        inlineImagePosition: InlineImagePosition.middleBody,
        paragraphOverrides: const {
          1: ParagraphStyleOverride(
            fontFamily: 'Pacifico',
            colorHex: '#FFB703',
            fontSize: 18.0,
            format: TextBlockFormat.sunken,
          ),
        },
      );

      final map = config.toDataMap();
      final restored = NoteStyleConfig.fromElement(
        fallbackColor: '#1E2436',
        data: map,
      );

      expect(restored.baseMode, 'gradient');
      expect(restored.gradientStartColor, '#FF2A85');
      expect(restored.gradientMidColor, '#7B2CBF');
      expect(restored.gradientEndColor, '#00F5D4');
      expect(restored.gradientAngle, 45.0);
      expect(restored.patternType, NotePatternType.waves);
      expect(restored.patternUseGradient, isTrue);
      expect(restored.shapeType, NoteShapeType.diamond);
      expect(restored.borderType, NoteBorderType.dashed);
      expect(restored.hasShine, isTrue);
      expect(restored.titleFont, 'Cinzel');
      expect(restored.titleFormat, TextBlockFormat.escuadra);
      expect(restored.inlineImagePosition, InlineImagePosition.middleBody);
      expect(restored.paragraphOverrides[1]?.fontFamily, 'Pacifico');
      expect(restored.paragraphOverrides[1]?.format, TextBlockFormat.sunken);
    });

    test('context-sensitive pattern capabilities match pattern semantics', () {
      const chessCfg = NoteStyleConfig(patternType: NotePatternType.chess);
      expect(chessCfg.patternSupportsSpacing, isFalse);
      expect(chessCfg.patternSupportsStrokeWidth, isFalse);
      expect(chessCfg.patternSupportsScale, isTrue);

      const lineCfg = NoteStyleConfig(patternType: NotePatternType.linesOblique);
      expect(lineCfg.patternSupportsStrokeWidth, isTrue);
      expect(lineCfg.patternSupportsSpacing, isTrue);
      expect(lineCfg.patternSupportsFillToggle, isFalse);

      const circleCfg = NoteStyleConfig(patternType: NotePatternType.circlesEmpty);
      expect(circleCfg.patternSupportsSpacing, isTrue);
      expect(circleCfg.patternSupportsStrokeWidth, isTrue);
      expect(circleCfg.patternSupportsFillToggle, isTrue);
    });

    test('NoteShapeUtils computes valid paths, content padding, and perimeter resize handles for all shapes', () {
      const size = Size(260, 220);
      for (final shape in NoteShapeType.values) {
        final path = NoteShapeUtils.buildShapePath(shape, size);
        expect(path.getBounds().width, greaterThan(100));
        expect(path.getBounds().height, greaterThan(100));

        final pad = NoteShapeUtils.getContentPadding(shape, size);
        expect(pad.left, greaterThanOrEqualTo(16));
        expect(pad.top, greaterThanOrEqualTo(16));

        final handle = NoteShapeUtils.getResizeHandleCenter(shape, size);
        expect(handle.dx, inInclusiveRange(size.width * 0.5, size.width));
        expect(handle.dy, inInclusiveRange(size.height * 0.5, size.height));
      }
    });
  });
}
