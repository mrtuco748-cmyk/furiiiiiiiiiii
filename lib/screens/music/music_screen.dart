import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';
import '../../models/music_playlist.dart';
import '../../models/music_track.dart';
import '../../providers/music_player_provider.dart';
import '../../services/music_download_service.dart';
import '../../widgets/tap_tile.dart';

/// Pantalla del Reproductor de Música compartida de F.U.R.I.
/// Soporta:
/// 1. Biblioteca colaborativa y streaming desde la nube
/// 2. Descarga local a demanda para reproducción sin conexión (offline)
/// 3. Comentarios y notas compartidas entre Facu y Rocío en cada canción
/// 4. Creación y gestión colaborativa de Playlists
/// 5. Búsqueda y extracción directa desde YouTube
class MusicScreen extends StatefulWidget {
  final int initialTab;
  const MusicScreen({super.key, this.initialTab = 0});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  late int _currentTab;
  final TextEditingController _searchCtrl = TextEditingController();
  List<YouTubeSearchResult> _searchResults = [];
  bool _isSearching = false;

  // Filtro de playlist seleccionada en la vista de biblioteca
  MusicPlaylist? _selectedPlaylistFilter;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MusicPlayerProvider>().load();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);

    final results = await context.read<MusicPlayerProvider>().searchYouTube(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerPv = context.watch<MusicPlayerProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(playerPv),
            _buildTabs(),
            if (playerPv.isDownloading) _buildDownloadProgressBar(playerPv),
            Expanded(
              child: _buildCurrentTabContent(playerPv),
            ),
            if (playerPv.currentTrack != null)
              _buildBottomPlayer(playerPv),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(MusicPlayerProvider playerPv) {
    switch (_currentTab) {
      case 0:
        return _buildLibraryTab(playerPv);
      case 1:
        return _buildPlaylistsTab(playerPv);
      case 2:
      default:
        return _buildSearchTab(playerPv);
    }
  }

  Widget _buildHeader(MusicPlayerProvider pv) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          TapTile(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Icon(Icons.headphones, color: Color(0xFF39FF14), size: 28),
          const SizedBox(width: 10),
          Text(
            'MÚSICA',
            style: GoogleFonts.bangers(
              color: Colors.white,
              fontSize: 24,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${pv.tracks.length} temas',
              style: GoogleFonts.bangers(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              title: 'TEMAS',
              icon: Icons.library_music,
              active: _currentTab == 0,
              color: const Color(0xFF9D00FF),
              onTap: () => setState(() => _currentTab = 0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              title: 'PLAYLISTS',
              icon: Icons.playlist_play,
              active: _currentTab == 1,
              color: const Color(0xFF00D4FF),
              onTap: () => setState(() => _currentTab = 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _tabButton(
              title: 'BUSCAR',
              icon: Icons.search,
              active: _currentTab == 2,
              color: const Color(0xFFFF0033),
              onTap: () => setState(() => _currentTab = 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String title,
    required IconData icon,
    required bool active,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bg = active ? color : const Color(0xFF161616);
    return TapTile(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 17),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.bangers(
                color: Colors.white,
                fontSize: 14,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadProgressBar(MusicPlayerProvider pv) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Color(0xFF39FF14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pv.downloadStatus,
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(pv.downloadProgress * 100).toInt()}%',
                style: GoogleFonts.bangers(color: const Color(0xFF39FF14), fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pv.downloadProgress,
              backgroundColor: const Color(0xFF222222),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF39FF14)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // --- PESTAÑA: BIBLIOTECA ---

  Widget _buildLibraryTab(MusicPlayerProvider pv) {
    if (pv.loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF9D00FF)),
      );
    }

    final tracks = _selectedPlaylistFilter != null
        ? pv.getTracksForPlaylist(_selectedPlaylistFilter!)
        : pv.tracks;

    return Column(
      children: [
        if (_selectedPlaylistFilter != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.playlist_play, color: Color(0xFF00D4FF), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'PLAYLIST: ${_selectedPlaylistFilter!.title.toUpperCase()}',
                    style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TapTile(
                  onTap: () => setState(() => _selectedPlaylistFilter = null),
                  child: const Icon(Icons.close, color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),
        Expanded(
          child: tracks.isEmpty
              ? _buildEmptyLibraryState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  itemCount: tracks.length,
                  itemBuilder: (ctx, i) {
                    final track = tracks[i];
                    return _buildTrackCard(track, pv);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyLibraryState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.music_off, color: Colors.white24, size: 56),
          const SizedBox(height: 14),
          Text(
            _selectedPlaylistFilter != null
                ? 'Esta playlist no tiene canciones todavía'
                : 'No hay canciones en la biblioteca',
            style: GoogleFonts.bangers(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 6),
          const Text(
            'Busca temas en YouTube para agregarlos a la biblioteca',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TapTile(
            onTap: () => setState(() {
              _selectedPlaylistFilter = null;
              _currentTab = 2;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0033),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'BUSCAR EN YOUTUBE',
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(MusicTrack track, MusicPlayerProvider pv) {
    final isPlayingThis = pv.currentTrack?.id == track.id;
    final isFacu = track.addedBy.toLowerCase().contains('facu');
    final authorColor = isFacu ? const Color(0xFF00D4FF) : const Color(0xFFFF1493);
    final authorInitial = isFacu ? 'F' : 'R';
    final trackId = track.id ?? track.cloudId ?? 0;
    final isDownloadingLocal = pv.localDownloadingIds.contains(trackId);
    final hasLocal = track.localPath.isNotEmpty && File(track.localPath).existsSync();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isPlayingThis ? const Color(0xFF261238) : const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 4, 8, 0),
            onTap: () {
              HapticFeedback.selectionClick();
              pv.play(track);
            },
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: track.thumbnailUrl.isNotEmpty
                  ? Image.network(
                      track.thumbnailUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => _fallbackCover(),
                    )
                  : _fallbackCover(),
            ),
            title: Text(
              track.title,
              style: GoogleFonts.bangers(
                color: isPlayingThis ? const Color(0xFF39FF14) : Colors.white,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    track.artist,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(color: authorColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text(
                    authorInitial,
                    style: GoogleFonts.bangers(
                      color: const Color(0xFF111111),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  track.durationFormatted,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            trailing: TapTile(
              onTap: () => pv.toggleFavorite(track),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  track.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: track.isFavorite ? const Color(0xFFFF5757) : Colors.white38,
                  size: 22,
                ),
              ),
            ),
          ),
          // Barra de acciones secundarias de la canción
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                // 1. Descarga offline
                TapTile(
                  onTap: isDownloadingLocal
                      ? () {}
                      : () async {
                          if (hasLocal) {
                            _showOfflineSheet(track, pv);
                          } else {
                            HapticFeedback.selectionClick();
                            final ok = await pv.downloadTrackLocally(track);
                            if (mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF0D6B15),
                                  content: Text(
                                    'Descargada para escuchar sin conexión',
                                    style: GoogleFonts.bangers(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasLocal ? const Color(0xFF1A2B1C) : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        if (isDownloadingLocal)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF39FF14),
                            ),
                          )
                        else
                          Icon(
                            hasLocal ? Icons.check_circle : Icons.download,
                            color: hasLocal ? const Color(0xFF39FF14) : Colors.white60,
                            size: 15,
                          ),
                        const SizedBox(width: 4),
                        Text(
                          hasLocal ? 'OFFLINE' : 'DESCARGAR',
                          style: GoogleFonts.bangers(
                            color: hasLocal ? const Color(0xFF39FF14) : Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 2. Comentarios
                TapTile(
                  onTap: () => _showCommentsSheet(track, pv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Color(0xFF00D4FF), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'COMENTAR',
                          style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 3. Playlists
                TapTile(
                  onTap: () => _showAddToPlaylistSheet(track, pv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.playlist_add, color: Color(0xFFE040FB), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          '+ PLAYLIST',
                          style: GoogleFonts.bangers(color: const Color(0xFFE040FB), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // 4. Opciones / Eliminar
                TapTile(
                  onTap: () => _showTrackOptions(track, pv),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Icon(Icons.more_horiz, color: Colors.white38, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- PESTAÑA: PLAYLISTS ---

  Widget _buildPlaylistsTab(MusicPlayerProvider pv) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'PLAYLISTS DE LA PAREJA',
                  style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
                ),
              ),
              TapTile(
                onTap: () => _showCreatePlaylistDialog(pv),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, color: Color(0xFF111111), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'NUEVA',
                        style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: pv.playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.queue_music, color: Colors.white24, size: 56),
                      const SizedBox(height: 14),
                      Text(
                        'No hay playlists creadas todavía',
                        style: GoogleFonts.bangers(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Crea playlists compartidas para viajes, entrenamientos o momentos juntos',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TapTile(
                        onTap: () => _showCreatePlaylistDialog(pv),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+ CREAR PRIMERA PLAYLIST',
                            style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: pv.playlists.length,
                  itemBuilder: (ctx, i) {
                    final playlist = pv.playlists[i];
                    final playlistTracks = pv.getTracksForPlaylist(playlist);
                    final isFacu = playlist.createdBy.toLowerCase().contains('facu');
                    final authorColor = isFacu ? const Color(0xFF00D4FF) : const Color(0xFFFF1493);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.playlist_play, color: Color(0xFF00D4FF), size: 28),
                            ),
                            title: Text(
                              playlist.title,
                              style: GoogleFonts.bangers(color: Colors.white, fontSize: 17),
                            ),
                            subtitle: Text(
                              playlist.description.isNotEmpty
                                  ? playlist.description
                                  : 'Creada por ${playlist.createdBy}',
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TapTile(
                                  onTap: playlistTracks.isEmpty
                                      ? () {}
                                      : () {
                                          HapticFeedback.heavyImpact();
                                          pv.playPlaylist(playlist);
                                        },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: playlistTracks.isNotEmpty
                                          ? const Color(0xFF39FF14)
                                          : const Color(0xFF222222),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: playlistTracks.isNotEmpty
                                          ? const Color(0xFF0A0A0A)
                                          : Colors.white38,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TapTile(
                                  onTap: () => _showPlaylistMenu(playlist, pv),
                                  child: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                                ),
                              ],
                            ),
                          ),
                          // Barra inferior de la tarjeta de playlist
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${playlistTracks.length} canciones',
                                    style: GoogleFonts.bangers(color: Colors.white70, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1E1E),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    playlist.createdBy,
                                    style: GoogleFonts.bangers(color: authorColor, fontSize: 12),
                                  ),
                                ),
                                const Spacer(),
                                TapTile(
                                  onTap: () {
                                    setState(() {
                                      _selectedPlaylistFilter = playlist;
                                      _currentTab = 0; // Cambiar a la vista de canciones
                                    });
                                  },
                                  child: Text(
                                    'VER TEMAS →',
                                    style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- PESTAÑA: BÚSQUEDA YOUTUBE ---

  Widget _buildSearchTab(MusicPlayerProvider pv) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Buscar canción o artista...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFFF0033)),
                    filled: true,
                    fillColor: const Color(0xFF161616),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TapTile(
                onTap: _performSearch,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0033),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'BUSCAR',
                    style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isSearching)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF0033)),
            ),
          )
        else if (_searchResults.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'Escribe algo para buscar en YouTube',
                style: GoogleFonts.bangers(color: Colors.white38, fontSize: 16),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _searchResults.length,
              itemBuilder: (ctx, i) {
                final item = _searchResults[i];
                final isAlreadySaved = pv.tracks.any((t) => t.youtubeId == item.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.thumbnailUrl.isNotEmpty
                            ? Image.network(
                                item.thumbnailUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => _fallbackCover(),
                              )
                            : _fallbackCover(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.author} • ${item.durationFormatted}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TapTile(
                        onTap: (isAlreadySaved || pv.isDownloading)
                            ? () {}
                            : () async {
                                HapticFeedback.heavyImpact();
                                final saved = await pv.downloadTrack(item);
                                if (!mounted) return;
                                if (saved != null) {
                                   setState(() => _currentTab = 0);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF0D6B15),
                                      content: Text(
                                        '¡"${item.title}" guardada en Supabase!',
                                        style: GoogleFonts.bangers(color: Colors.white),
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF7A1414),
                                      content: Text(
                                        'No se pudo guardar: ${pv.lastDownloadError ?? "Error de red"}',
                                        style: GoogleFonts.bangers(color: Colors.white),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAlreadySaved
                                ? const Color(0xFF222222)
                                : const Color(0xFF39FF14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isAlreadySaved ? 'GUARDADO' : 'GUARDAR',
                            style: GoogleFonts.bangers(
                              color: isAlreadySaved ? Colors.white38 : const Color(0xFF0A0A0A),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- REPRODUCTOR INFERIOR ---

  Widget _buildBottomPlayer(MusicPlayerProvider pv) {
    final track = pv.currentTrack!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider de progreso
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: const Color(0xFF39FF14),
              inactiveTrackColor: const Color(0xFF2A2A2A),
              thumbColor: const Color(0xFF39FF14),
            ),
            child: Slider(
              value: pv.position.inSeconds.toDouble().clamp(0.0, pv.duration.inSeconds.toDouble()),
              max: pv.duration.inSeconds > 0 ? pv.duration.inSeconds.toDouble() : 1.0,
              onChanged: (val) {
                pv.seek(Duration(seconds: val.toInt()));
              },
            ),
          ),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: track.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        track.thumbnailUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => _fallbackCover(),
                      )
                    : _fallbackCover(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: GoogleFonts.bangers(color: Colors.white, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_formatDuration(pv.position)} / ${_formatDuration(pv.duration)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              TapTile(
                onTap: () => _showCommentsSheet(track, pv),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.chat_bubble_outline, color: Color(0xFF00D4FF), size: 22),
                ),
              ),
              const SizedBox(width: 4),
              TapTile(
                onTap: pv.playPrevious,
                child: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 6),
              TapTile(
                onTap: () {
                  HapticFeedback.selectionClick();
                  pv.isPlaying ? pv.pause() : pv.resume();
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF39FF14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pv.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: const Color(0xFF0A0A0A),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TapTile(
                onTap: pv.playNext,
                child: const Icon(Icons.skip_next, color: Colors.white, size: 28),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MODAL: COMENTARIOS Y NOTAS DE LA CANCIÓN ---

  void _showCommentsSheet(MusicTrack track, MusicPlayerProvider pv) {
    final trackId = track.cloudId ?? track.id ?? 0;
    pv.loadComments(trackId);
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera del modal
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: track.thumbnailUrl.isNotEmpty
                          ? Image.network(
                              track.thumbnailUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => _fallbackCover(),
                            )
                          : _fallbackCover(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Comentarios de Facu y Rocío',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TapTile(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close, color: Colors.white70, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFF222222), height: 1),
                const SizedBox(height: 10),
                // Lista de comentarios
                Expanded(
                  child: Consumer<MusicPlayerProvider>(
                    builder: (context, provider, _) {
                      final comments = provider.getCommentsForTrack(trackId);
                      if (comments.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline, color: Colors.white24, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Aún no hay comentarios en este tema',
                                style: GoogleFonts.bangers(color: Colors.white38, fontSize: 14),
                              ),
                              const Text(
                                '¡Dejale una nota o dedicatoria a tu pareja!',
                                style: TextStyle(color: Colors.white24, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (c, idx) {
                          final com = comments[idx];
                          final isFacu = com.userId.toLowerCase().contains('facu');
                          final authorColor = isFacu ? const Color(0xFF00D4FF) : const Color(0xFFFF1493);
                          final currentId = AppState.identity ?? 'Facu';
                          final isOwn = com.userId.toLowerCase() == currentId.toLowerCase();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: authorColor,
                                  child: Text(
                                    isFacu ? 'F' : 'R',
                                    style: GoogleFonts.bangers(
                                      color: const Color(0xFF111111),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        com.userId,
                                        style: GoogleFonts.bangers(color: authorColor, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        com.content,
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwn)
                                  TapTile(
                                    onTap: () => provider.deleteComment(com),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4.0),
                                      child: Icon(Icons.delete_outline, color: Colors.white38, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Input para nuevo comentario
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Escribí un comentario o dedicatoria...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFF1E1E1E),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TapTile(
                        onTap: () {
                          final text = commentCtrl.text.trim();
                          if (text.isNotEmpty) {
                            pv.addComment(trackId, text);
                            commentCtrl.clear();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D4FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.send, color: Color(0xFF111111), size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- MODAL: AGREGAR / QUITAR DE PLAYLIST ---

  void _showAddToPlaylistSheet(MusicTrack track, MusicPlayerProvider pv) {
    final trackIdentifier = track.cloudId ?? track.id ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.playlist_add, color: Color(0xFF00D4FF), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'GUARDAR EN PLAYLIST',
                        style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
                      ),
                      const Spacer(),
                      TapTile(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: Colors.white54, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (pv.playlists.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'No hay playlists creadas aún',
                          style: GoogleFonts.bangers(color: Colors.white38, fontSize: 15),
                        ),
                      ),
                    )
                  else
                    ...pv.playlists.map((pl) {
                      final inPlaylist = pl.trackIds.contains(trackIdentifier);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CheckboxListTile(
                          value: inPlaylist,
                          activeColor: const Color(0xFF00D4FF),
                          checkColor: const Color(0xFF0A0A0A),
                          title: Text(
                            pl.title,
                            style: GoogleFonts.bangers(color: Colors.white, fontSize: 16),
                          ),
                          subtitle: Text(
                            '${pl.trackIds.length} temas',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          onChanged: (_) {
                            pv.toggleTrackInPlaylist(pl, trackIdentifier);
                            setSheetState(() {});
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  TapTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      _showCreatePlaylistDialog(pv);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          '+ CREAR NUEVA PLAYLIST',
                          style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL: CREAR PLAYLIST ---

  void _showCreatePlaylistDialog(MusicPlayerProvider pv) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF141414),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'NUEVA PLAYLIST',
            style: GoogleFonts.bangers(color: const Color(0xFF00D4FF), fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Nombre de la playlist (ej: Viajes)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Descripción (opcional)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'CANCELAR',
                style: GoogleFonts.bangers(color: Colors.white54, fontSize: 14),
              ),
            ),
            TapTile(
              onTap: () {
                final title = titleCtrl.text.trim();
                if (title.isNotEmpty) {
                  pv.createPlaylist(title, descCtrl.text.trim());
                  Navigator.pop(ctx);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CREAR',
                  style: GoogleFonts.bangers(color: const Color(0xFF111111), fontSize: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // --- MODAL: OPCIONES DE PLAYLIST ---

  void _showPlaylistMenu(MusicPlaylist playlist, MusicPlayerProvider pv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                playlist.title,
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TapTile(
                onTap: () {
                  Navigator.pop(ctx);
                  pv.playPlaylist(playlist);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_arrow, color: Color(0xFF39FF14), size: 20),
                      const SizedBox(width: 12),
                      Text('REPRODUCIR PLAYLIST', style: GoogleFonts.bangers(color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TapTile(
                onTap: () {
                  Navigator.pop(ctx);
                  pv.deletePlaylist(playlist);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A0A0A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Color(0xFFFF5757), size: 20),
                      const SizedBox(width: 12),
                      Text('ELIMINAR PLAYLIST', style: GoogleFonts.bangers(color: Color(0xFFFF5757), fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- MODAL: GESTIÓN OFFLINE DE CANCIÓN ---

  void _showOfflineSheet(MusicTrack track, MusicPlayerProvider pv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF39FF14), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'DISPONIBLE SIN CONEXIÓN',
                    style: GoogleFonts.bangers(color: const Color(0xFF39FF14), fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Esta canción está descargada en el almacenamiento del dispositivo para reproducirse sin consumir datos móviles.',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TapTile(
                onTap: () {
                  Navigator.pop(ctx);
                  pv.removeLocalCopy(track);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF222222),
                      content: Text(
                        'Copia local eliminada. La canción sigue en la nube.',
                        style: GoogleFonts.bangers(color: Colors.white),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A0A0A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'ELIMINAR COPIA LOCAL (LIBERAR ESPACIO)',
                      style: GoogleFonts.bangers(color: const Color(0xFFFF5757), fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- MODAL: OPCIONES GENERALES DE CANCIÓN ---

  void _showTrackOptions(MusicTrack track, MusicPlayerProvider pv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                track.title,
                style: GoogleFonts.bangers(color: Colors.white, fontSize: 18),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              TapTile(
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddToPlaylistSheet(track, pv);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.playlist_add, color: Color(0xFF00D4FF), size: 20),
                      const SizedBox(width: 12),
                      Text('AGREGAR A PLAYLIST', style: GoogleFonts.bangers(color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TapTile(
                onTap: () {
                  Navigator.pop(ctx);
                  _showCommentsSheet(track, pv);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, color: Color(0xFF00D4FF), size: 20),
                      const SizedBox(width: 12),
                      Text('VER COMENTARIOS Y NOTAS', style: GoogleFonts.bangers(color: Colors.white, fontSize: 15)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TapTile(
                onTap: () {
                  Navigator.pop(ctx);
                  pv.deleteTrack(track);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A0A0A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Color(0xFFFF5757), size: 20),
                      const SizedBox(width: 12),
                      Text('ELIMINAR DE LA BIBLIOTECA', style: GoogleFonts.bangers(color: Color(0xFFFF5757), fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackCover() {
    return Container(
      width: 50,
      height: 50,
      color: const Color(0xFF222222),
      child: const Icon(Icons.music_note, color: Colors.white38),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
