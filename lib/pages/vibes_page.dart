import 'package:flutter/material.dart' hide Theme;
import 'package:pop_media/models/theme.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/generic_media_grid.dart';
import 'package:pop_media/widgets/generic_filter.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/widgets/wheel_select.dart';
import 'package:provider/provider.dart';

class VibesPage extends StatefulWidget {
  const VibesPage({super.key});

  @override
  State<VibesPage> createState() => _VibesPageState();
}

class _VibesPageState extends State<VibesPage> {
  final TextEditingController _controller = TextEditingController();
  String mediaFilter = 'All';
  String mediaChar = 'a';

  bool _hasSearched = false;
  String _query = "";

  // This list feeds the WheelSelect
  List<Media> _searchResults = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Perform the search: updates both the grid and the wheel list
  void _performSearch() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    
    context.read<TtsService>().speak("Searching ${_controller.text}");

    final results = await DataService.getVibeSearch(UserSession.uid!, mediaChar, query);

    setState(() {
      _query = query;
      _hasSearched = true;
      _searchResults = results;
    });
  }

  void _onFilterChanged(String newFilter) async {
    context.read<TtsService>().speak("Filtering Search By ${newFilter}");
    setState(() {
      mediaFilter = newFilter;
      switch (newFilter) {
        case 'Books':
          mediaChar = 'b';
          break;
        case 'Movies':
          mediaChar = 'm';
          break;
        case 'TV Shows':
          mediaChar = 't';
          break;
        default:
          mediaChar = 'a';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    return MainScaffold(
      currentIndex: 3,
      body: Stack(
        children: [
            Positioned.fill(
              child: _hasSearched
                  ? Opacity(
                      opacity: theme.imageOpactity,
                      child: theme.mainBackgroundImage != null
                        ? Image.asset(theme.mainBackgroundImage!, fit: BoxFit.cover)
                        : Container(color: theme.mainBackgroundColor,),
                    )
                  : Opacity(
                    opacity: 0.9,
                    child: Image.asset(theme.vibeBackgroundImage, fit: BoxFit.cover),
                  ),
            ),
          _hasSearched ? _buildResultsLayout(theme) : _buildCenteredSearch(theme),
        ],
      ),
    );
  }

  Widget _buildCenteredSearch(Theme theme) => Center(child: _buildSearchRow(theme));

  Widget _buildResultsLayout(Theme theme) {
    return Column(
        children: [
          const SizedBox(height: 5),
          _buildSearchRow(theme),
          const SizedBox(height: 5),
          Expanded(
          child: SingleChildScrollView(
            key: ValueKey('${mediaFilter}_${_query.length}'),
            child: GridListBuilder<Media>(
              future: DataService.getVibeSearch(UserSession.uid!, mediaChar, _query),
              cardHeight: 225,
              itemBuilder: (context, media) => MediaCard(
                media: media,
                type: MediaCardType.overview,
                hideName: false
              ),
            ),
          ),),
        ],
    );
  }

  Widget _buildSearchRow(Theme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 2),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.9), Colors.grey.shade200.withOpacity(0.9)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                        fontFamily: theme.fontFamily,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search the vibes...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  if (_query.isEmpty) ...[
                    _buildVibeInfo(theme),
                    TextButton(
                      onPressed: _performSearch,
                      child: const ComicTitle(title: 'Enter', size: 15),
                    ),
                  ] else ...[
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear',
                      onPressed: () {
                        _controller.clear();
                        _query = "";
                        _searchResults = [];
                        setState(() => _hasSearched = false);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            height: 40,
            child: GenericFilter(
              selectedType: mediaFilter,
              onChanged: _onFilterChanged,
              userShown: false,
            ),
          ),
          if (_hasSearched && _searchResults.isNotEmpty) ...[
            WheelSelect(media: _searchResults),
          ],
        ],
      ),
    );
  }

  Widget _buildVibeInfo(Theme theme) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 300,
              height: 300,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Text(
                      "On this page search the vibe of media you are looking for to get recommendations \n i.e. salty dog fisherman adventure",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: theme.fontFamily,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      "Close",
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: theme.fontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: const Icon(
        Icons.info_outline,
        size: 18,
        color: Colors.grey,
      ),
    );
  }
}