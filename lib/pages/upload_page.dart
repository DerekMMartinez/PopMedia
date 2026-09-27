import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/models/book.dart';
import 'package:pop_media/models/movie.dart';
import 'package:pop_media/models/television.dart';
import 'package:pop_media/models/badge.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/book_review.dart';
import 'package:pop_media/models/media_with_review.dart';
import 'package:pop_media/models/movie_review.dart';
import 'package:pop_media/models/television_review.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/ajax_search.dart';
import 'package:pop_media/widgets/star_rating.dart';
import 'package:pop_media/colors.dart';
import 'package:pop_media/widgets/privacy_checkbox.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/widgets/media_buttons.dart';
import 'package:pop_media/widgets/thinking_bubble.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class UploadPage extends StatefulWidget {
  final Map<String, dynamic>? preselectedMedia;

  const UploadPage({super.key, this.preselectedMedia});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final _formKey = GlobalKey<FormState>(); // <-- form key
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  double rating = 3.5;
  String? type = "Public";
  Map<String, dynamic>? _selectedMedia;
  RadioType _selectedType = RadioType.movie;
  DateTime _selectedDate = DateTime.now();
  bool _spoilers = false;
  bool imageBadgeEarned = false;
  bool imageBadgeEarnedRightNow = false;
@override
void initState() {
  super.initState();

  if (widget.preselectedMedia != null){
    _selectedMedia = widget.preselectedMedia;
    if(_selectedMedia!["media_id"][0] == 'b'){
      _selectedType = RadioType.book;
    }
    if(_selectedMedia!["media_id"][0] == 'm'){
      _selectedType = RadioType.movie;
    }
    if(_selectedMedia!["media_id"][0] == 't'){
      _selectedType = RadioType.television;
    }
    _titleController.text = _selectedMedia!['title'] ?? '';
    _loadBadgeEarned();

  }
}

void _openDatePicker(BuildContext context) {
  final DateTime today = DateTime.now();
  final DateTime earliestPossibleDate = DateTime(today.year - 100, today.month, today.day);
  DateTime _clampDate(DateTime date) {
  if (date.isBefore(earliestPossibleDate)) {
    return earliestPossibleDate;
  }
  if (date.isAfter(today)) {
    return today;
  }
  return date;
}
  showModalBottomSheet(
    context: context,
    builder: (_) {
      return SizedBox(
        height: 260, // smaller height
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          minimumDate: earliestPossibleDate,
          maximumDate: today,
          initialDateTime: _clampDate(_selectedDate),
          onDateTimeChanged: (DateTime date) {
            setState(() {
              context.read<TtsService>().speak("Date Changed To: ${date.month}/${date.day}/${date.year}");
              _selectedDate = _clampDate(date);
            });
          },
        ),
      );
    },
  );
}
Future<void> _loadBadgeEarned() async {
    print("in loadBadgeEarned");
    imageBadgeEarned = await DataService.checkMediaBadgeEarned(_selectedMedia!['media_id'], UserSession.uid!);
    setState(() {});
  }

  Media selectedMediaToModel(Map<String, dynamic> media) {
  final id = media['media_id'] as String;

  if (id.startsWith('b')) return Book.fromJson(media);
  if (id.startsWith('m')) return Movie.fromJson(media);
  if (id.startsWith('t')) return Television.fromJson(media);

  throw ArgumentError('Unknown media type: $id');
}

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = MediaQuery.of(context).size.width < 500;
    final theme = context.watch<ThemeController>().currentTheme;

    return Scaffold(
      key: const Key('upload_page'),
      backgroundColor: theme.mainBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.topBarColor,
        centerTitle: true,
          title: Image.asset(
            theme.logo, 
            height: 60,
            fit: BoxFit.contain,
          ), 
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            key: const Key('exit_button'),
            color: theme.primaryColor,
            onPressed: () {
              context.read<TtsService>().speak("Are you sure you want to exit?");
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  height: 200,
                  child: Column(
                    children: [
                      const Text(
                        'Exit Upload',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: const [
                          Text(
                            'Are you sure you want to cancel your post?',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '(Information will not be saved)',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => {
                              context.read<TtsService>().speak("Remaining on Upload"),
                              Navigator.of(context).pop()
                            },
                            child: const Text('Keep Posting'),
                          ),
                          ElevatedButton(
                            key: const Key('leave_button'),
                            onPressed: () {
                              context.read<TtsService>().speak("Exiting Upload");
                              Navigator.of(context).pop();
                              Navigator.of(context).pop();
                            },
                            child: const Text('Leave'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: (){
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints( minHeight: screenHeight,),
        child: Stack(
          children: [
            Positioned.fill(
              child: theme.name != 'Simple'
                  ? Opacity(
                      opacity: 0.4,
                      child: Image.asset(
                        theme.subBackgroundImageTwo,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: theme.mainBackgroundColor,
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  SizedBox(height: 12),
                  Row(
                    children:[
                      ComicTitle(title: 'Media Type: *', size: 14),
                       if (isMobile)
                        Flexible(
                          child: MediaTypeRadio(
                            value: _selectedType,
                            onChanged: (value) {
                              context.read<TtsService>().speak("Uploading Type: ${value.name}");
                              setState(() {
                                _selectedType = value;
                                _selectedMedia = null;
                                imageBadgeEarnedRightNow = false;
                                _titleController.clear();
                              });
                            },
                          ),
                        )
                      else
                        MediaTypeRadio(
                          value: _selectedType,
                          onChanged: (value) {
                            context.read<TtsService>().speak("Uploading Type: ${value.name}");
                            setState(() {
                              _selectedType = value;
                              _selectedMedia = null;
                              imageBadgeEarnedRightNow = false;
                              _titleController.clear();
                            });
                          }
                        ),
                    ],
                  ),
                  SizedBox(height: 14),
                  // --- Title Ajax Search  ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ComicTitle(title: 'Title: *' , size: 14),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 3),
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Colors.grey.shade200.withOpacity(0.9),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: AjaxSearchField(
                            controller: _titleController,
                            key: const Key('upload_ajax_search'),
                            hintText: "Media Title",
                            onSearch: (query) async {
                              context.read<TtsService>().speak("Searching: ${query}");
                              try {
                                final mediaList = await DataService.loadMedia(query, _selectedType);
                                final normalized = mediaList.map((item) {
                                  final map = Map<String, dynamic>.from(item);
                                  map['image'] = map['image']?.toString() ?? 'assets/media_imgs/placeholder_poster.png';
                                  return map;
                                }).toList();

                                return normalized;
                              } catch (e) {context.read<TtsService>().speak("Failed to load search");
                                print("Error fetching media: $e");
                                return [];
                              }
                            },
                            displayStringForOption: (Map<String, dynamic> media) =>
                                media['title']?.toString() ?? '',
                            onSelected: (Map<String, dynamic> media) {
                              _selectedMedia = media;
                              imageBadgeEarnedRightNow = false;
                              _loadBadgeEarned();
                              _titleController.text = media['title']?.toString() ?? '';
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children:[
                      ComicTitle(
                        title: (_selectedType == RadioType.movie ||
                                _selectedType == RadioType.television)
                            ? 'Date Watched: *'
                            : 'Date Read: *',
                        size: 14,
                      ),
                      GestureDetector(
                        onTap: () => _openDatePicker(context),
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: Text(
                            "${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}",
                            style: TextStyle(
                              fontFamily: theme.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ]
                  ),
                    // --- Rating ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ComicTitle(title: 'Rate: *' , size: 14),
                        const SizedBox(width: 12),
                        StarRatingWidget(
                          key: const Key('upload_rate'),
                          starCount: 5,
                          initialRating: 3.5,
                          color: AppColors.teamGold,
                          onRatingChanged: (value) {
                            context.read<TtsService>().speak("Rating Changed to: ${value}");
                            rating = value;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        ComicTitle(title: 'Review:' , size: 14),
                        SizedBox(width: 30),
                        Row(
                        children: [
                          // black box checkbox
                          Container(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              key: const Key('upload_spoilers'),
                              value: _spoilers,
                              onChanged: (bool? value) {
                                context.read<TtsService>().speak("Contains Spoilers: ${value}");
                                setState(() {
                                  _spoilers = value ?? false;
                                });
                              },
                              activeColor: Colors.white,
                              checkColor: Colors.black,  
                              side: BorderSide(
                                color: theme.primaryColor,
                                width: 2,
                              ),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Contains Spoilers',
                            style: TextStyle(
                              fontFamily: theme.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ThinkingBubble(
                      key: const Key('upload_review'),
                      initialText: 'Write your review here...', 
                      controller: _reviewController
                      ),

                    const SizedBox(height: 10),
              
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children:[
                            ComicTitle(title: 'Review Privacy: *' , size: 14),
                            SizedBox(width: 2),
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        width: 350,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColor, width: 2,),
                                          color: theme.mainBackgroundColor,
                                          image: theme.privacyImage != null
                                              ? DecorationImage(
                                                  image: AssetImage(theme.privacyImage!),
                                                  fit: BoxFit.cover,
                                                )
                                              : theme.mainBackgroundImage != null ? DecorationImage(
                                                  image: AssetImage(theme.mainBackgroundImage!),
                                                  fit: BoxFit.cover,
                                                ) : null
                                        ),
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ComicTitle(title: 'Privacy Settings', size: 20),
                                            SizedBox(height: 5),
                                            Container(
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
                                                child: Center(
                                                child: Text(
                                                  "Public: Viewed By Anyone \n Friends Only: Viewed By Mutuals \n My Eyes Only: Viewed By You",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontFamily: theme.fontFamily,
                                                    color: theme.primaryColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 15),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: theme.mainBackgroundColor,
                                                side: BorderSide(color: theme.name != 'Simple' ? theme.primaryColor : theme.accentColorThree, width: 2),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text(
                                                "Close",
                                                style: TextStyle(
                                                  color: theme.primaryColor,
                                                  fontFamily: theme.fontFamily,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Icon(
                                Icons.info_outline,
                                size: 18,
                                color: theme.primaryColor,
                              ),
                            ),
                            SizedBox(width: 2),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: SingleCheckboxSet(
                            onChanged: (value) {
                                context.read<TtsService>().speak("Selected Privacy: ${value}");
                                type = value;
                            }
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            print("Posting time, imageBadgeEarned: ${imageBadgeEarned}, imageBadgeEarnedRightNow: ${imageBadgeEarnedRightNow}");
                             if (UserSession.badgeProcessing){
                              ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(
                                  content: Text(
                                    "Your previously submitted image is currently being processed. Please wait a moment and try again.")
                                    )
                                  );
                              return;
                            }
                            if (_titleController.text.trim().isEmpty) {
                              context.read<TtsService>().speak("Please enter or select a title.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter or select a title.")),
                              );
                              return;
                            }

                            if (_selectedMedia == null) {
                              context.read<TtsService>().speak("Please select a valid media.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please select a valid media.")),
                              );
                              return;
                            }

                            if (UserSession.userReviews!.any((media) => media.media.name == _titleController.text)) {
                              context.read<TtsService>().speak("Media has already been reviewed. Update review from review page.");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Media has already been reviewed. Update review from review page.")),
                              );
                              return;
                            }
                            try {
                              await DataService.postReview(
                                uid: UserSession.uid!,
                                mediaId: _selectedMedia!['media_id'],
                                rating: rating,
                                review_visibility: type ?? "Public",
                                reviewText: _reviewController.text,
                                finishedOn: _selectedDate,
                                spoilers: _spoilers
                              );

                              var username = await DataService.getUsername(uid: UserSession.uid!);
                              
                              final reviewData = {
                                'uid': UserSession.uid!,
                                'username': username,
                                'media_id': _selectedMedia!['media_id'],
                                'rating': rating,
                                'review_visibility': type ?? "Public",
                                'review_text': _reviewController.text,
                                'finished_on': _selectedDate.toString(),
                                'spoiler': _spoilers
                              };

                              if(_selectedType == RadioType.book){
                                var media = Book.fromJson(_selectedMedia!);
                                var review = BookReview.fromJson(reviewData);
                                var mediaWithReview = MediaWithReview(media: media, review: review);
                                UserSession.addUserReview(mediaWithReview);
                              }
                              if(_selectedType == RadioType.movie){
                                var media = Movie.fromJson(_selectedMedia!);
                                var review = MovieReview.fromJson(reviewData);
                                var mediaWithReview = MediaWithReview(media: media, review: review);
                                UserSession.addUserReview(mediaWithReview);
                              }
                              if(_selectedType == RadioType.television){
                                var media = Television.fromJson(_selectedMedia!);
                                var review = TelevisionReview.fromJson(reviewData);
                                var mediaWithReview = MediaWithReview(media: media, review: review);
                                UserSession.addUserReview(mediaWithReview);
                              }

                              //Badge checks
                              var bookLength = (await UserSession.getUserReviews(UserSession.uid!, 'b')).length;
                              var movieLength = (await UserSession.getUserReviews(UserSession.uid!, 'm')).length;
                              var tvLength = (await UserSession.getUserReviews(UserSession.uid!, 't')).length;

                              bool badgeEarned = false;

                              if(_selectedType == RadioType.book && bookLength == 10){
                                UserSession.addBadgeEarned(2);
                                Navigator.pushReplacementNamed(context, '/homePage', arguments:{'showBookBadge': true});
                                badgeEarned = true;
                              }
                              if(_selectedType == RadioType.movie && movieLength == 10){
                                UserSession.addBadgeEarned(3);
                                Navigator.pushReplacementNamed(context, '/homePage', arguments:{'showMovieBadge': true});
                                badgeEarned = true;
                              }
                              if(_selectedType == RadioType.television && tvLength == 10){
                                UserSession.addBadgeEarned(4);
                                Navigator.pushReplacementNamed(context, '/homePage', arguments:{'showTvBadge': true});
                                badgeEarned = true;
                              }

                              if((bookLength > 0 && movieLength > 0 && tvLength > 0) && 
                              ((bookLength == 1 && _selectedMedia!['media_id'][0] == 'b') || 
                              (movieLength == 1 && _selectedMedia!['media_id'][0] == 'm') || 
                              (tvLength == 1 && _selectedMedia!['media_id'][0] == 't'))){
                                UserSession.addBadgeEarned(5);
                                Navigator.pushReplacementNamed(context, '/homePage', arguments:{'showAllMediaBadge': true});
                                badgeEarned = true;
                              }

                              if(!badgeEarned){
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/homePage',
                                  (route) => false,
                                );
                              }
                              if (imageBadgeEarnedRightNow){        //this one is for the IMAGE badge
                                await DataService.postMediaBadgeEarned(_selectedMedia!['media_id'], UserSession.uid!, _selectedMedia!['name'], _selectedMedia!['image_url']);
                                Badge badge = await DataService.getBadgeWithMediaId(_selectedMedia!['media_id']);
                                UserSession.addNewBadge(badge);
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error posting review: $e")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.mainBackgroundColor,
                            foregroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                              side: BorderSide(color: theme.primaryColor, width: 2),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            elevation: 0,
                          ),
                          key: const Key('upload_post_button'),
                          child: ComicTitle(title: 'Post', size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
}
