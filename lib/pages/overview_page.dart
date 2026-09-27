import 'package:flutter/material.dart';
import 'package:pop_media/pages/upload_page.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_controller.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/add_popup.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/widgets/static_star_rating.dart';
import 'package:pop_media/models/review.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/widgets/review_card.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/widgets/text_popup.dart';
import 'package:provider/provider.dart';
import 'media_review_page.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/widgets/media_section.dart';
import 'package:pop_media/widgets/comic_title.dart';

class OverviewPage extends StatefulWidget {
  final Media media;

  const OverviewPage({super.key, required this.media});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  bool expanded = false;
  late Future<List<Media>> _bookRecFuture;
  late Future<List<Media>> _movieRecFuture;
  late Future<List<Media>> _tvRecFuture;
  late Future<List<Review>> _reviewsFuture;
  String mediaIcon = 'assets/icons/book.png';

  @override
  void initState() {
    super.initState();
    _bookRecFuture = DataService.getRecForMedia(widget.media.id, 'b');
    _movieRecFuture = DataService.getRecForMedia(widget.media.id, 'm');
    _tvRecFuture = DataService.getRecForMedia(widget.media.id, 't');
    _reviewsFuture = DataService.getMediaReviews(UserSession.uid!, widget.media.id, "", false);

    if(widget.media.type == 'Movie'){
      mediaIcon = 'assets/icons/movie.png';
    }
    else if(widget.media.type == 'Tv'){
      mediaIcon = 'assets/icons/tv.png';
    }
  }

  void _addPopUp() async{
    if(!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddPopup(
        media: widget.media,
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return MainScaffold(
      currentIndex: null, 
      body: LayoutBuilder(
        builder: (context, constraints){
          final width = constraints.maxWidth;
          final isDesktop = width >= 680;
          if(isDesktop){
            return _buildWebLayout(context);
          }
          else{
            return _buildMobileLayout(context);
          }
        }
      )
    );
  }

Widget _buildMobileLayout(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final theme = context.watch<ThemeController>().currentTheme;

  return SingleChildScrollView(
    child: Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.4,
            child: Image.asset(
              theme.subBackgroundImageTwo,
              width: double.infinity,
              height: 700,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 5, 4, 0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- POSTER ----------
                  Card(
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: screenWidth * 0.35,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: Image.network(
                          widget.media.image,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ---------- MEDIA INFO ----------
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: Colors.black, width: 2),
                      ),
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Consumer<TTSController>(
                                  builder: (context, ttsController, _) {
                                    if (!ttsController.ttsEnabled) return SizedBox.shrink();
                                    return IconButton(
                                      icon: Icon(Icons.volume_up),
                                      onPressed: () {
                                        context.read<TtsService>().speak("${widget.media.name}, ${widget.media.type}, Released: ${widget.media.date}, ${widget.media.genre}, Creator: ${widget.media.creator}, Overall Rating: ${widget.media.rate}");
                                      },
                                    );
                                  },
                                ),
                              ),
                              Center(
                                child: Image.asset(
                                  mediaIcon,
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.accentColorTwo, width: 4),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.add, size: 30),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () {
                                      _addPopUp();
                                    },
                                  ),
                                )
                              ),
                                  ],
                                ),
                              Text(
                                  widget.media.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: theme.fontFamily,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              Text(
                                widget.media.date,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              TextPopUp(text: widget.media.genre, maxLines:2, type: "Genre", media: widget.media),
                              if(!(widget.media.id[0] == 't' && widget.media.creator == 'N/A'))...[
                                Text(
                                  widget.media.creator,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            

                          const SizedBox(height: 10),
                          widget.media.id[0] == 'b'
                              ? FutureBuilder<double>(
                                  future: DataService.getBookRating(widget.media.id),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return staticStarRating(0);
                                    }

                                    return staticStarRating(snapshot.data!);
                                  },
                                )
                              : staticStarRating(widget.media.rate),
                          // --- SUMMARY ---
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              TextPopUp(text: widget.media.description, maxLines: 3, type: "Overview", media: widget.media)
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  ),
                  ),
                  ),
                ],
              ),

              const SizedBox(height: 5),

              // ---------- REVIEWS ----------
              MediaSection<Review>(
                title: 'Reviews',
                count: true,
                borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor,
                onNavigate: () {
                  context.read<TtsService>().speak("Opening ${widget.media.name} Reviews");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MediaReviewsPage(
                              media: widget.media),
                    ),
                  );
                },
                onNavigateUpload: () {
                  Map<String, dynamic> mediaMap = {
                    'media_id': widget.media.id,
                    'title': widget.media.name,
                    'description': widget.media.description,
                    'creator': widget.media.creator,
                    'image': widget.media.image,
                    'release_date': widget.media.date,
                    'overall_rating': widget.media.rate,
                    'genres': widget.media.genre,
                  };
                  context.read<TtsService>().speak("Opening ${widget.media.name} in Upload Page");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UploadPage(preselectedMedia: mediaMap)),
                  );
                },
                postReview: !UserSession.userReviews!.any((media) => media.media.id == widget.media.id),
                friendSection: false,
                sectionHeight: 175,
                future: _reviewsFuture, 
                backgroundImage: theme.subBackgroundImageOne,
                itemBuilder: (context, review) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8),
                    child: SizedBox(
                      width: 375,
                      height: 150,
                      child: ReviewCard(
                        media: widget.media,
                        review: review,
                        maxLines: 4,
                      ),
                    ),
                  );
                },
              ),

              const Divider(
                color: Colors.black,
                height: 10,
                thickness: 2,
                indent: 20,
                endIndent: 20,
              ),

              // ---------- RECOMMENDATIONS ----------
              Container(
                padding: const EdgeInsets.all(4),
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
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ComicTitle(
                            title: 'Recommendations',
                            size: 20),
                      ),
                    ),
                    MediaSection<Media>(
                      borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorTwo,
                      count: false,
                      title: 'Movies',
                      onNavigate: null,
                      sectionHeight: 230,
                      postReview: false,
                      friendSection: false,
                      future: _movieRecFuture,
                      backgroundImage: theme.subBackgroundImageOne,
                      itemBuilder: (context, media) {
                        return MediaCard(
                          media: media,
                          type: MediaCardType.overview,
                          hideName: false
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    MediaSection<Media>(
                      borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorThree,
                      title: 'Television',
                      count: false,
                      onNavigate: null,
                      sectionHeight: 230,
                      postReview: false,
                      friendSection: false,
                      future: _tvRecFuture,
                      backgroundImage: theme.subBackgroundImageOne,
                      itemBuilder: (context, media) {
                        return MediaCard(
                          media: media,
                          type: MediaCardType.overview,
                          hideName: false
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    MediaSection<Media>(
                      borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor,
                      title: 'Books',
                      count: false,
                      onNavigate: null,
                      sectionHeight: 230,
                      postReview: false,
                      friendSection: false,
                      future: _bookRecFuture,
                      backgroundImage: theme.subBackgroundImageOne,
                      itemBuilder: (context, media) {
                        return MediaCard(
                          media: media,
                          type: MediaCardType.overview,
                          hideName: false
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildWebLayout(BuildContext context) {
  final theme = context.watch<ThemeController>().currentTheme;

  return SingleChildScrollView(
    child: Stack(
      children: [
        // ---------- Background ----------
        Positioned.fill(
          child: Opacity(
            opacity: 0.4,
            child: Image.asset(
              theme.subBackgroundImageTwo,
              width: double.infinity,
              height: 700,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // ---------- Content ----------
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------- LEFT COLUMN ----------
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Consumer<TTSController>(
                                  builder: (context, ttsController, _) {
                                    if (!ttsController.ttsEnabled) return SizedBox.shrink();
                                    return IconButton(
                                      icon: Icon(Icons.volume_up),
                                      onPressed: () {
                                        context.read<TtsService>().speak("${widget.media.name}, ${widget.media.type}, Released: ${widget.media.date}, ${widget.media.genre}, Creator: ${widget.media.creator}, Overall Rating: ${widget.media.rate}");
                                      },
                                    );
                                  },
                                ),),
                              Center(
                                child: Image.asset(
                                  mediaIcon,
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.accentColorTwo, width: 4),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.add, size: 30),
                                    padding: EdgeInsets.zero,
                                    constraints: BoxConstraints(),
                                    onPressed: () {
                                      _addPopUp();
                                    },
                                  ),
                                )
                              ),
                            ],
                          ),
                          Text(
                            widget.media.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: theme.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(widget.media.date,
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic, fontSize: 13)),
                          if(!(widget.media.id[0] == 't' && widget.media.creator == 'N/A'))...[
                            Text(widget.media.creator,
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic, fontSize: 13)),
                          ],
                          TextPopUp(text: widget.media.genre, maxLines:2, type: "Genre", media: widget.media),
                          const SizedBox(height: 10),
                          widget.media.id[0] == 'b'
                              ? FutureBuilder<double>(
                                  future: DataService.getBookRating(widget.media.id),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return staticStarRating(0);
                                    }

                                    return staticStarRating(snapshot.data!);
                                  },
                                )
                              : staticStarRating(widget.media.rate),
                          const SizedBox(height: 8),
                          TextPopUp(text: widget.media.description, maxLines: 3, type: "Overview", media: widget.media)
                        ],
                      ),
                    ),

              const SizedBox(height: 12),
              
              SizedBox(
                      height: 885, 
                      child: Card(
                        clipBehavior: Clip.hardEdge,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: Image.network(
                            widget.media.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // ---------- RIGHT COLUMN ----------
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediaSection<Review>(
                      title: 'Reviews',
                      count: true,
                      onNavigate: () {
                        context.read<TtsService>().speak("Opening ${widget.media.name} Reviews");
                        Navigator.push(context, MaterialPageRoute(builder: (_) => MediaReviewsPage(media: widget.media)));
                      },
                      onNavigateUpload: () {
                        Map<String, dynamic> mediaMap = {
                          'media_id': widget.media.id,
                          'title': widget.media.name,
                          'description': widget.media.description,
                          'creator': widget.media.creator,
                          'image': widget.media.image,
                          'release_date': widget.media.date,
                          'overall_rating': widget.media.rate,
                          'genres': widget.media.genre,
                        };
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => UploadPage(preselectedMedia: mediaMap)),
                        );
                      },
                      borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor,
                      postReview: !UserSession.userReviews!.any((media) => media.media.id == widget.media.id),
                      friendSection: false,
                      sectionHeight: 175,
                      future: _reviewsFuture, 
                      backgroundImage: theme.subBackgroundImageOne,
                      itemBuilder: (context, review) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 375,
                            height: 150,
                            child: ReviewCard(
                              media: widget.media,
                              review: review,
                              maxLines: 4,
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(
                      color: theme.primaryColor,
                      height: 10,
                      thickness: 2,
                    ),
                    const SizedBox(height: 10),
                    Container(
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
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                            child: ComicTitle(title: 'Recommendations', size: 20),
                          ),
                          MediaSection<Media>(
                            title: 'Movies',
                            count: false, 
                            onNavigate: null,
                            borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorTwo,
                            sectionHeight: 230,
                            postReview: false,
                            friendSection: false,
                            future: _movieRecFuture,
                            backgroundImage: theme.subBackgroundImageOne,
                            itemBuilder: (context, media) {
                              return MediaCard(
                                media: media,
                                type: MediaCardType.overview,
                                hideName: false
                              );
                            },
                          ),

                    const SizedBox(height: 15),

                    MediaSection<Media>(
                      title: 'Television',
                      count: false,
                      onNavigate: null,
                      borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorTwo,
                      sectionHeight: 230,
                      postReview: false,
                      friendSection: false,
                      future: _tvRecFuture,
                      backgroundImage: theme.subBackgroundImageOne,
                      itemBuilder: (context, media) {
                        return MediaCard(
                          media: media,
                          type: MediaCardType.overview,
                          hideName: false
                        );
                      },
                    ),

                    const SizedBox(height: 15),

                    MediaSection<Media>(
                      title: 'Book',
                      count: false,
                      onNavigate: null,
                      borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorTwo,
                      sectionHeight: 230,
                      postReview: false,
                      friendSection: false,
                      future: _bookRecFuture,
                      backgroundImage: theme.subBackgroundImageOne,
                      itemBuilder: (context, media) {
                        return MediaCard(
                          media: media,
                          type: MediaCardType.overview,
                          hideName: false
                        );
                      },
                    ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}