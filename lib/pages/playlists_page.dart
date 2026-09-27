import 'package:flutter/material.dart';
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/pages/create_playlist_page.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/generic_media_grid.dart';
import 'package:pop_media/widgets/playlist_card.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class PlaylistsPage extends StatefulWidget {

  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage>{
  bool _isSearching = false;
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  List<Playlist> _allPlaylists = [];
  List<Playlist> _filteredPlaylists = [];

@override
void initState() {
  super.initState();
  _controller.addListener(_filterPlaylists);

  _isLoading = true;
  _loadPlaylists();
}

  void _loadPlaylists() async {
    setState(() {
      _isLoading = true;
    });

    final playlists = await DataService.getPlaylists(UserSession.uid!, false);

    if (!mounted) return;

    setState(() {
      _allPlaylists = playlists;
      _filteredPlaylists = playlists;
      _isLoading = false;
    });
  }

@override
void dispose() {
  _controller.removeListener(_filterPlaylists);
  _controller.dispose();
  super.dispose();
}

void _filterPlaylists() {
  final query = _controller.text.toLowerCase();

  setState(() {
    if (query.isEmpty) {
      _filteredPlaylists = _allPlaylists;
    } else {
      _filteredPlaylists = _allPlaylists.where((item) {
        final name = (item.name).toLowerCase();
        return name.contains(query);
      }).toList();
    }
  });
}


@override
Widget build(BuildContext context) {
  final theme = context.watch<ThemeController>().currentTheme;
  final screenHeight = MediaQuery.of(context).size.height;

  return MainScaffold(
    currentIndex: null,
    body: Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.4,
            child: Image.asset(
              theme.subBackgroundImageOne,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Scrollable content
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints( minHeight: screenHeight,),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Container(
                padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                    border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorTwo, width: 2,),
                    color: theme.mainBackgroundColor,
                    image: theme.mainBackgroundImage != null
                        ? DecorationImage(
                            image: AssetImage(theme.mainBackgroundImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ComicTitle(title: 'My Playlists', size: 25),
                      Spacer(),
                      TextButton(
                        onPressed: () {Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CreatePlaylistPage()),
                        );},
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: theme.accentColorTwo, width: 4),
                          ),
                        ),
                        child: Text(
                          "Add New Playlist",
                          style: TextStyle(
                            fontFamily: theme.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ]
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isSearching
                        ? TextField(
                            key: const ValueKey('searchField'),
                            controller: _controller,
                            autofocus: true,
                            style: TextStyle(color: theme.primaryColor),
                            decoration: InputDecoration(
                              hintText: 'Search My Reviews by Title',
                              hintStyle: TextStyle(color: theme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.primaryColor) 
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: theme.accentColor) 
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.close, color: theme.primaryColor),
                                onPressed: () {
                                  setState(() {
                                    _controller.clear();
                                    _isSearching = false;
                                    context.read<TtsService>().speak("Clearing Search Filter");
                                  });
                                },
                              ),
                            ),
                          )
                        : Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.search),
                                color: theme.primaryColor,
                                onPressed: () {
                                  setState(() {
                                    _isSearching = true;
                                  });
                                },
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                  else if (_filteredPlaylists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No playlists found', 
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontFamily: theme.fontFamily)
                          )),
                    )
                  else
                  Align(
                    alignment: Alignment.topLeft,
                    key: ValueKey('${_filteredPlaylists.length}'),
                    child: GridListBuilder<Playlist>(
                      items: _filteredPlaylists,
                      cardHeight: 220,
                      itemBuilder: (context, playlist) => PlaylistCard(
                        playlist: playlist,
                      ),
                    )
                  )
                ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}