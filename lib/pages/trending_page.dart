import 'package:flutter/material.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/generic_media_grid.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/widgets/media_filter.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/wheel_select.dart';
import 'package:provider/provider.dart';

class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  bool _isLoading = false;
  late Future<List<dynamic>> reviewsFuture;
  List<Media> _filteredTrending = [];
  String mediaFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTrending('a');
  }

  void _loadTrending(String type) async {
    setState(() {
      _isLoading = true;
    });

    final trending = await UserSession.getTrending(type);

    if (!mounted) return;

    setState(() {
      _filteredTrending = trending;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      context.read<TtsService>().speak("Filtering Trending by ${newFilter}");
      mediaFilter = newFilter;
    });

    switch (newFilter) {
      case 'Books':
        _loadTrending('b');
        break;
      case 'Movies':
        _loadTrending('m');
        break;
      case 'TV Shows':
        _loadTrending('t');
        break;
      default:
        _loadTrending('a');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;

    return MainScaffold(
      currentIndex: 0,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background image fills viewport
              Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Image.asset(
                  theme.subBackgroundImageFour,
                  fit: BoxFit.cover,
                ),
              ),
            ),

              // Scrollable content with minHeight = screen height
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorThree, width: 2,),
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
                        // Title + Filter Row
                        Row(
                          children:[
                            ComicTitle(title: 'Trending Media', size: 25),
                            Spacer(),
                            if(_filteredTrending.isNotEmpty)...[
                              WheelSelect(media: _filteredTrending),
                            ]
                          ]
                        ),
                        SizedBox(height: 10),
                        MediaFilter(
                          selectedType: mediaFilter,
                          onChanged: _onFilterChanged
                        ),
                        SizedBox(height: 10),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                          else if (_filteredTrending.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No trending found', 
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontFamily: theme.fontFamily)
                                  )),
                            )
                          else
                            Align(
                            alignment: Alignment.topLeft,
                            key: ValueKey('${mediaFilter}_${_filteredTrending.length}'),
                            child: GridListBuilder<Media>(
                              future: Future.value(_filteredTrending),
                              cardHeight: 200,
                              itemBuilder: (context, media) =>
                                  MediaCard(media: media, type: MediaCardType.overview, hideName: false),
                            ),
                          ),
                      ],
                    ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
