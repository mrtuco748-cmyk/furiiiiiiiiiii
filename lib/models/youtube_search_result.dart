/// Resultado simplificado de búsqueda de YouTube.
class YouTubeSearchResult {
  final String id;
  final String title;
  final String author;
  final int durationSeconds;
  final String thumbnailUrl;

  YouTubeSearchResult({
    required this.id,
    required this.title,
    required this.author,
    required this.durationSeconds,
    required this.thumbnailUrl,
  });

  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
