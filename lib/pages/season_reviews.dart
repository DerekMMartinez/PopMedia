import 'package:flutter/material.dart';
import 'package:pop_media/models/season_review.dart';
import 'package:pop_media/models/television.dart';
import 'package:pop_media/pages/overview_page.dart';
import 'package:pop_media/pages/profile_page.dart';
import 'package:pop_media/text_speech/tts_controller.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/models/review.dart';
import 'package:pop_media/widgets/season_card.dart';
import 'package:pop_media/widgets/static_star_rating.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/widgets/text_popup.dart';
import 'package:provider/provider.dart';


class SeasonReviewsPage extends StatefulWidget {
  final Television media;
  final Review review;
  final MediaCardType type;


  SeasonReviewsPage({super.key, required this.media, required this.review, required this.type});




  @override
  State<SeasonReviewsPage> createState() => _SeasonReviewsPage();
}




class _SeasonReviewsPage extends State<SeasonReviewsPage> {
  late Future<List<SeasonReview>> _seasonReviewsFuture;
  late double _rating;
  late DateTime _date;
  late String _reviewText;
  late TextEditingController _reviewController = TextEditingController();
  String media_type = 'Book';

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _date = widget.review.date;
    _reviewText = widget.review.review ?? '';
    _reviewController = TextEditingController(text: _reviewText);
    _seasonReviewsFuture = DataService.getSeasonReviews(widget.review.review_id);


    if(widget.media.type == 'Tv')
      media_type = "TV";
    else if(widget.media.type == 'Movie')
      media_type = "Movie";
  }




  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 600;
          if (isDesktop) {
            return _buildWebLayout(context);
          } else {
            return _buildMobileLayout(context);
          }
        },
      ),
    );
  }


  Widget _buildMobileLayout(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final theme = context.watch<ThemeController>().currentTheme;


    return Stack(
        children: [
          // ---------- BACKGROUND ----------
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
          // ---------- CONTENT ----------
          SingleChildScrollView(
            child: ConstrainedBox(
            constraints: BoxConstraints( minHeight: screenHeight,),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 5, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- POSTER + REVIEWER INFO ----------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster image
                      InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => OverviewPage(media: widget.media)));
                      },
                      child: Card(
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
                      ),),
                      const SizedBox(width: 12),


                      // Reviewer info
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor, width: 2)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(width: 5),
                                  InkWell(
                                      onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProfilePage(userId: widget.review.uid, adminAccess: false),
                                            ),
                                          );
                                      },                                
                                      child: Text(
                                          widget.review.username,
                                          style: TextStyle(
                                            fontFamily: theme.fontFamily,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      ),
                                    ),
                                  Consumer<TTSController>(
                                    builder: (context, ttsController, _) {
                                      if (!ttsController.ttsEnabled) return SizedBox.shrink();


                                      return IconButton(
                                        icon: Icon(Icons.volume_up),
                                        onPressed: () {
                                          context.read<TtsService>().speak("${widget.review.rating} stars, reviewed on ${_date.month}/${_date.day}/${_date.year}, ${widget.review.review}");
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Text(
                                      "Overall Review: ${_date.month}/${_date.day}/${_date.year}",
                                      style: TextStyle(
                                        fontFamily: theme.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    staticStarRating(_rating, size: 35),
                                    SizedBox(height: 8),
                                    TextPopUp(
                                      text: widget.review.review != "" ? widget.review.review! : "User Did Not Leave Overall Review",
                                      maxLines: 3,
                                      type: "Seasons",
                                      review: widget.review,
                                    ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),


                  // ---------- SEASON REVIEWS ----------
                  Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          image:  DecorationImage(
                                  image: AssetImage(theme.subBackgroundImageOne),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withOpacity(0.6),
                                    BlendMode.lighten,
                                  ),
                                )
                        ),
                        child: FutureBuilder<List<SeasonReview>>(
                          future: _seasonReviewsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }


                            if (snapshot.hasError) {
                              return const Text("Error loading reviews");
                            }


                            final reviews = snapshot.data!;


                            final reviewMap = {
                              for (var r in reviews) r.season_number: r
                            };


                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < widget.media.seasonNumber; i++) ...[
                                  SeasonCard(
                                    uid: widget.review.uid,
                                    review_id: widget.review.review_id,
                                    seasonNumber: (i+1),
                                    review: reviewMap[i+1] ??
                                        SeasonReview(
                                          review_id: widget.review.review_id,
                                          season_number: i+1,
                                          rating: 0,
                                          review: null,
                                          date: DateTime.now(),
                                          spoilers: false,
                                          watched: false,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                ]
                              ],
                            );
                          },
                        )
                      ),
                ],
              ),
            ),
          ),
          ),
        ],
      );
  }


Widget _buildWebLayout(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  final theme = context.watch<ThemeController>().currentTheme;


  return Stack(
    children: [
      // ---------- BACKGROUND ----------
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


      // ---------- CONTENT ----------
      SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight, // ensure background fills screen
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- LEFT COLUMN: POSTER ----------
                InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => OverviewPage(media: widget.media)));
                      },
                      child: Card(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: screenWidth * 0.4,
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: Image.network(
                              widget.media.image,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),),


                const SizedBox(width: 16),


                // ---------- RIGHT COLUMN: REVIEWER INFO + REVIEW ----------
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---------- Reviewer Info ----------
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                InkWell(
                                      onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProfilePage(userId: widget.review.uid, adminAccess: false),
                                            ),
                                          );
                                      },  
                                      child: Text(
                                          widget.review.username,
                                          style: TextStyle(
                                            fontFamily: theme.fontFamily,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                      ),
                                    ),
                                  Consumer<TTSController>(
                                    builder: (context, ttsController, _) {
                                      if (!ttsController.ttsEnabled) return SizedBox.shrink();


                                      return IconButton(
                                        icon: Icon(Icons.volume_up),
                                        onPressed: () {
                                          context.read<TtsService>().speak("${widget.review.rating} stars, reviewed on ${_date.month}/${_date.day}/${_date.year}, ${widget.review.review}");
                                        },
                                      );
                                    },
                                  ),
                              ]
                            ),
                           Text(
                              "Overall Review: ${_date.month}/${_date.day}/${_date.year}",
                              style: TextStyle(
                                fontFamily: theme.fontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 8),
                            staticStarRating(_rating, size: 35),
                            SizedBox(height: 8),
                            TextPopUp(
                              text: widget.review.review != "" ? widget.review.review! : "User Did Not Leave Overall Review",
                              maxLines: 3,
                              type: "Seasons",
                              review: widget.review,
                            ),
                          const SizedBox(height: 10),
                        ]
                      )
                    ),
                      const SizedBox(height: 10),
                    // ---------- SEASON REVIEWS ----------
                    Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 2),
                          image:  DecorationImage(
                                  image: AssetImage(theme.subBackgroundImageOne),
                                  fit: BoxFit.cover,
                                  colorFilter: ColorFilter.mode(
                                    Colors.white.withOpacity(0.6),
                                    BlendMode.lighten,
                                  ),
                                )
                        ),
                        child: FutureBuilder<List<SeasonReview>>(
                          future: _seasonReviewsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }


                            if (snapshot.hasError) {
                              return const Text("Error loading reviews");
                            }


                            final reviews = snapshot.data!;


                            final reviewMap = {
                              for (var r in reviews) r.season_number: r
                            };


                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < widget.media.seasonNumber; i++) ...[
                                  SeasonCard(
                                    uid: widget.review.uid,
                                    review_id: widget.review.review_id,
                                    seasonNumber: (i+1),
                                    review: reviewMap[i+1] ??
                                        SeasonReview(
                                          review_id: widget.review.review_id,
                                          season_number: i+1,
                                          rating: 0,
                                          review: null,
                                          date: DateTime.now(),
                                          spoilers: false,
                                          watched: false,
                                        ),
                                  ),
                                  const SizedBox(height: 20),
                                ]
                              ],
                            );
                          },
                        )
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
}
