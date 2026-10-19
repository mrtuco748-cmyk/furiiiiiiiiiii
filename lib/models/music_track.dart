/// Modelo de canción de la biblioteca de música compartida de F.U.R.I.
/// Soporta reproducción local y por streaming desde Supabase Storage.
class MusicTrack {
  final int? id;
  final int? cloudId;
  final String youtubeId;
  final String title;
  final String artist;
  final int durationSeconds;
  final String thumbnailUrl;
  final String audioUrl;
  final String localPath;
  final String addedBy; // 'Facu' o 'Rocio'
  final int sizeBytes;
  final bool isFavorite;
  final int synced;
  final String? createdAt;

  MusicTrack({
    this.id,
    this.cloudId,
    required this.youtubeId,
    required this.title,
    this.artist = '',
    this.durationSeconds = 0,
    this.thumbnailUrl = '',
    required this.audioUrl,
    this.localPath = '',
    this.addedBy = '',
    this.sizeBytes = 0,
    this.isFavorite = false,
    this.synced = 1,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cloud_id': cloudId,
      'youtube_id': youtubeId,
      'title': title,
      'artist': artist,
      'duration_seconds': durationSeconds,
      'thumbnail_url': thumbnailUrl,
      'audio_url': audioUrl,
      'local_path': localPath,
      'added_by': addedBy,
      'size_bytes': sizeBytes,
      'is_favorite': isFavorite ? 1 : 0,
      'synced': synced,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'youtube_id': youtubeId,
      'title': title,
      'artist': artist,
      'duration_seconds': durationSeconds,
      'thumbnail_url': thumbnailUrl,
      'audio_url': audioUrl,
      'added_by': addedBy,
      'size_bytes': sizeBytes,
      'is_favorite': isFavorite,
      'created_at': createdAt,
    };
  }

  factory MusicTrack.fromMap(Map<String, dynamic> map) {
    return MusicTrack(
      id: map['id'] as int?,
      cloudId: (map['cloud_id'] ?? map['cloudId']) as int?,
      youtubeId: (map['youtube_id'] ?? map['youtubeId'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      artist: (map['artist'] ?? '') as String,
      durationSeconds: (map['duration_seconds'] ?? map['durationSeconds'] ?? 0) as int,
      thumbnailUrl: (map['thumbnail_url'] ?? map['thumbnailUrl'] ?? '') as String,
      audioUrl: (map['audio_url'] ?? map['audioUrl'] ?? '') as String,
      localPath: (map['local_path'] ?? map['localPath'] ?? '') as String,
      addedBy: (map['added_by'] ?? map['addedBy'] ?? '') as String,
      sizeBytes: (map['size_bytes'] ?? map['sizeBytes'] ?? 0) as int,
      isFavorite: (map['is_favorite'] == 1 || map['is_favorite'] == true),
      synced: (map['synced'] ?? 1) as int,
      createdAt: map['created_at'] as String?,
    );
  }

  factory MusicTrack.fromCloudRow(Map<String, dynamic> m) {
    return MusicTrack(
      cloudId: m['id'] as int?,
      youtubeId: (m['youtube_id'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      artist: (m['artist'] ?? '') as String,
      durationSeconds: (m['duration_seconds'] ?? 0) as int,
      thumbnailUrl: (m['thumbnail_url'] ?? '') as String,
      audioUrl: (m['audio_url'] ?? '') as String,
      localPath: '',
      addedBy: (m['added_by'] ?? '') as String,
      sizeBytes: (m['size_bytes'] ?? 0) as int,
      isFavorite: m['is_favorite'] == true,
      synced: 1,
      createdAt: m['created_at']?.toString(),
    );
  }

  MusicTrack copyWith({
    int? id,
    int? cloudId,
    String? youtubeId,
    String? title,
    String? artist,
    int? durationSeconds,
    String? thumbnailUrl,
    String? audioUrl,
    String? localPath,
    String? addedBy,
    int? sizeBytes,
    bool? isFavorite,
    int? synced,
    String? createdAt,
    bool clearCloudId = false,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      cloudId: clearCloudId ? null : (cloudId ?? this.cloudId),
      youtubeId: youtubeId ?? this.youtubeId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      localPath: localPath ?? this.localPath,
      addedBy: addedBy ?? this.addedBy,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      isFavorite: isFavorite ?? this.isFavorite,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get durationFormatted {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
