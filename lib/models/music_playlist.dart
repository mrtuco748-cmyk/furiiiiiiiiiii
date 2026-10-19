import 'dart:convert';

/// Modelo de playlist compartida de música entre Facu y Rocío.
class MusicPlaylist {
  final int? id;
  final int? cloudId;
  final String title;
  final String description;
  final String createdBy; // 'Facu' o 'Rocio'
  final List<int> trackIds; // Lista de cloudIds o localIds de canciones
  final String createdAt;

  MusicPlaylist({
    this.id,
    this.cloudId,
    required this.title,
    this.description = '',
    required this.createdBy,
    this.trackIds = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cloud_id': cloudId,
      'title': title,
      'description': description,
      'created_by': createdBy,
      'track_ids': jsonEncode(trackIds),
      'created_at': createdAt,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'title': title,
      'description': description,
      'created_by': createdBy,
      'track_ids': trackIds,
      'created_at': createdAt,
    };
  }

  factory MusicPlaylist.fromMap(Map<String, dynamic> map) {
    List<int> parsedTrackIds = [];
    final rawTracks = map['track_ids'] ?? map['trackIds'];
    if (rawTracks is List) {
      parsedTrackIds = rawTracks.map((e) => (e as num).toInt()).toList();
    } else if (rawTracks is String && rawTracks.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTracks);
        if (decoded is List) {
          parsedTrackIds = decoded.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {}
    }

    return MusicPlaylist(
      id: map['id'] as int?,
      cloudId: (map['cloud_id'] ?? map['cloudId']) as int?,
      title: (map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      createdBy: (map['created_by'] ?? map['createdBy'] ?? '') as String,
      trackIds: parsedTrackIds,
      createdAt: (map['created_at'] ?? '') as String,
    );
  }

  factory MusicPlaylist.fromCloudRow(Map<String, dynamic> m) {
    List<int> parsedTrackIds = [];
    final rawTracks = m['track_ids'];
    if (rawTracks is List) {
      parsedTrackIds = rawTracks.map((e) => (e as num).toInt()).toList();
    } else if (rawTracks is String && rawTracks.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawTracks);
        if (decoded is List) {
          parsedTrackIds = decoded.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {}
    }

    return MusicPlaylist(
      cloudId: m['id'] as int?,
      title: (m['title'] ?? '') as String,
      description: (m['description'] ?? '') as String,
      createdBy: (m['created_by'] ?? '') as String,
      trackIds: parsedTrackIds,
      createdAt: m['created_at']?.toString() ?? '',
    );
  }

  MusicPlaylist copyWith({
    int? id,
    int? cloudId,
    String? title,
    String? description,
    String? createdBy,
    List<int>? trackIds,
    String? createdAt,
  }) {
    return MusicPlaylist(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      trackIds: trackIds ?? this.trackIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
