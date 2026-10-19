import '../services/music_download_service.dart';
import 'music_track.dart';

/// Estado de un elemento en la cola de descarga de música
enum DownloadItemStatus {
  queued,
  downloading,
  completed,
  failed,
  cancelled,
}

/// Representa una canción en la cola de descarga
class DownloadQueueItem {
  final YouTubeSearchResult searchResult;
  DownloadItemStatus status;
  double progress;
  String statusMessage;
  String? errorMessage;
  final DateTime addedAt;
  MusicTrack? savedTrack;

  DownloadQueueItem({
    required this.searchResult,
    this.status = DownloadItemStatus.queued,
    this.progress = 0.0,
    this.statusMessage = 'En cola...',
    this.errorMessage,
    DateTime? addedAt,
    this.savedTrack,
  }) : addedAt = addedAt ?? DateTime.now();

  String get id => searchResult.id;
  String get title => searchResult.title;
  String get author => searchResult.author;
  String get thumbnailUrl => searchResult.thumbnailUrl;
  int get durationSeconds => searchResult.durationSeconds;
  String get durationFormatted => searchResult.durationFormatted;

  bool get isQueued => status == DownloadItemStatus.queued;
  bool get isDownloading => status == DownloadItemStatus.downloading;
  bool get isCompleted => status == DownloadItemStatus.completed;
  bool get isFailed => status == DownloadItemStatus.failed;
  bool get isCancelled => status == DownloadItemStatus.cancelled;

  DownloadQueueItem copyWith({
    DownloadItemStatus? status,
    double? progress,
    String? statusMessage,
    String? errorMessage,
    MusicTrack? savedTrack,
  }) {
    return DownloadQueueItem(
      searchResult: searchResult,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      addedAt: addedAt,
      savedTrack: savedTrack ?? this.savedTrack,
    );
  }
}
