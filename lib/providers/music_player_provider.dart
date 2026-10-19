import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_state.dart';
import '../database/database_helper.dart';
import '../models/download_queue_item.dart';
import '../models/music_comment.dart';
import '../models/music_playlist.dart';
import '../models/music_track.dart';
import '../services/music_download_service.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import '../supabase_config.dart';

/// Provider central para el reproductor de música compartida de F.U.R.I.
/// Controla reproducción, cola, búsqueda, descarga offline, playlists,
/// comentarios y sincronización en tiempo real entre Facu y Rocío.
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

  final AudioPlayer _player = AudioPlayer();
  final MusicDownloadService _downloadService = MusicDownloadService();

  List<MusicTrack> _tracks = [];
  MusicTrack? _currentTrack;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _loading = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  String? _lastDownloadError;

  // Cola de descargas secuencial
  final List<DownloadQueueItem> _downloadQueue = [];
  bool _isProcessingQueue = false;

  // Playlists y comentarios
  List<MusicPlaylist> _playlists = [];
  MusicPlaylist? _currentPlaylist;
  final Map<int, List<MusicComment>> _commentsByTrack = {};
  final Set<int> _loadingCommentsForTrack = {};

  // Descargas offline en progreso
  final Set<int> _localDownloadingIds = {};

  RealtimeChannel? _channel;
  bool _realtimeUp = false;

  // Stream subscriptions
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  List<MusicTrack> get tracks => _tracks;
  MusicTrack? get currentTrack => _currentTrack;
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get loading => _loading;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get downloadStatus => _downloadStatus;
  String? get lastDownloadError => _lastDownloadError;

  // Getters de la cola de descargas
  List<DownloadQueueItem> get downloadQueue => List.unmodifiable(_downloadQueue);
  int get queuedCount => _downloadQueue.where((i) => i.isQueued).length;
  int get activeOrQueuedCount => _downloadQueue.where((i) => i.isDownloading || i.isQueued).length;
  DownloadQueueItem? get currentDownloadingItem =>
      _downloadQueue.where((i) => i.isDownloading).firstOrNull;

  bool isDownloadingItem(String youtubeId) =>
      _downloadQueue.any((i) => i.id == youtubeId && i.isDownloading);

  bool isQueuedItem(String youtubeId) =>
      _downloadQueue.any((i) => i.id == youtubeId && i.isQueued);

  DownloadQueueItem? getQueueItem(String youtubeId) =>
      _downloadQueue.where((i) => i.id == youtubeId).firstOrNull;

  int getQueuePosition(String youtubeId) {
    final queuedList = _downloadQueue.where((i) => i.isQueued).toList();
    final idx = queuedList.indexWhere((i) => i.id == youtubeId);
    return idx != -1 ? idx + 1 : 0;
  }

  List<MusicPlaylist> get playlists => _playlists;
  MusicPlaylist? get currentPlaylist => _currentPlaylist;
  Map<int, List<MusicComment>> get commentsByTrack => _commentsByTrack;
  Set<int> get localDownloadingIds => _localDownloadingIds;

  static final AudioContext _mediaAudioContext = AudioContext(
    android: AudioContextAndroid(
      isSpeakerphoneOn: false,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {
        AVAudioSessionOptions.mixWithOthers,
      },
    ),
  );

  MusicPlayerProvider() {
    _instance = this;
    _initAudioListeners();
  }

  void _initAudioListeners() {
    _player.setAudioContext(_mediaAudioContext);

    NotificationService.onMusicAction = (actionId) {
      if (actionId == 'music_prev') {
        playPrevious();
      } else if (actionId == 'music_play_pause') {
        togglePlayPause();
      } else if (actionId == 'music_next') {
        playNext();
      }
    };

    _posSub = _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });

    _durSub = _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _stateSub = _player.onPlayerStateChanged.listen((s) {
      _playerState = s;
      SoundService.isMusicPlaying = (s == PlayerState.playing || s == PlayerState.paused);
      if (s == PlayerState.playing) {
        SoundService().stopBackgroundMusic();
      }
      notifyListeners();
      if (_currentTrack != null) {
        NotificationService.updateMusicNotification(
          title: _currentTrack!.title,
          artist: _currentTrack!.artist,
          isPlaying: s == PlayerState.playing,
        );
      } else {
        NotificationService.cancelMusicNotification();
      }
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      playNext();
    });
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      await _pullFromCloud();
      await _pullPlaylistsFromCloud();
    } catch (e) {
      developer.log('MusicPlayerProvider.load sync error: $e');
    }
    await _reloadFromLocal();
    await _reloadPlaylistsFromLocal();
    _loading = false;
    notifyListeners();
    _subscribeRealtime();
  }

  Future<void> _reloadFromLocal() async {
    final db = await DatabaseHelper().database;
    final result = await db.query(_tableName, orderBy: 'id DESC');
    _tracks = result.map((m) => MusicTrack.fromMap(Map<String, dynamic>.from(m))).toList();
  }

  Future<void> _pullFromCloud() async {
    final data = await SupabaseConfig.client
        .from(_tableName)
        .select()
        .timeout(const Duration(seconds: 10));
    final cloud = (data as List)
        .map((r) => MusicTrack.fromCloudRow(Map<String, dynamic>.from(r as Map)))
        .toList();

    final db = await DatabaseHelper().database;
    final localRows = await db.query(_tableName);
    final localByCloud = <int, MusicTrack>{};
    for (final m in localRows) {
      final t = MusicTrack.fromMap(Map<String, dynamic>.from(m));
      if (t.cloudId != null) localByCloud[t.cloudId!] = t;
    }

    for (final c in cloud) {
      if (c.cloudId == null) continue;
      final local = localByCloud[c.cloudId!];
      if (local == null) {
        await db.insert(_tableName, c.toMap());
      }
    }
  }

  // --- BÚSQUEDA Y SUBIDA A SUPABASE CON COLA SECUENCIAL ---

  Future<List<YouTubeSearchResult>> searchYouTube(String query) async {
    return await _downloadService.search(query);
  }

  /// Añade una canción a la cola de descargas. Si ya existe en la biblioteca
  /// compartida o ya se encuentra en cola/descargando, devuelve false.
  bool addToDownloadQueue(YouTubeSearchResult result) {
    // Si ya existe guardada en la biblioteca
    if (_tracks.any((t) => t.youtubeId == result.id)) {
      return false;
    }

    // Si ya está en la cola activa
    final existing = getQueueItem(result.id);
    if (existing != null) {
      if (existing.isDownloading || existing.isQueued) {
        return false;
      }
      // Si falló anteriormente, se remueve para re-encolar limpia
      _downloadQueue.remove(existing);
    }

    final newItem = DownloadQueueItem(searchResult: result);
    _downloadQueue.add(newItem);
    notifyListeners();

    _processQueue();
    return true;
  }

  /// Remueve una canción de la cola (si aún no empezó a descargarse)
  void removeFromQueue(String youtubeId) {
    _downloadQueue.removeWhere((i) => i.id == youtubeId && !i.isDownloading);
    notifyListeners();
  }

  /// Reintenta una descarga que falló
  void retryDownload(String youtubeId) {
    final item = getQueueItem(youtubeId);
    if (item != null && item.isFailed) {
      item.status = DownloadItemStatus.queued;
      item.progress = 0.0;
      item.statusMessage = 'En cola...';
      item.errorMessage = null;
      notifyListeners();
      _processQueue();
    }
  }

  /// Limpia de la lista visual las descargas completadas o fallidas
  void clearFinishedDownloads() {
    _downloadQueue.removeWhere((i) => i.isCompleted || i.isFailed || i.isCancelled);
    notifyListeners();
  }

  /// Procesa secuencialmente los elementos encolados uno a uno para garantizar
  /// que ninguna descarga se pierda ni se bloquee por concurrencia.
  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (true) {
      final nextIdx = _downloadQueue.indexWhere((i) => i.isQueued);
      if (nextIdx == -1) break;

      final currentItem = _downloadQueue[nextIdx];
      currentItem.status = DownloadItemStatus.downloading;
      currentItem.progress = 0.05;
      currentItem.statusMessage = 'Iniciando extracción...';

      _isDownloading = true;
      _downloadProgress = 0.05;
      _downloadStatus = 'Descargando: ${currentItem.title}';
      _lastDownloadError = null;
      notifyListeners();

      try {
        final track = await _downloadService.downloadAndUploadTrack(
          currentItem.searchResult,
          onProgress: (p, s) {
            currentItem.progress = p;
            currentItem.statusMessage = s;
            _downloadProgress = p;
            _downloadStatus = '${currentItem.title} ($s)';
            notifyListeners();
          },
        );

        if (track != null) {
          currentItem.status = DownloadItemStatus.completed;
          currentItem.progress = 1.0;
          currentItem.statusMessage = '¡Guardada en Supabase!';
          currentItem.savedTrack = track;
          await _reloadFromLocal();

          // Notificación flotante in-app (visible en cualquier pantalla de F.U.R.I)
          NotificationService.showInAppNotification(InAppNotificationItem(
            title: 'Música guardada',
            body: '¡"${currentItem.title}" ya está disponible en la música compartida!',
            data: {'type': 'music'},
          ));
        } else {
          currentItem.status = DownloadItemStatus.failed;
          currentItem.errorMessage = 'No se pudo guardar la canción';
          currentItem.statusMessage = 'Error al guardar';
        }
      } catch (e) {
        developer.log('MusicPlayerProvider._processQueue error en ${currentItem.title}: $e');
        currentItem.status = DownloadItemStatus.failed;
        final cleanMsg = e.toString().replaceAll('Exception: ', '');
        currentItem.errorMessage = cleanMsg;
        currentItem.statusMessage = 'Error: $cleanMsg';
        _lastDownloadError = cleanMsg;
      } finally {
        notifyListeners();
      }
    }

    _isDownloading = false;
    _downloadProgress = 0.0;
    _downloadStatus = '';
    _isProcessingQueue = false;
    notifyListeners();
  }

  /// Método compatible que encola y aguarda la descarga individual
  Future<MusicTrack?> downloadTrack(YouTubeSearchResult result) async {
    final existing = _tracks.where((t) => t.youtubeId == result.id).firstOrNull;
    if (existing != null) return existing;

    addToDownloadQueue(result);

    while (true) {
      final item = getQueueItem(result.id);
      if (item == null) return null;
      if (item.isCompleted) return item.savedTrack;
      if (item.isFailed || item.isCancelled) return null;
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  // --- DESCARGA A DEMANDA (OFFLINE) ---

  /// Descarga el archivo de audio localmente para reproducción sin internet
  Future<bool> downloadTrackLocally(MusicTrack track) async {
    if (track.audioUrl.isEmpty) return false;
    final trackId = track.id ?? track.cloudId ?? 0;
    _localDownloadingIds.add(trackId);
    notifyListeners();

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final ext = track.audioUrl.contains('.mp4') || track.audioUrl.contains('.m4a') ? 'm4a' : 'mp3';
      final fileName = 'furi_offline_${track.cloudId ?? track.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final localFile = File('${docsDir.path}/$fileName');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(Uri.parse(track.audioUrl));
      final res = await req.close();
      if (res.statusCode != 200 && res.statusCode != 206) {
        client.close();
        return false;
      }

      final sink = localFile.openWrite();
      await for (final chunk in res) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();
      client.close();

      final updated = track.copyWith(localPath: localFile.path);
      final idx = _tracks.indexWhere((t) => t.id == track.id);
      if (idx != -1) {
        _tracks[idx] = updated;
      }
      if (_currentTrack?.id == track.id) {
        _currentTrack = updated;
      }

      final db = await DatabaseHelper().database;
      await db.update(
        _tableName,
        {'local_path': localFile.path},
        where: 'id = ?',
        whereArgs: [track.id],
      );
      notifyListeners();
      return true;
    } catch (e) {
      developer.log('downloadTrackLocally error: $e');
      return false;
    } finally {
      _localDownloadingIds.remove(trackId);
      notifyListeners();
    }
  }

  /// Elimina la copia local de la canción para liberar espacio en el almacenamiento
  Future<void> removeLocalCopy(MusicTrack track) async {
    try {
      if (track.localPath.isNotEmpty) {
        final f = File(track.localPath);
        if (await f.exists()) {
          await f.delete();
        }
      }
      final updated = track.copyWith(localPath: '');
      final idx = _tracks.indexWhere((t) => t.id == track.id);
      if (idx != -1) {
        _tracks[idx] = updated;
      }
      if (_currentTrack?.id == track.id) {
        _currentTrack = updated;
      }

      final db = await DatabaseHelper().database;
      await db.update(
        _tableName,
        {'local_path': ''},
        where: 'id = ?',
        whereArgs: [track.id],
      );
      notifyListeners();
    } catch (e) {
      developer.log('removeLocalCopy error: $e');
    }
  }

  // --- REPRODUCCIÓN ---

  Future<void> play(MusicTrack track) async {
    _currentTrack = track;
    SoundService.isMusicPlaying = true;
    SoundService().stopBackgroundMusic();
    notifyListeners();

    try {
      await _player.setAudioContext(_mediaAudioContext);
      Source source;
      if (track.localPath.isNotEmpty && await File(track.localPath).exists()) {
        source = DeviceFileSource(track.localPath);
      } else if (track.audioUrl.isNotEmpty) {
        source = UrlSource(track.audioUrl);
      } else {
        developer.log('MusicPlayerProvider play: sin fuente de audio');
        return;
      }

      await _player.stop();
      await _player.play(source);
    } catch (e) {
      developer.log('MusicPlayerProvider.play error: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.setAudioContext(_mediaAudioContext);
    SoundService.isMusicPlaying = true;
    SoundService().stopBackgroundMusic();
    await _player.resume();
  }

  Future<void> togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
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
    await _player.stop();
    _currentTrack = null;
    _position = Duration.zero;
    SoundService.isMusicPlaying = false;
    NotificationService.cancelMusicNotification();
    notifyListeners();
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  void playNext() {
    final list = _currentPlaylist != null ? getTracksForPlaylist(_currentPlaylist!) : _tracks;
    if (list.isEmpty || _currentTrack == null) return;
    final idx = list.indexWhere((t) => t.id == _currentTrack!.id);
    if (idx != -1 && idx + 1 < list.length) {
      play(list[idx + 1]);
    } else if (list.isNotEmpty) {
      play(list.first);
    }
  }

  void playPrevious() {
    final list = _currentPlaylist != null ? getTracksForPlaylist(_currentPlaylist!) : _tracks;
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
      await db.update(
        _tableName,
        {'is_favorite': newFav ? 1 : 0},
        where: 'id = ?',
        whereArgs: [track.id],
      );

      if (track.cloudId != null) {
        await SupabaseConfig.client
            .from(_tableName)
            .update({'is_favorite': newFav})
            .eq('id', track.cloudId!);
      }
    } catch (e) {
      developer.log('MusicPlayerProvider.toggleFavorite error: $e');
    }
  }

  Future<void> deleteTrack(MusicTrack track) async {
    if (_currentTrack?.id == track.id) {
      await stop();
    }
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

  // --- PLAYLISTS ---

  Future<void> _pullPlaylistsFromCloud() async {
    try {
      final data = await SupabaseConfig.client
          .from('music_playlists')
          .select()
          .order('id', ascending: false)
          .timeout(const Duration(seconds: 10));
      final cloud = (data as List)
          .map((r) => MusicPlaylist.fromCloudRow(Map<String, dynamic>.from(r as Map)))
          .toList();

      final db = await DatabaseHelper().database;
      for (final p in cloud) {
        if (p.cloudId == null) continue;
        final existing = await db.query('music_playlists', where: 'cloud_id = ?', whereArgs: [p.cloudId]);
        if (existing.isEmpty) {
          await db.insert('music_playlists', p.toMap());
        } else {
          await db.update('music_playlists', p.toMap(), where: 'cloud_id = ?', whereArgs: [p.cloudId]);
        }
      }
    } catch (e) {
      developer.log('_pullPlaylistsFromCloud error: $e');
    }
  }

  Future<void> _reloadPlaylistsFromLocal() async {
    final db = await DatabaseHelper().database;
    final rows = await db.query('music_playlists', orderBy: 'id DESC');
    _playlists = rows.map((r) => MusicPlaylist.fromMap(Map<String, dynamic>.from(r))).toList();
    notifyListeners();
  }

  Future<MusicPlaylist?> createPlaylist(String title, [String description = '']) async {
    if (title.trim().isEmpty) return null;
    final rawIdentity = AppState.identity;
    final user = (rawIdentity != null && rawIdentity.isNotEmpty) ? rawIdentity : 'Facu';
    final now = DateTime.now().toIso8601String();

    try {
      final res = await SupabaseConfig.client
          .from('music_playlists')
          .insert({
            'title': title.trim(),
            'description': description.trim(),
            'created_by': user,
            'track_ids': [],
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      final playlist = MusicPlaylist.fromCloudRow(Map<String, dynamic>.from(res));
      final db = await DatabaseHelper().database;
      final localId = await db.insert('music_playlists', playlist.toMap());
      final saved = playlist.copyWith(id: localId);

      _playlists.insert(0, saved);
      notifyListeners();
      return saved;
    } catch (e) {
      developer.log('createPlaylist error: $e');
      return null;
    }
  }

  Future<void> toggleTrackInPlaylist(MusicPlaylist playlist, int trackIdentifier) async {
    final nextIds = List<int>.from(playlist.trackIds);
    if (nextIds.contains(trackIdentifier)) {
      nextIds.remove(trackIdentifier);
    } else {
      nextIds.add(trackIdentifier);
    }

    final updated = playlist.copyWith(trackIds: nextIds);
    final idx = _playlists.indexWhere((p) => p.id == playlist.id || (p.cloudId != null && p.cloudId == playlist.cloudId));
    if (idx != -1) {
      _playlists[idx] = updated;
      notifyListeners();
    }

    try {
      final db = await DatabaseHelper().database;
      if (playlist.id != null) {
        await db.update('music_playlists', updated.toMap(), where: 'id = ?', whereArgs: [playlist.id]);
      }

      if (playlist.cloudId != null) {
        await SupabaseConfig.client
            .from('music_playlists')
            .update({
              'track_ids': nextIds,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', playlist.cloudId!);
      }
    } catch (e) {
      developer.log('toggleTrackInPlaylist error: $e');
    }
  }

  Future<void> deletePlaylist(MusicPlaylist playlist) async {
    _playlists.removeWhere((p) => p.id == playlist.id && p.cloudId == playlist.cloudId);
    if (_currentPlaylist?.cloudId == playlist.cloudId || _currentPlaylist?.id == playlist.id) {
      _currentPlaylist = null;
    }
    notifyListeners();

    try {
      final db = await DatabaseHelper().database;
      if (playlist.id != null) {
        await db.delete('music_playlists', where: 'id = ?', whereArgs: [playlist.id]);
      }
      if (playlist.cloudId != null) {
        await SupabaseConfig.client.from('music_playlists').delete().eq('id', playlist.cloudId!);
      }
    } catch (e) {
      developer.log('deletePlaylist error: $e');
    }
  }

  void playPlaylist(MusicPlaylist playlist, [int startIndex = 0]) {
    _currentPlaylist = playlist;
    final playlistTracks = getTracksForPlaylist(playlist);
    if (playlistTracks.isNotEmpty) {
      final trackToPlay = (startIndex >= 0 && startIndex < playlistTracks.length)
          ? playlistTracks[startIndex]
          : playlistTracks.first;
      play(trackToPlay);
    }
  }

  List<MusicTrack> getTracksForPlaylist(MusicPlaylist playlist) {
    return _tracks.where((t) {
      final cid = t.cloudId;
      final lid = t.id;
      return (cid != null && playlist.trackIds.contains(cid)) ||
             (lid != null && playlist.trackIds.contains(lid));
    }).toList();
  }

  // --- COMENTARIOS ---

  List<MusicComment> getCommentsForTrack(int trackId) {
    return _commentsByTrack[trackId] ?? [];
  }

  Future<void> loadComments(int trackId) async {
    if (_loadingCommentsForTrack.contains(trackId)) return;
    _loadingCommentsForTrack.add(trackId);

    try {
      final db = await DatabaseHelper().database;
      final local = await db.query('music_comments', where: 'track_id = ?', whereArgs: [trackId], orderBy: 'id ASC');
      _commentsByTrack[trackId] = local.map((m) => MusicComment.fromMap(m)).toList();
      notifyListeners();

      final cloudData = await SupabaseConfig.client
          .from('music_comments')
          .select()
          .eq('track_id', trackId)
          .order('id', ascending: true);

      final cloudComments = (cloudData as List)
          .map((r) => MusicComment.fromCloudRow(Map<String, dynamic>.from(r as Map)))
          .toList();

      _commentsByTrack[trackId] = cloudComments;
      notifyListeners();
    } catch (e) {
      developer.log('loadComments error: $e');
    } finally {
      _loadingCommentsForTrack.remove(trackId);
    }
  }

  Future<void> addComment(int trackId, String content) async {
    if (content.trim().isEmpty) return;
    final rawIdentity = AppState.identity;
    final user = (rawIdentity != null && rawIdentity.isNotEmpty) ? rawIdentity : 'Facu';
    final now = DateTime.now().toIso8601String();

    try {
      final res = await SupabaseConfig.client
          .from('music_comments')
          .insert({
            'track_id': trackId,
            'user_id': user,
            'content': content.trim(),
            'created_at': now,
          })
          .select()
          .single();

      final comment = MusicComment.fromCloudRow(Map<String, dynamic>.from(res));
      final list = _commentsByTrack[trackId] ?? [];
      _commentsByTrack[trackId] = [...list, comment];
      notifyListeners();

      final db = await DatabaseHelper().database;
      await db.insert('music_comments', comment.toMap());
    } catch (e) {
      developer.log('addComment error: $e');
    }
  }

  Future<void> deleteComment(MusicComment comment) async {
    try {
      final list = _commentsByTrack[comment.trackId] ?? [];
      _commentsByTrack[comment.trackId] = list
          .where((c) => (comment.cloudId != null ? c.cloudId != comment.cloudId : c.id != comment.id))
          .toList();
      notifyListeners();

      if (comment.cloudId != null) {
        await SupabaseConfig.client.from('music_comments').delete().eq('id', comment.cloudId!);
      }
      final db = await DatabaseHelper().database;
      if (comment.id != null) {
        await db.delete('music_comments', where: 'id = ?', whereArgs: [comment.id]);
      } else if (comment.cloudId != null) {
        await db.delete('music_comments', where: 'cloud_id = ?', whereArgs: [comment.cloudId]);
      }
    } catch (e) {
      developer.log('deleteComment error: $e');
    }
  }

  // --- REALTIME SUBSCRIPTION ---

  void _subscribeRealtime() {
    if (_realtimeUp) return;
    try {
      _channel = SupabaseConfig.client
          .channel('music_realtime_sync')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _tableName,
            callback: (payload) {
              final rec = payload.newRecord;
              if (payload.eventType == PostgresChangeEvent.insert && rec.isNotEmpty) {
                final incoming = MusicTrack.fromCloudRow(rec);
                if (incoming.cloudId != null &&
                    !_tracks.any((t) => t.cloudId == incoming.cloudId)) {
                  _tracks.insert(0, incoming);
                  notifyListeners();
                  DatabaseHelper().database.then((db) {
                    db.insert(_tableName, incoming.toMap());
                  });
                }
              } else if (payload.eventType == PostgresChangeEvent.delete) {
                final oldRec = payload.oldRecord;
                final cloudId = (oldRec['id'] as num?)?.toInt();
                if (cloudId != null) {
                  _tracks.removeWhere((t) => t.cloudId == cloudId);
                  notifyListeners();
                  DatabaseHelper().database.then((db) {
                    db.delete(_tableName, where: 'cloud_id = ?', whereArgs: [cloudId]);
                  });
                }
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'music_playlists',
            callback: (_) {
              _pullPlaylistsFromCloud();
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'music_comments',
            callback: (payload) {
              final trackId = (payload.newRecord['track_id'] ?? payload.oldRecord['track_id']) as num?;
              if (trackId != null) {
                loadComments(trackId.toInt());
              }
            },
          )
          .subscribe();
      _realtimeUp = true;
    } catch (e) {
      developer.log('MusicPlayerProvider realtime subscription error: $e');
    }
  }

  @override
  void dispose() {
    NotificationService.cancelMusicNotification();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    _player.dispose();
    _downloadService.dispose();
    _channel?.unsubscribe();
    super.dispose();
  }
}
