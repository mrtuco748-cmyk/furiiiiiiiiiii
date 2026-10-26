import 'comic_panel.dart';
import 'comic_template_layouts.dart';

/// Las 12 plantillas clásicas y útiles de viñetas para historietas, cómic y manga.
enum ComicTemplateType {
  singleFull,
  twoHorizontal,
  threeTiers,
  fourKoma,
  sixGrid,
  nineGrid,
  comicHeroSplit,
  shonenSlash,
  actionManga5,
  mangaClimax,
  dailyStrip,
  webtoonScroll;

  String get displayName {
    switch (this) {
      case ComicTemplateType.singleFull:
        return 'Página Completa / Splash';
      case ComicTemplateType.twoHorizontal:
        return '2 Viñetas Dobles (1:1)';
      case ComicTemplateType.threeTiers:
        return '3 Tiras Clásicas';
      case ComicTemplateType.fourKoma:
        return '4-Koma Manga (Yonkoma)';
      case ComicTemplateType.sixGrid:
        return '6 Viñetas (Grilla 2x3)';
      case ComicTemplateType.nineGrid:
        return '9 Viñetas (Grilla 3x3)';
      case ComicTemplateType.comicHeroSplit:
        return 'Heroico Split (1 Grande + 3)';
      case ComicTemplateType.shonenSlash:
        return 'Shonen Diagonal (3 Viñetas)';
      case ComicTemplateType.actionManga5:
        return 'Manga Acción (5 Viñetas)';
      case ComicTemplateType.mangaClimax:
        return 'Clímax Manga (Tensión + Splash)';
      case ComicTemplateType.dailyStrip:
        return 'Tira Diaria (3 Cuadros)';
      case ComicTemplateType.webtoonScroll:
        return 'Webtoon Suave (3 Paneles)';
    }
  }

  String get label => displayName;

  String get description {
    switch (this) {
      case ComicTemplateType.singleFull:
        return 'Impacto total a página completa para portadas o momentos clave';
      case ComicTemplateType.twoHorizontal:
        return 'Dos planos amplios para diálogo extenso o contraste';
      case ComicTemplateType.threeTiers:
        return 'Narrativa clásica de tres actos (inicio, nudo, desenlace)';
      case ComicTemplateType.fourKoma:
        return 'Tira cómica tradicional japonesa de cuatro paneles';
      case ComicTemplateType.sixGrid:
        return 'Estructura estándar universal de cómic y novela gráfica';
      case ComicTemplateType.nineGrid:
        return 'Ritmo cinematográfico milimétrico estilo novela gráfica';
      case ComicTemplateType.comicHeroSplit:
        return 'Gran panel protagónico con 3 viñetas de soporte lateral';
      case ComicTemplateType.shonenSlash:
        return 'Viñeta superior con corte diagonal dinámico de acción shonen';
      case ComicTemplateType.actionManga5:
        return 'Dos viñetas de ritmo, gran plano de impacto y resolución';
      case ComicTemplateType.mangaClimax:
        return 'Viñeta de tensión arriba y revelación gigante abajo';
      case ComicTemplateType.dailyStrip:
        return 'Tres viñetas horizontales para gag o tira de prensa';
      case ComicTemplateType.webtoonScroll:
        return 'Tres viñetas redondeadas con espacio para lectura vertical';
    }
  }

  List<ComicPanel> createPanels({double gutter = 0.02}) {
    return ComicTemplateLayouts.generate(this, gutter: gutter);
  }
}
