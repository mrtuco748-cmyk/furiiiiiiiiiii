import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../database/database_helper.dart';
import '../../models/download_queue_item.dart';
import '../../models/music_comment.dart';
import '../../models/music_playlist.dart';
import '../../models/music_track.dart';
import '../../services/music_download_service.dart';
import '../../supabase_config.dart';
import 'helpers/music_audio_controller.dart';
import 'helpers/music_comments_manager.dart';
import 'helpers/music_download_queue_manager.dart';
import 'helpers/music_playlists_manager.dart';
import 'helpers/music_sync_service.dart';

class MusicPlayerProvider extends ChangeNotifier {
  static const _tableName = 'music_tracks';
  static MusicPlayerProvider? _instance;
  static MusicPlayerProvider? get currentInstance => _instance;

  bool _isMusicScreenOpen = false;
  bool get isMusicScreenOpen => _isMusicScreenOpen;
  void setMusicScreenOpen(bool open) {
    if (_isMusicScreenOpen != open) {
      _isMusicScreenOpen = open;
      notifyListeners();
    }
  }

  final MusicDownloadService _downloadService = MusicDownloadService();
  late final MusicAudioController _audio;
  late final MusicPlaylistsManager _playlistsMgr;
  late final MusicCommentsManager _commentsMgr;
  late final MusicDownloadQueueManager _downloadMgr;

  List<MusicTrack> _tracks = [];
  MusicTrack? _currentTrack;
  bool _loading = false;
  RealtimeChannel? _channel;

  List<MusicTrack> get tracks => _tracks;
  MusicTrack? get currentTrack => _currentTrack;
  PlayerState get playerState => _audio.playerState;
  bool get isPlaying => _audio.playerState == PlayerState.playing;
  Duration get position => _audio.position;
  Duration get duration => _audio.duration;
  bool get loading => _loading;

  // Delegations: Download queue
  bool get isDownloading => _downloadMgr.isDownloading;
  double get downloadProgress => _downloadMgr.downloadProgress;
  String get downloadStatus => _downloadMgr.downloadStatus;
  String? get lastDownloadError => _downloadMgr.lastDownloadError;
  List<DownloadQueueItem> get downloadQueue => _downloadMgr.downloadQueue;
  int get queuedCount => _downloadMgr.queuedCount;
  int get activeOrQueuedCount => _downloadMgr.activeOrQueuedCount;
  DownloadQueueItem? get currentDownloadingItem => _downloadMgr.currentDownloadingItem;
  bool isDownloadingItem(String youtubeId) => _downloadMgr.isDownloadingItem(youtubeId);
  bool isQueuedItem(String youtubeId) => _downloadMgr.isQueuedItem(youtubeId);
  DownloadQueueItem? getQueueItem(String youtubeId) => _downloadMgr.getQueueItem(youtubeId);
  int getQueuePosition(String youtubeId) => _downloadMgr.getQueuePosition(youtubeId);
  Set<int> get localDownloadingIds => _downloadMgr.localDownloadingIds;

  // Delegations: Playlists & Comments
  List<MusicPlaylist> get playlists => _playlistsMgr.playlists;
  MusicPlaylist? get currentPlaylist => _playlistsMgr.currentPlaylist;
  Map<int, List<MusicComment>> get commentsByTrack => _commentsMgr.commentsByTrack;

  MusicPlayerProvider() {
    _instance = this;
    _audio = MusicAudioController(
      onNotify: notifyListeners,
      onTrackCompleted: playNext,
    );
    _playlistsMgr = MusicPlaylistsManager(onNotify: notifyListeners);
    _commentsMgr = MusicCommentsManager(onNotify: notifyListeners);
    _downloadMgr = MusicDownloadQueueManager(
      downloadService: _downloadService,
      onNotify: notifyListeners,
      onReloadTracks: _reloadFromLocal,
      getTracks: () => _tracks,
      onUpdateTrack: (updated) {
        final idx = _tracks.indexWhere((t) => t.id == updated.id);
        if (idx != -1) _tracks[idx] = updated;
        if (_currentTrack?.id == updated.id) _currentTrack = updated;
      },
    );

    _audio.init(
      onPlayPrevious: playPrevious,
      onTogglePlayPause: togglePlayPause,
      onPause: pause,
      onPlayNext: playNext,
      onStop: stop,
      getCurrentTrack: () => _currentTrack,
    );
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      await MusicSyncService.pullFromCloud();
      await _playlistsMgr.pullPlaylistsFromCloud();
    } catch (e) {
      developer.log('MusicPlayerProvider.load sync error: $e');
    }
    await _reloadFromLocal();
    await _playlistsMgr.reloadPlaylistsFromLocal();
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  Future<void> _reloadFromLocal() async {
    _tracks = await MusicSyncService.reloadFromLocal();
    notifyListeners();
  }

  void _subscribeRealtime() {
    _channel?.unsubscribe();
    _channel = MusicSyncService.subscribeRealtime(
      onInsertTrack: (incoming) {
        if (!_tracks.any((t) => t.cloudId == incoming.cloudId)) {
          _tracks.insert(0, incoming);
          notifyListeners();
        }
      },
      onDeleteTrack: (cloudId) {
        _tracks.removeWhere((t) => t.cloudId == cloudId);
        notifyListeners();
      },
      onPlaylistsChanged: () => _playlistsMgr.pullPlaylistsFromCloud(),
      onCommentsChanged: (trackId) => _commentsMgr.loadComments(trackId),
    );
  }

  // --- REPRODUCCIÓN ---

  Future<void> play(MusicTrack track) async {
    _currentTrack = track;
    notifyListeners();
    await _audio.playTrack(track);
  }

  Future<void> pause() => _audio.pause(_currentTrack);

  Future<void> resume() => _audio.resume(_currentTrack);

  Future<void> togglePlayPause() async {
    if (_audio.playerState == PlayerState.playing) {
      await pause();
    } else {
      if (_currentTrack != null) {
        await resume();
      } else if (_tracks.isNotEmpty) {
        await play(_tracks.first);
      }
    }
  }

  Future<void> stop() async {
    _currentTrack = null;
    await _audio.stop();
    notifyListeners();
  }

  Future<void> seek(Duration pos) => _audio.seek(pos, _currentTrack);

  void playNext() {
    final list = _playlistsMgr.currentPlaylist != null
        ? _playlistsMgr.getTracksForPlaylist(_playlistsMgr.currentPlaylist!, _tracks)
        : _tracks;
    if (list.isEmpty || _currentTrack == null) return;
    final idx = list.indexWhere((t) => t.id == _currentTrack!.id);
    if (idx != -1 && idx + 1 < list.length) {
      play(list[idx + 1]);
    } else if (list.isNotEmpty) {
      play(list.first);
    }
  }

  void playPrevious() {
    final list = _playlistsMgr.currentPlaylist != null
        ? _playlistsMgr.getTracksForPlaylist(_playlistsMgr.currentPlaylist!, _tracks)
        : _tracks;
    if (list.isEmpty || _currentTrack == null) return;
    final idx = list.indexWhere((t) => t.id == _currentTrack!.id);
    if (idx > 0) {
      play(list[idx - 1]);
    } else if (list.isNotEmpty) {
      play(list.last);
    }
  }

  Future<void> toggleFavorite(MusicTrack track) async {
    final newFav = !track.isFavorite;
    final updated = track.copyWith(isFavorite: newFav);
    final idx = _tracks.indexWhere((t) => t.id == track.id);
    if (idx != -1) {
      _tracks[idx] = updated;
      notifyListeners();
    }

    try {
      final db = await DatabaseHelper().database;
      await db.update(_tableName, {'is_favorite': newFav ? 1 : 0}, where: 'id = ?', whereArgs: [track.id]);
      if (track.cloudId != null) {
        await SupabaseConfig.client.from(_tableName).update({'is_favorite': newFav}).eq('id', track.cloudId!);
      }
    } catch (e) {
      developer.log('MusicPlayerProvider.toggleFavorite error: $e');
    }
  }

  Future<void> deleteTrack(MusicTrack track) async {
    if (_currentTrack?.id == track.id) await stop();
    _tracks.removeWhere((t) => t.id == track.id);
    notifyListeners();

    try {
      final db = await DatabaseHelper().database;
      await db.delete(_tableName, where: 'id = ?', whereArgs: [track.id]);
      if (track.localPath.isNotEmpty) {
        final f = File(track.localPath);
        if (await f.exists()) await f.delete();
      }
      if (track.cloudId != null) {
        await SupabaseConfig.client.from(_tableName).delete().eq('id', track.cloudId!);
      }
    } catch (e) {
      developer.log('MusicPlayerProvider.deleteTrack error: $e');
    }
  }

  // Delegations
  Future<List<YouTubeSearchResult>> searchYouTube(String query) => _downloadMgr.searchYouTube(query);
  bool addToDownloadQueue(YouTubeSearchResult result) => _downloadMgr.addToDownloadQueue(result);
  void removeFromQueue(String youtubeId) => _downloadMgr.removeFromQueue(youtubeId);
  void retryDownload(String youtubeId) => _downloadMgr.retryDownload(youtubeId);
  void clearFinishedDownloads() => _downloadMgr.clearFinishedDownloads();
  Future<MusicTrack?> downloadTrack(YouTubeSearchResult result) => _downloadMgr.downloadTrack(result);
  Future<bool> downloadTrackLocally(MusicTrack track) => _downloadMgr.downloadTrackLocally(track);
  Future<void> removeLocalCopy(MusicTrack track) => _downloadMgr.removeLocalCopy(track);

  Future<MusicPlaylist?> createPlaylist(String title, [String description = '']) =>
      _playlistsMgr.createPlaylist(title, description);
  Future<void> toggleTrackInPlaylist(MusicPlaylist playlist, int trackIdentifier) =>
      _playlistsMgr.toggleTrackInPlaylist(playlist, trackIdentifier);
  Future<void> deletePlaylist(MusicPlaylist playlist) => _playlistsMgr.deletePlaylist(playlist);
  void playPlaylist(MusicPlaylist playlist, [int startIndex = 0]) {
    _playlistsMgr.currentPlaylist = playlist;
    final playlistTracks = _playlistsMgr.getTracksForPlaylist(playlist, _tracks);
    if (playlistTracks.isNotEmpty) {
      final trackToPlay = (startIndex >= 0 && startIndex < playlistTracks.length)
          ? playlistTracks[startIndex]
          : playlistTracks.first;
      play(trackToPlay);
    }
  }
  List<MusicTrack> getTracksForPlaylist(MusicPlaylist playlist) =>
      _playlistsMgr.getTracksForPlaylist(playlist, _tracks);

  List<MusicComment> getCommentsForTrack(int trackId) => _commentsMgr.getCommentsForTrack(trackId);
  Future<void> loadComments(int trackId) => _commentsMgr.loadComments(trackId);
  Future<void> addComment(int trackId, String content) => _commentsMgr.addComment(trackId, content);
  Future<void> deleteComment(MusicComment comment) => _commentsMgr.deleteComment(comment);

  @override
  void dispose() {
    _audio.dispose();
    _downloadService.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }
}
