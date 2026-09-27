import 'package:flutter/material.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/generic_media_grid.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/widgets/media_filter.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/models/media_with_review.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class MyReviewsPage extends StatefulWidget {
  final String? uid;
  final String? username;
  final bool hideName;

  const MyReviewsPage({super.key, required this.hideName, this.uid, this.username});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage>{
  bool _isSearching = false;
  bool _isLoading = false;
  final TextEditingController _controller = TextEditingController();
  late Future<List<MediaWithReview>> reviewsFuture;
  List<MediaWithReview> _allReviews = [];
  List<MediaWithReview> _filteredReviews = [];
  String mediaFilter = 'All';

  late final String activeUid;

  @override
  void initState() {
    super.initState();
    activeUid = widget.uid ?? UserSession.uid!;
    _loadReviews('a');
    _controller.addListener(_filterReviews);
  }

  void _loadReviews(String type) async {
    setState(() {
      _isLoading = true;
    });

    final reviews = activeUid == UserSession.uid
      ? await UserSession.getUserReviews(activeUid, type)
      : await DataService.getUserReviews(UserSession.uid!, activeUid, type);

    if (!mounted) return;

    setState(() {
      _allReviews = reviews;
      _filteredReviews = reviews;
      _isLoading = false;
    });
  }


  @override
  void dispose() {
    _controller.removeListener(_filterReviews);
    _controller.dispose();
    super.dispose();
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      mediaFilter = newFilter;
      _isSearching = false;
      _controller.clear();
    });
    context.read<TtsService>().speak("Filtering My Reviews by ${newFilter}");

    switch (newFilter) {
      case 'Books':
       _loadReviews('b');
        break;
      case 'Movies':
        _loadReviews('m');
        break;
      case 'TV Shows':
        _loadReviews('t');
        break;
      default:
        _loadReviews('a');
    }
  }

  void _filterReviews() {
    final query = _controller.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredReviews = _allReviews;
      } else {
        context.read<TtsService>().speak("Filtering My Reviews by ${query}");
        _filteredReviews = _allReviews.where((item) {
          final title = item.media.name.toLowerCase();
          return title.contains(query);
        }).toList();
      }
    });
  }


@override
Widget build(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final theme = context.watch<ThemeController>().currentTheme;

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
                    border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor, width: 2,),
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
                  ComicTitle(title: widget.username == null ? 'My Reviews' : "${widget.username}'s Reviews", size: 25),
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
                            key: const ValueKey('filtersRow'),
                            children: [
                              Expanded(
                                child: MediaFilter(
                                  key: const Key('my_reviews_filter'),
                                  selectedType: mediaFilter,
                                  onChanged: _onFilterChanged,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search),
                                key: const Key('my_reviews_search'),
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
                  else if (_filteredReviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No reviews found', 
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontFamily: theme.fontFamily)
                          )),
                    )
                  else
                  Align(
                    alignment: Alignment.topLeft,
                    key: ValueKey('${mediaFilter}_${_filteredReviews.length}'),
                    child: GridListBuilder<MediaWithReview>(
                      items: _filteredReviews,
                      cardHeight: 245,
                      itemBuilder: (context, mediaWithReview) => MediaCard(
                        key: Key('my_review_${mediaWithReview.media.name}'),
                        media: mediaWithReview.media,
                        review: mediaWithReview.review,
                        type: widget.uid == UserSession.uid ? MediaCardType.myReview : MediaCardType.friendReview,
                        hideName: widget.hideName
                      ),
                    ))
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