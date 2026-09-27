import 'package:flutter/material.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/pages/single_playlist_page.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/ajax_search.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/generic_media_grid.dart';
import 'package:pop_media/widgets/generic_filter.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/movie.dart';
import 'package:pop_media/models/book.dart';
import 'package:pop_media/models/television.dart';
import 'package:pop_media/pages/overview_page.dart';
import 'package:pop_media/pages/profile_page.dart';
import 'package:provider/provider.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final controller = TextEditingController();
  String mediaFilter = 'All';
  String mediaChar = 'a';
  late Future<List<Media>> _trending;
  late Future<List<Media>> _recommended;

  @override
  void initState() {
    super.initState();
    _trending = UserSession.getTrending('a');
    _recommended = UserSession
    .getRecForUser(UserSession.uid!, 'a')
    .catchError((e) {
      debugPrint("Error fetching recommendations: $e");
      return <Media>[]; 
    });
  }

  void _onFilterChanged(String newFilter) {
  setState(() {
    context.read<TtsService>().speak("Filtering Search by ${newFilter}");
    mediaFilter = newFilter;
    switch(newFilter){
      case 'Books':
        mediaChar = 'b';
        break;
      case 'Movies':
        mediaChar = 'm';
        break;
      case 'TV Shows':
        mediaChar = 't';
        break;
      case 'Users':
        mediaChar = 'u';
        break;
      case 'Playlists':
        mediaChar = 'p';
        break;
      default:
        mediaChar = 'a';
    } 
  });

  final text = controller.text;
  if(text.isNotEmpty){
    controller
      ..text = text
      ..selection = TextSelection.collapsed(offset: text.length);
  }
}


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = context.watch<ThemeController>().currentTheme;

    return MainScaffold(
      currentIndex: 1,
      body: Stack(
        children: [
          Positioned.fill(
              child: theme.mainBackgroundImage != null
                  ? Opacity(
                      opacity: theme.imageOpactity,
                      child: Image.asset(
                        theme.mainBackgroundImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: theme.mainBackgroundColor,
                    ),
            ),
          SingleChildScrollView(
            child: ConstrainedBox(
            constraints: BoxConstraints( minHeight: screenHeight,),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor, width: 3),
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.9),
                          Colors.grey.shade200.withOpacity(0.9),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search field
                        Expanded(
                          child: AjaxSearchField(
                            controller: controller,
                            hintText: "Search",
                            onSearch: (query) async {
                              try {
                                final searchList =
                                    await DataService.discoverSearch(query, mediaChar);

                                context.read<TtsService>().speak("Searching for ${query}");

                                return searchList
                                    .map((item) =>
                                        Map<String, dynamic>.from(item))
                                    .toList();
                              } catch (e) {
                                debugPrint("Error fetching media: $e");
                                return [];
                              }
                            },
                            displayStringForOption: (item) {
                              if (item.containsKey('pid')) {
                                return item['name']?.toString() ?? '';
                              }
                              else if (item.containsKey('uid')) {
                                return item['username']?.toString() ?? '';
                              }
                              return item['title']?.toString() ?? '';
                            },
                            onSelected: (item) {
                              if (item.containsKey('pid')) {
                                context.read<TtsService>().speak("Opening Playlist From Search");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SinglePlaylistPage(playlist: Playlist.fromJson(item)),
                                  ),
                                );
                              } else if (item.containsKey('uid')) {
                                context.read<TtsService>().speak("Opening Profile From Search");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProfilePage(userId: item['uid'], adminAccess: false),
                                  ),
                                );
                              } else if (item['media_id'][0] == 'm') {
                                Movie movie = Movie.fromJson(item);
                                context.read<TtsService>().speak("Opening ${movie.name} Overview");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OverviewPage(media: movie),
                                  ),
                                );
                              } else if (item['media_id'][0] == 'b') {
                                Book book = Book.fromJson(item);
                                context.read<TtsService>().speak("Opening ${book.name} Overview");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OverviewPage(media: book),
                                  ),
                                );
                              } else {
                                Television tv = Television.fromJson(item);
                                context.read<TtsService>().speak("Opening ${tv.name} Overview");
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OverviewPage(
                                            media: tv),
                                  ),
                                );
                              }
                            },
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Filter (fixed position)
                        GenericFilter(
                          selectedType: mediaFilter,
                          onChanged: _onFilterChanged,
                          userShown: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    color: theme.primaryColor,
                    height: 10,
                    thickness: 2,
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorThree, width: 2),
                      image: DecorationImage(
                        image: AssetImage(theme.subBackgroundImageFour),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(0.6),
                          BlendMode.lighten,
                        ),
                      ),
                    ),
                    child: Column( 
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ComicTitle(title: 'Recommendations', size: 22),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.primaryColor, width: 2,),
                                  color: theme.mainBackgroundColor,
                                  image: theme.mainBackgroundImage != null
                                      ? DecorationImage(
                                          image: AssetImage(theme.mainBackgroundImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.arrow_forward, color: theme.primaryColor),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    context.read<TtsService>().speak("Opening Recommendations");
                                    Navigator.pushNamed(context, '/recommendationsPage');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        GridListBuilder<Media>(
                          future: _recommended,
                          cardHeight: 200,
                          maxRows: 2,
                          itemBuilder: (context, media) => MediaCard(
                            media: media,
                            type: MediaCardType.overview,
                            hideName: false
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    color: theme.primaryColor,
                    height: 10,
                    thickness: 2,
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorTwo, width: 2),
                      image: DecorationImage(
                        image: AssetImage(theme.subBackgroundImageFour),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withOpacity(0.6),
                          BlendMode.lighten,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ComicTitle(title: 'Trending', size: 22),
                            SizedBox(
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.primaryColor, width: 2,),
                                  color: theme.mainBackgroundColor,
                                  image: theme.mainBackgroundImage != null
                                      ? DecorationImage(
                                          image: AssetImage(theme.mainBackgroundImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.arrow_forward, color: theme.primaryColor),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    context.read<TtsService>().speak("Opening Trending");
                                    Navigator.pushNamed(context, '/trendingPage');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        GridListBuilder<Media>(
                          future: _trending,
                          cardHeight: 200,
                          maxRows: 2,
                          itemBuilder: (context, media) => MediaCard(
                            media: media,
                            type: MediaCardType.overview,
                            hideName: false
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: [   
                      Text(
                        "Looking For A Specific Vibe?",
                          style: TextStyle(
                            fontFamily: 'Swanky',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            letterSpacing: 1.2,
                          ),
                      ),
                    Align(
                    child: GestureDetector(
                      onTap: () {
                        context.read<TtsService>().speak("Opening Vibe Search");
                        Navigator.pushNamed(context, '/vibesPage');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: theme.gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Text(
                          'Vibe Check Media',
                          style: TextStyle(
                            fontFamily: theme.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  )
                  ],
                  ),
                ]
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}