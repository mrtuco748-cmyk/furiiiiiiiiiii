import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/music_playlist.dart';
import '../../providers/music_player_provider.dart';
import '../../services/music_download_service.dart';
import 'modals/music_comments_sheet.dart';
import 'modals/music_download_queue_modal.dart';
import 'widgets/music_bottom_player.dart';
import 'widgets/music_header_tabs.dart';
import 'widgets/music_library_tab.dart';
import 'widgets/music_playlists_tab.dart';
import 'widgets/music_search_tab.dart';

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
  MusicPlaylist? _selectedPlaylistFilter;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MusicPlayerProvider>().load();
        context.read<MusicPlayerProvider>().setMusicScreenOpen(true);
      }
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
            MusicHeader(
              pv: playerPv,
              onOpenQueue: () => showDownloadQueueModal(context, playerPv),
            ),
            MusicTabsBar(
              currentTab: _currentTab,
              onTabSelected: (tab) => setState(() => _currentTab = tab),
            ),
            if (playerPv.isDownloading || playerPv.activeOrQueuedCount > 0)
              MusicDownloadProgressBar(
                pv: playerPv,
                onOpenQueue: () => showDownloadQueueModal(context, playerPv),
              ),
            Expanded(
              child: _buildCurrentTabContent(playerPv),
            ),
            if (playerPv.currentTrack != null)
              MusicBottomPlayer(
                pv: playerPv,
                onOpenComments: () => showCommentsSheet(context, playerPv.currentTrack!, playerPv),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(MusicPlayerProvider playerPv) {
    switch (_currentTab) {
      case 0:
        return MusicLibraryTab(
          pv: playerPv,
          selectedPlaylistFilter: _selectedPlaylistFilter,
          onClearPlaylistFilter: () => setState(() => _selectedPlaylistFilter = null),
          onSwitchToSearchTab: () => setState(() {
            _selectedPlaylistFilter = null;
            _currentTab = 2;
          }),
        );
      case 1:
        return MusicPlaylistsTab(
          pv: playerPv,
          onSelectPlaylist: (playlist) {
            setState(() {
              _selectedPlaylistFilter = playlist;
              _currentTab = 0;
            });
          },
        );
      case 2:
      default:
        return MusicSearchTab(
          searchCtrl: _searchCtrl,
          isSearching: _isSearching,
          searchResults: _searchResults,
          onSearch: _performSearch,
          pv: playerPv,
          onOpenDownloadQueue: () => showDownloadQueueModal(context, playerPv),
        );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    MusicPlayerProvider.currentInstance?.setMusicScreenOpen(false);
    super.dispose();
  }
}
