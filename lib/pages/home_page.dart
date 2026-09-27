import 'package:flutter/material.dart' hide Theme;
import 'package:pop_media/pages/my_reviews_page.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:provider/provider.dart';
import '../widgets/main_scaffold.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/widgets/media_section.dart';
import 'package:pop_media/widgets/badge_earned_popup.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/models/media_with_review.dart';
import 'package:pop_media/models/media.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>{
  late Future<List<MediaWithReview>> _myReviews;
  late Future<List<MediaWithReview>> _friendsReviews;
  late Future<List<Media>> _trending;

  @override
  void initState() {
    super.initState();
    _myReviews = UserSession.getUserReviews(UserSession.uid!, 'a');
    _friendsReviews = DataService.getFollowingReviews('me', 'a');
    _trending = UserSession.getTrending('a');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;

      if (args != null && args['showWelcomeBadge'] == true) {
        _showBadge("1");
      }
      if (args != null && args['showBookBadge'] == true) {
        _showBadge("2");
      }
      if (args != null && args['showMovieBadge'] == true) {
        _showBadge("3");
      }
      if (args != null && args['showTvBadge'] == true) {
        _showBadge("4");
      }
      if (args != null && args['showAllMediaBadge'] == true) {
        _showBadge("5");
      }
    });
  }

  void _showBadge(String bid) async{
    final badge = await DataService.getBadge(bid: bid);
    if(!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BadgeEarnedPopUp(
        badge: badge,
        confetti: true
      )
    );
    context.read<TtsService>().speak("Congratualations! Earned new badge ${badge.name}");
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    return MainScaffold(
      key: const Key('home_screen'),
      body: SingleChildScrollView(
        child: Stack(
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
            // Content on top of the background
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 5, right:5, left: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- My Reviews Section ----------------
                  MediaSection<MediaWithReview>(
                    title: 'My Reviews',
                    count: false,
                    onNavigate: () {
                      context.read<TtsService>().speak("Opening My Reviews");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyReviewsPage(uid: UserSession.uid, username: null, hideName: false,),
                        ),
                      );
                    },
                    sectionHeight: 230,
                    postReview: false,
                    friendSection: false,
                    borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor,
                    future: _myReviews,
                    backgroundImage: theme.subBackgroundImageOne,
                    itemBuilder: (context, mediaWithReview) {
                      return MediaCard(
                        key: Key('my_review_${mediaWithReview.media.name}'),
                        media: mediaWithReview.media,
                        review: mediaWithReview.review,
                        type: MediaCardType.myReview,
                        hideName: false
                      );
                    },
                  ),
                  SizedBox(height: 15),
                  // ---------------- Following Section ----------------
                  MediaSection<MediaWithReview>(
                    title: "Following Reviews",
                    count: false,
                    onNavigate: () {
                      context.read<TtsService>().speak("Opening Following Reviews");
                      Navigator.pushNamed(context, '/followingPage');},
                    sectionHeight: 248,
                    postReview: false,
                    friendSection: false,
                    future: _friendsReviews,
                    borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorTwo,
                    backgroundImage: theme.subBackgroundImageTwo,
                    itemBuilder: (context, mediaWithReview) {
                      return MediaCard(
                        media: mediaWithReview.media,
                        review: mediaWithReview.review,
                        type : MediaCardType.friendReview,
                        hideName: false
                      );
                    },
                  ),

                  SizedBox(height: 15),
                  // ---------------- Trending Section ----------------
                  MediaSection<Media>(
                    title: 'Trending',
                    count: false,
                    onNavigate: () {
                      context.read<TtsService>().speak("Opening Trending");
                      Navigator.pushNamed(context, '/trendingPage');},
                    sectionHeight: 205,
                    postReview: false,
                    friendSection: false,
                    future: _trending,
                    backgroundImage: theme.subBackgroundImageThree,
                    borderColor: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorThree,
                    itemBuilder: (context, media) {
                      return MediaCard(
                        media: media,
                        type : MediaCardType.overview,
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
      currentIndex: 0,
    );
  }
}