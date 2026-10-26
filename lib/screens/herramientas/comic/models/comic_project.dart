import 'dart:convert';
import 'comic_page.dart';
import 'comic_template.dart';

/// Representa una obra, historieta o cómic completo con múltiples páginas.
class ComicProject {
  final String id;
  final String title;
  final String author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ComicPage> pages;
  final int activePageIndex;
  final String? coverImageBase64;

  ComicProject({
    required this.id,
    required this.title,
    this.author = 'Yo',
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.pages,
    this.activePageIndex = 0,
    this.coverImageBase64,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ComicPage get activePage => pages.isNotEmpty
      ? pages[activePageIndex.clamp(0, pages.length - 1)]
      : ComicPage(id: '0', pageNumber: 1, panels: [], bubbles: [], sfxStickers: []);

  ComicProject copyWith({
    String? id,
    String? title,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ComicPage>? pages,
    int? activePageIndex,
    String? coverImageBase64,
  }) {
    return ComicProject(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pages: pages ?? this.pages,
      activePageIndex: activePageIndex ?? this.activePageIndex,
      coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'author': author,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'activePageIndex': activePageIndex,
    'coverImageBase64': coverImageBase64,
    'pages': pages.map((p) => p.toMap()).toList(),
  };

  factory ComicProject.fromMap(Map<String, dynamic> map) {
    final pagesData = (map['pages'] as List<dynamic>?) ?? [];
    var pages = pagesData.map((p) => ComicPage.fromMap(p as Map<String, dynamic>)).toList();

    if (pages.isEmpty) {
      pages = [
        ComicPage(
          id: 'page_1',
          pageNumber: 1,
          panels: ComicTemplateType.fourKoma.createPanels(),
          bubbles: [],
          sfxStickers: [],
        )
      ];
    }

    return ComicProject(
      id: map['id'] as String? ?? 'comic_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? 'Mi Cómic',
      author: map['author'] as String? ?? 'Yo',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      pages: pages,
      activePageIndex: (map['activePageIndex'] as int?) ?? 0,
      coverImageBase64: map['coverImageBase64'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory ComicProject.fromJson(String source) => ComicProject.fromMap(jsonDecode(source));
}
