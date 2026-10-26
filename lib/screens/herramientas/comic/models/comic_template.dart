import 'comic_panel.dart';
import 'comic_template_layouts.dart';

/// Tipos de plantillas y estructuras de viñetas dinámicas y divertidas para páginas de cómic.
enum ComicTemplateType {
  singleFull,
  twoHorizontal,
  threeTiers,
  fourKoma,
  sixGrid,
  shonenSlash,
  comicHeroSplit,
  webtoonScroll,
  funnyGagChaos,
  overlappingImpact,
  cinematicWidescreen,
  shoujoDream,
  actionClimax5,
  crossroadsMosaic;

  String get displayName {
    switch (this) {
      case ComicTemplateType.singleFull:
        return 'Página Completa / Splash';
      case ComicTemplateType.twoHorizontal:
        return '2 Viñetas (Doble)';
      case ComicTemplateType.threeTiers:
        return '3 Tiras Clásicas';
      case ComicTemplateType.fourKoma:
        return '4-Koma Manga (Yonkoma)';
      case ComicTemplateType.sixGrid:
        return '6 Viñetas (Grilla)';
      case ComicTemplateType.shonenSlash:
        return 'Shonen Diagonal (Impacto)';
      case ComicTemplateType.comicHeroSplit:
        return 'Marvel Heroico (Split)';
      case ComicTemplateType.webtoonScroll:
        return 'Webtoon Vertical Suave';
      case ComicTemplateType.funnyGagChaos:
        return 'Caos Cómico Divertido';
      case ComicTemplateType.overlappingImpact:
        return 'Impacto Superpuesto';
      case ComicTemplateType.cinematicWidescreen:
        return 'Cine Anamórfico 21:9';
      case ComicTemplateType.shoujoDream:
        return 'Shojo Romántico';
      case ComicTemplateType.actionClimax5:
        return 'Clímax Acción 5 Viñetas';
      case ComicTemplateType.crossroadsMosaic:
        return 'Mosaico Suspenso';
    }
  }

  String get label => displayName;

  String get description {
    switch (this) {
      case ComicTemplateType.singleFull:
        return 'Impacto visual a página completa';
      case ComicTemplateType.twoHorizontal:
        return 'Plano cinematográfico doble';
      case ComicTemplateType.threeTiers:
        return 'Narrativa clásica de tres actos';
      case ComicTemplateType.fourKoma:
        return 'Tira cómica vertical tradicional';
      case ComicTemplateType.sixGrid:
        return 'Secuencia estándar de seis viñetas';
      case ComicTemplateType.shonenSlash:
        return 'Corte diagonal dinámico de acción shonen';
      case ComicTemplateType.comicHeroSplit:
        return 'Layout clásico de superhéroes Marvel/DC';
      case ComicTemplateType.webtoonScroll:
        return 'Paneles verticales redondeados estilo manhwa';
      case ComicTemplateType.funnyGagChaos:
        return 'Paneles desordenados y micro-reacción cómica';
      case ComicTemplateType.overlappingImpact:
        return 'Viñeta flotante sobre splash de fondo';
      case ComicTemplateType.cinematicWidescreen:
        return 'Planos panorámicos oscuros estilo película';
      case ComicTemplateType.shoujoDream:
        return 'Composición tierna y emotiva para momentos íntimos';
      case ComicTemplateType.actionClimax5:
        return 'Velocidad vertiginosa con 3 viñetas diagonales';
      case ComicTemplateType.crossroadsMosaic:
        return 'Mosaico asimétrico de misterio';
    }
  }

  List<ComicPanel> createPanels({double gutter = 0.02}) {
    return ComicTemplateLayouts.generate(this, gutter: gutter);
  }
}
