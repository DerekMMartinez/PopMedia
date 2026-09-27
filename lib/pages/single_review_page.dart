import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart' hide Theme, Badge;
import 'package:pop_media/colors.dart';
import 'package:pop_media/models/badge.dart';
import 'package:pop_media/models/book_review.dart';
import 'package:pop_media/models/media_with_review.dart';
import 'package:pop_media/models/movie_review.dart';
import 'package:pop_media/models/television.dart';
import 'package:pop_media/models/television_review.dart';
import 'package:pop_media/models/theme.dart';
import 'package:pop_media/pages/camera_page.dart';
import 'package:pop_media/pages/media_review_page.dart';
import 'package:pop_media/pages/overview_page.dart';
import 'package:pop_media/pages/profile_page.dart';
import 'package:pop_media/text_speech/tts_controller.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/pages/season_reviews.dart';
import 'package:pop_media/widgets/chat_bubble.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/review.dart';
import 'package:pop_media/widgets/media_badge_locked.dart';
import 'package:pop_media/widgets/media_section.dart';
import 'package:pop_media/widgets/report_popup.dart';
import 'package:pop_media/widgets/alpha_masked_image.dart';
import 'package:pop_media/widgets/static_star_rating.dart';
import 'package:pop_media/widgets/star_rating.dart';
import 'package:pop_media/widgets/review_card.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/privacy_selector.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:pop_media/widgets/badge_earned_popup.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class SingleReviewsPage extends StatefulWidget {
  final Media media;
  final Review review;
  final MediaCardType type;

  SingleReviewsPage({
    super.key,
    required this.media,
    required this.review,
    required this.type,
  });

  @override
  State<SingleReviewsPage> createState() => _SingleReviewsPage();
}

class _SingleReviewsPage extends State<SingleReviewsPage> {
  bool _isEditing = false;
  late double _rating;
  late DateTime _date;
  late String _privacyLabel;
  late String _reviewText;
  late bool _spoilers;
  late TextEditingController _reviewController = TextEditingController();
  late Future<List<Review>> _reviews;
  String media_type = 'Book';
  late Review editedReview = widget.review;
  late bool _badgeEarned = false;
  bool _cameraOpening = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _date = widget.review.date;
    _privacyLabel = widget.review.visibility;
    _reviewText = widget.review.review ?? '';
    _reviewController = TextEditingController(text: _reviewText);
    _reviews = DataService.getMediaReviews(
      UserSession.uid!,
      widget.media.id,
      widget.review.username,
      true,
    );
    _spoilers = widget.review.spoilers;
    if (widget.media.type == 'Tv')
      media_type = "TV";
    else if (widget.media.type == 'Movie')
      media_type = "Movie";
    _loadBadgeEarned();
  }

  Future<void> _loadBadgeEarned() async {
    _badgeEarned = await DataService.checkMediaBadgeEarned(
      widget.media.id,
      widget.review.uid,
    );
    setState(() {});
  }

  void _handleVerifyReturn(bool result) async {
    if (result) {
      _badgeEarned = true;
      if (mounted) {
        setState(() {});
      }
      try {
        Badge badge = await DataService.getBadgeWithMediaId(widget.media.id);
        UserSession.addNewBadge(badge);
      } catch (e) {
        debugPrint("Badge fetch after verification failed: $e");
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image Verified!')));
    } else {
      await _loadBadgeEarned();
      if (_badgeEarned) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image Verified!')));
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification failed...')));
    }
  }

  Future<void> _handleMobileCamera(BuildContext context) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _handleIosCamera(context);
      return;
    }

    await _handleAndroidCamera(context);
  }

  Future<void> _handleIosCamera(BuildContext context) async {

    if (_cameraOpening) return;

    setState(() {
      _cameraOpening = true;
    });

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        requestFullMetadata: false,
      );

      if (image == null) return;

      if (!context.mounted) return;

      final imageBytes = await image.readAsBytes();

      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => DisplayPictureScreen(
            imagePath: image.path,
            imageBase64: base64Encode(imageBytes),
            media: widget.media,
            callback: _handleVerifyReturn,
            stillUploading: false,
            popCountAfterConfirm: 1,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cameraOpening = false;
        });
      }
    }
  }

  Future<void> _handleAndroidCamera(BuildContext context) async {

    if (_cameraOpening) return;

    setState(() {
      _cameraOpening = true;
    });

    try {
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 10),
      );

      if (cameras.isEmpty) {
        throw Exception("No cameras available");
      }

      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      if (!context.mounted) return;

      await Navigator.pushNamed(
        context,
        '/cameraPage',
        arguments: {
          'camera': firstCamera,
          'media': widget.media,
          'callback': _handleVerifyReturn,
          'stillUploading': false,
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _cameraOpening = false;
        });
      }
    }
  }

  void _openDatePicker(BuildContext context, Theme theme) {
    final DateTime today = DateTime.now();
    final DateTime earliestPossibleDate = DateTime(
      today.year - 100,
      today.month,
      today.day,
    );
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
          height: 260,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            minimumDate: earliestPossibleDate,
            maximumDate: today,
            initialDateTime: _clampDate(_date),
            onDateTimeChanged: (DateTime date) {
              setState(() {
                context.read<TtsService>().speak(
                  "Date Changed To: ${_date.month}/${_date.day}/${_date.year}",
                );
                _date = _clampDate(date);
              });
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Theme theme) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        context.read<TtsService>().speak(
          "Are you sure you want to delete this review?",
        );
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Are you sure you want to delete this review?",
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      context.read<TtsService>().speak("Delete Canceled");
                      Navigator.pop(ctx);
                    },
                    child: const ComicTitle(title: "Cancel"),
                  ),
                  TextButton(
                    key: const Key('review_delete_confirm'),
                    onPressed: () async {
                      final success = await UserSession.deleteUserReview(
                        widget.review.uid,
                        widget.media.id,
                      );

                      // Close the bottom sheet FIRST
                      Navigator.pop(ctx);

                      if (success) {
                        context.read<TtsService>().speak("Review Deleted");
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).pushNamedAndRemoveUntil(
                          '/homePage',
                          (route) => false,
                        );
                      } else {
                        context.read<TtsService>().speak("Delete Failed");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to delete review. Please try again later.',
                            ),
                          ),
                        );
                      }
                    },
                    child: const ComicTitle(title: "Delete"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
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
    final theme = context.watch<ThemeController>().currentTheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        // ---------- BACKGROUND ----------
        Positioned.fill(
          child: Opacity(
            opacity: 0.4,
            child: RotatedBox(
              quarterTurns: 1, // 90 degrees
              child: Image.asset(
                theme.subBackgroundImageTwo,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // ---------- CONTENT ----------
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
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
                          context.read<TtsService>().speak(
                            "Opening ${widget.media.name} Overview",
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  OverviewPage(media: widget.media),
                            ),
                          );
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
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Reviewer info
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: theme.name != 'Simple'
                                  ? theme.primaryColor
                                  : theme.accentColor,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        if (widget.review.username !=
                                            widget.review.uid) {
                                          //Not from the APIS
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProfilePage(
                                                userId: widget.review.uid,
                                                adminAccess: false,
                                              ),
                                            ),
                                          );
                                        } else {
                                          showDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (context) {
                                              return AlertDialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                contentPadding: EdgeInsets.zero,
                                                content: Container(
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: AssetImage(
                                                        theme
                                                            .subBackgroundImageTwo,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Text(
                                                        'Imported Review',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      RichText(
                                                        textAlign:
                                                            TextAlign.center,
                                                        text: TextSpan(
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                          children: [
                                                            if (widget.media.id
                                                                .startsWith(
                                                                  'b',
                                                                )) ...[
                                                              const TextSpan(
                                                                text:
                                                                    'This review is imported from \n Google Plays API',
                                                              ),
                                                            ] else ...[
                                                              const TextSpan(
                                                                text:
                                                                    'This review is imported from \n The TMDB API',
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                        child: const Text(
                                                          'Close',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
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
                                  ),
                                  Consumer<TTSController>(
                                    builder: (context, ttsController, _) {
                                      if (!ttsController.ttsEnabled)
                                        return SizedBox.shrink();

                                      return IconButton(
                                        icon: Icon(Icons.volume_up),
                                        onPressed: () {
                                          context.read<TtsService>().speak(
                                            "${widget.review.rating} stars, reviewed on ${_date.month}/${_date.day}/${_date.year}",
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  if (widget.type ==
                                      MediaCardType.myReview) ...[
                                    IconButton(
                                      icon: Icon(
                                        _isEditing ? Icons.check : Icons.edit,
                                      ),
                                      key: const Key('edit_button'),
                                      color: Colors.black,
                                      style: IconButton.styleFrom(
                                        backgroundColor: _isEditing
                                            ? const Color.fromARGB(
                                                255,
                                                136,
                                                236,
                                                139,
                                              )
                                            : Colors.white,
                                      ),
                                      tooltip: _isEditing ? 'Save' : 'Edit',
                                      onPressed: () async {
                                        setState(() {
                                          _isEditing = !_isEditing;
                                        });
                                        if (!_isEditing) {
                                          context.read<TtsService>().speak(
                                            "Saving Edits",
                                          );
                                          try {
                                            setState(() {
                                              _reviewText =
                                                  _reviewController.text;
                                            });
                                            await DataService.updateReview(
                                              uid: UserSession.uid!,
                                              mediaId: widget.media.id,
                                              rating: _rating,
                                              review_visibility: _privacyLabel,
                                              reviewText: _reviewText,
                                              finished_on: _date,
                                              spoilers: _spoilers,
                                            );

                                            final reviewData = {
                                              'uid': UserSession.uid!,
                                              'username':
                                                  widget.review.username,
                                              'media_id': widget.media.id,
                                              'rating': _rating,
                                              'review_text':
                                                  _reviewController.text,
                                              'review_visibility':
                                                  _privacyLabel,
                                              'finished_on': _date
                                                  .toIso8601String(),
                                              'spoiler': _spoilers,
                                            };

                                            if (widget.media.id[0] == 'b') {
                                              var review = BookReview.fromJson(
                                                reviewData,
                                              );
                                              var mediaWithReview =
                                                  MediaWithReview(
                                                    media: widget.media,
                                                    review: review,
                                                  );
                                              UserSession.editUserReview(
                                                mediaWithReview,
                                              );
                                              editedReview = review;
                                            }
                                            if (widget.media.id[0] == 'm') {
                                              var review = MovieReview.fromJson(
                                                reviewData,
                                              );
                                              var mediaWithReview =
                                                  MediaWithReview(
                                                    media: widget.media,
                                                    review: review,
                                                  );
                                              UserSession.editUserReview(
                                                mediaWithReview,
                                              );
                                              editedReview = review;
                                            }
                                            if (widget.media.id[0] == 't') {
                                              var review =
                                                  TelevisionReview.fromJson(
                                                    reviewData,
                                                  );
                                              var mediaWithReview =
                                                  MediaWithReview(
                                                    media: widget.media,
                                                    review: review,
                                                  );
                                              UserSession.editUserReview(
                                                mediaWithReview,
                                              );
                                              editedReview = review;
                                            }
                                          } catch (e) {
                                            context.read<TtsService>().speak(
                                              "Failed to Save Edits",
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Error posting review: $e",
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          context.read<TtsService>().speak(
                                            "Editing Review",
                                          );
                                        }
                                      },
                                    ),
                                    if (widget.type == MediaCardType.myReview &&
                                        _isEditing)
                                      IconButton(
                                        key: const Key('delete_review_button'),
                                        onPressed: () {
                                          context.read<TtsService>().speak(
                                            "Delete Review",
                                          );
                                          _showDeleteConfirmation(
                                            context,
                                            theme,
                                          );
                                        },
                                        icon: const Icon(Icons.delete),
                                        color: Colors.black,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                  ] else ...[
                                    IconButton(
                                      onPressed: () {
                                        context.read<TtsService>().speak(
                                          "Opened Report PopUp",
                                        );
                                        showDialog(
                                          context: context,
                                          builder: (context) => ReportPopUp(
                                            type: "Review",
                                            associatedId:
                                                "${widget.media.type}, ${widget.review.review_id}",
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.flag),
                                      color: Colors.red,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isEditing) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: StarRatingWidget(
                                          initialRating: _rating,
                                          starSize: 30,
                                          onRatingChanged: (value) {
                                            context.read<TtsService>().speak(
                                              "Rating Changed To: ${value}",
                                            );
                                            _rating = value;
                                          },
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: GestureDetector(
                                          onTap: () =>
                                              _openDatePicker(context, theme),
                                          child: Container(
                                            height: 30,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 5,
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              "${_date.month}/${_date.day}/${_date.year}",
                                              style: TextStyle(
                                                fontFamily: theme.fontFamily,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // black box checkbox
                                            Container(
                                              width: 24,
                                              height: 24,
                                              child: Checkbox(
                                                key: const Key('edit_spoilers'),
                                                value: _spoilers,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    context
                                                        .read<TtsService>()
                                                        .speak(
                                                          "Contains Spoilers: ${value}",
                                                        );
                                                    _spoilers = value ?? false;
                                                  });
                                                },
                                                activeColor: Colors.white,
                                                checkColor: Colors.black,
                                                side: const BorderSide(
                                                  color: Colors.black,
                                                  width: 2,
                                                ),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              'Contains Spoilers',
                                              style: TextStyle(
                                                fontFamily: theme.fontFamily,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    Center(
                                      child: staticStarRating(
                                        _rating,
                                        size: 35,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      "${_date.month}/${_date.day}/${_date.year}",
                                      style: TextStyle(
                                        fontFamily: theme.fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  if (widget.type == MediaCardType.myReview &&
                                      _isEditing) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.red,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: PrivacySelector(
                                        startLabel: _privacyLabel,
                                        playlist: false,
                                        onChanged: (label) {
                                          setState(() {
                                            context.read<TtsService>().speak(
                                              "Privacy Changed To: ${label}",
                                            );
                                            _privacyLabel = label;
                                          });
                                        },
                                      ),
                                    ),
                                  ] else if (widget.type ==
                                      MediaCardType.myReview) ...[
                                    if (_privacyLabel == "public") ...[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/icons/public_icon.png',
                                            width: 35,
                                            height: 25,
                                            fit: BoxFit.cover,
                                          ),
                                          Text(
                                            "Public",
                                            style: TextStyle(
                                              fontFamily: theme.fontFamily,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_privacyLabel == "friends only") ...[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/icons/friends_only_icon.png',
                                            width: 35,
                                            height: 35,
                                            fit: BoxFit.cover,
                                          ),
                                          Text(
                                            "Friends Only",
                                            style: TextStyle(
                                              fontFamily: theme.fontFamily,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (_privacyLabel == "my eyes only") ...[
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/icons/private_icon.png',
                                            width: 35,
                                            height: 25,
                                            fit: BoxFit.cover,
                                          ),
                                          Text(
                                            "My Eyes Only",
                                            style: TextStyle(
                                              fontFamily: theme.fontFamily,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                  //POP badge mobile
                                  if (!_isEditing) ...[
                                    InkWell(
                                      child: !_badgeEarned
                                          ? Image.asset(
                                              'assets/badges/blankBadge.png',
                                              width: 55,
                                              height: 70,
                                              fit: BoxFit.cover,
                                            )
                                          : AlphaMaskedImage(
                                              imageUrl: widget.media.image,
                                              width: 85,
                                              height: 100,
                                            ),

                                      onTap: () async {
                                        if (_badgeEarned) {
                                          final badge =
                                              await DataService.getBadgeWithMediaId(
                                                widget.media.id,
                                              );

                                          if (!mounted) return;

                                          showDialog(
                                            context: context,
                                            useRootNavigator: true,
                                            builder: (context) =>
                                                BadgeEarnedPopUp(
                                                  badge: badge,
                                                  confetti:
                                                      UserSession.uid ==
                                                      widget.review.uid,
                                                ),
                                          );
                                        } else {
                                          showDialog(
                                            context: context,
                                            useRootNavigator: true,
                                            builder: (context) =>
                                                MediaBadgeLockedPopUp(
                                                  media: widget.media,
                                                  type: widget.type,
                                                  username:
                                                      widget.review.username,
                                                ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                  SizedBox(height: 5),
                                  if (!_badgeEarned && !_isEditing && widget.review.uid == UserSession.uid!) ...[
                                    ElevatedButton(
                                      onPressed: _cameraOpening
                                          ? null
                                          : () async {
                                              if (UserSession.badgeProcessing) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      "Your previously submitted image is currently being processed. Please wait a moment and try again.",
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              if (kIsWeb && screenWidth >= 500) {
                                                try {
                                                  final result =
                                                      await FilePicker.platform
                                                          .pickFiles(
                                                            type:
                                                                FileType.image,
                                                            withData: true,
                                                          );
                                                  if (result == null ||
                                                      result
                                                              .files
                                                              .single
                                                              .bytes ==
                                                          null)
                                                    return;

                                                  final file =
                                                      result.files.single;
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Photo is being submitted for badge verification! This may take a moment.",
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                  await DataService.verifyImageMatch(
                                                    base64Encode(file.bytes!),
                                                    widget.media,
                                                    UserSession.uid!,
                                                    _handleVerifyReturn,
                                                    false,
                                                  );
                                                } catch (e) {
                                                  debugPrint(
                                                    "Upload failed: $e",
                                                  );
                                                  context
                                                      .read<TtsService>()
                                                      .speak(
                                                        "Image Upload Failed",
                                                      );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Upload failed: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } else {

                                                try {
                                                  await _handleMobileCamera(
                                                    context,
                                                  );
                                                } catch (e) {
                                                  debugPrint(
                                                    "Camera flow failed: $e",
                                                  );

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Camera failed: $e",
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: const BorderSide(
                                                  color: Colors.black,
                                                  width: 2,
                                                ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        elevation: 0,
                                      ),
                                      child: _cameraOpening
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : ComicTitle(
                                              title: 'Use Photo',
                                              size: 14,
                                              color: theme.primaryColor,
                                            ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ---------- REVIEW ----------
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.name != 'Simple'
                            ? theme.primaryColor
                            : theme.accentColorThree,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: AssetImage(theme.subBackgroundImageOne),
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
                          children: [
                            ComicTitle(title: '$media_type Review'),
                            Consumer<TTSController>(
                              builder: (context, ttsController, _) {
                                if (!ttsController.ttsEnabled)
                                  return SizedBox.shrink();

                                return IconButton(
                                  icon: Icon(Icons.volume_up),
                                  onPressed: () {
                                    context.read<TtsService>().speak(
                                      "${_reviewController.text}",
                                    );
                                  },
                                );
                              },
                            ),
                            Spacer(),
                            if (media_type == 'TV' &&
                                !_isEditing &&
                                widget.review.username !=
                                    widget.review.uid) ...[
                              TextButton(
                                onPressed: () {
                                  context.read<TtsService>().speak(
                                    "Opening Season By Season Review",
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SeasonReviewsPage(
                                        media: widget.media as Television,
                                        review: editedReview,
                                        type: widget.type,
                                      ),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: BorderSide(
                                      color: theme.accentColorTwo,
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  "Season Reviews >",
                                  style: TextStyle(
                                    fontFamily: theme.fontFamily,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_reviewText.isNotEmpty || _isEditing) ...[
                          ChatBubble(
                            message: _reviewController.text,
                            width: double.infinity,
                            isEditing: _isEditing,
                            controller: _reviewController,
                            spoilers: _spoilers,
                            mine: widget.review.uid == UserSession.uid,
                          ),
                          const SizedBox(height: 10),
                        ] else ...[
                          Center(
                            child: Text(
                              'User did not leave a comment',
                              style: TextStyle(
                                fontFamily: theme.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: theme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!_isEditing) ...[
                    const SizedBox(height: 10),
                    Divider(
                      color: theme.primaryColor,
                      height: 10,
                      thickness: 2,
                      indent: 20,
                      endIndent: 20,
                    ),
                    const SizedBox(height: 10),
                    MediaSection<Review>(
                      title: 'Other Reviews',
                      count: true,
                      onNavigate: () {
                        context.read<TtsService>().speak(
                          "${"Opening Other Reviews of ${widget.media.name}"}",
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MediaReviewsPage(media: widget.media),
                          ),
                        );
                      },
                      borderColor: theme.name != 'Simple'
                          ? theme.primaryColor
                          : theme.accentColorTwo,
                      postReview: false,
                      friendSection: false,
                      sectionHeight: 175,
                      future: _reviews,
                      backgroundImage: theme.subBackgroundImageThree,
                      itemBuilder: (context, review) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SizedBox(
                            width: 395,
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
                  ],
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
          child: Opacity(
            opacity: 0.4,
            child: Image.asset(
              theme.subBackgroundImageTwo,
              fit: BoxFit.cover, // fills the entire stack
            ),
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
                      context.read<TtsService>().speak(
                        "Opening ${widget.media.name} Overview",
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              OverviewPage(media: widget.media),
                        ),
                      );
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
                    ),
                  ),

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
                            border: Border.all(
                              color: theme.name != 'Simple'
                                  ? theme.primaryColor
                                  : theme.accentColor,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        if (widget.review.username !=
                                            widget.review.uid) {
                                          //Not from the APIS
                                          context.read<TtsService>().speak(
                                            "Opening ${widget.review.username} Profile",
                                          );
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ProfilePage(
                                                userId: widget.review.uid,
                                                adminAccess: false,
                                              ),
                                            ),
                                          );
                                        } else {
                                          context.read<TtsService>().speak(
                                            "${widget.review.username} Imported Review from API",
                                          );
                                          showDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (context) {
                                              return AlertDialog(
                                                backgroundColor:
                                                    Colors.transparent,
                                                contentPadding: EdgeInsets.zero,
                                                content: Container(
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: AssetImage(
                                                        theme
                                                            .subBackgroundImageOne,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      const Text(
                                                        'Imported Review',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      RichText(
                                                        textAlign:
                                                            TextAlign.center,
                                                        text: TextSpan(
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                          children: [
                                                            if (widget.media.id
                                                                .startsWith(
                                                                  'b',
                                                                )) ...[
                                                              const TextSpan(
                                                                text:
                                                                    'This review is imported from \n Google Plays API',
                                                              ),
                                                            ] else ...[
                                                              const TextSpan(
                                                                text:
                                                                    'This review is imported from \n The TMDB API',
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 16,
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(
                                                              context,
                                                            ).pop(),
                                                        child: const Text(
                                                          'Close',
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
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
                                  ),
                                  Consumer<TTSController>(
                                    builder: (context, ttsController, _) {
                                      if (!ttsController.ttsEnabled)
                                        return SizedBox.shrink();

                                      return IconButton(
                                        icon: Icon(Icons.volume_up),
                                        onPressed: () {
                                          context.read<TtsService>().speak(
                                            "${widget.review.rating} stars, reviewed on ${_date.month}/${_date.day}/${_date.year}",
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  if (widget.type == MediaCardType.myReview)
                                    IconButton(
                                      icon: Icon(
                                        _isEditing ? Icons.check : Icons.edit,
                                      ),
                                      key: const Key('edit_button'),
                                      color: Colors.black,
                                      style: IconButton.styleFrom(
                                        backgroundColor: _isEditing
                                            ? const Color.fromARGB(
                                                255,
                                                136,
                                                236,
                                                139,
                                              )
                                            : Colors.white,
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          ;
                                          _isEditing = !_isEditing;
                                        });
                                        if (!_isEditing) {
                                          context.read<TtsService>().speak(
                                            "Saving Edits",
                                          );
                                          try {
                                            setState(() {
                                              _reviewText =
                                                  _reviewController.text;
                                            });
                                            await DataService.updateReview(
                                              uid: UserSession.uid!,
                                              mediaId: widget.media.id,
                                              rating: _rating,
                                              review_visibility: _privacyLabel,
                                              reviewText: _reviewText,
                                              finished_on: _date,
                                              spoilers: _spoilers,
                                            );

                                            final reviewData = {
                                              'uid': UserSession.uid!,
                                              'username':
                                                  widget.review.username,
                                              'media_id': widget.media.id,
                                              'rating': _rating,
                                              'review_text':
                                                  _reviewController.text,
                                              'review_visibility':
                                                  _privacyLabel,
                                              'finished_on': _date
                                                  .toIso8601String(),
                                              'spoiler': _spoilers,
                                            };

                                            if (widget.media.id[0] == 'b') {
                                              var review = BookReview.fromJson(
                                                reviewData,
                                              );
                                              var mediaWithReview =
                                                  MediaWithReview(
                                                    media: widget.media,
                                                    review: review,
                                                  );
                                              UserSession.editUserReview(
                                                mediaWithReview,
                                              );
                                            }
                                            if (widget.media.id[0] == 'm') {
                                              var review = MovieReview.fromJson(
                                                reviewData,
                                              );
                                              var mediaWithReview =
                                                  MediaWithReview(
                                                    media: widget.media,
                                                    review: review,
                                                  );
                                              UserSession.editUserReview(
                                                mediaWithReview,
                                              );
                                            }
                                            if (widget.media.id[0] == 't') {
                                              var review =
                                                  TelevisionReview.fromJson(
                                                    reviewData,
                                                  );
                                              var mediaWithReview =
                                                  MediaWithReview(
                                                    media: widget.media,
                                                    review: review,
                                                  );
                                              UserSession.editUserReview(
                                                mediaWithReview,
                                              );
                                            }
                                          } catch (e) {
                                            context.read<TtsService>().speak(
                                              "Failed to Save Edits",
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  "Error posting review: $e",
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          context.read<TtsService>().speak(
                                            "Editing Review",
                                          );
                                        }
                                      },
                                    ),
                                  SizedBox(width: 5),
                                  if (widget.type == MediaCardType.myReview &&
                                      _isEditing) ...[
                                    IconButton(
                                      key: const Key('delete_review_button'),
                                      onPressed: () {
                                        context.read<TtsService>().speak(
                                          "Delete Review",
                                        );
                                        _showDeleteConfirmation(context, theme);
                                      },
                                      icon: const Icon(Icons.delete),
                                      color: Colors.black,
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                    ),
                                  ] else if (widget.type !=
                                      MediaCardType.myReview) ...[
                                    IconButton(
                                      onPressed: () {
                                        context.read<TtsService>().speak(
                                          "Opened Report PopUp",
                                        );
                                        showDialog(
                                          context: context,
                                          builder: (context) => ReportPopUp(
                                            type: "Review",
                                            associatedId:
                                                "${widget.media.type}, ${widget.review.review_id}",
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.flag),
                                      color: Colors.red,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_isEditing) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: StarRatingWidget(
                                      initialRating: _rating,
                                      starSize: 30,
                                      onRatingChanged: (value) {
                                        context.read<TtsService>().speak(
                                          "Rating Changed To: ${value}",
                                        );
                                        _rating = value;
                                      },
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: GestureDetector(
                                      onTap: () =>
                                          _openDatePicker(context, theme),
                                      child: Container(
                                        height: 30,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          "${_date.month}/${_date.day}/${_date.year}",
                                          style: TextStyle(
                                            fontFamily: theme.fontFamily,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.red,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        // black box checkbox
                                        Container(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            key: const Key('edit_spoilers'),
                                            value: _spoilers,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                context.read<TtsService>().speak(
                                                  "Contains Spoilers: ${value}",
                                                );
                                                _spoilers = value ?? false;
                                              });
                                            },
                                            activeColor: Colors.white,
                                            checkColor: Colors.black,
                                            side: const BorderSide(
                                              color: Colors.black,
                                              width: 2,
                                            ),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Contains Spoilers',
                                          style: TextStyle(
                                            fontFamily: theme.fontFamily,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ] else ...[
                                staticStarRating(_rating, size: 35),
                                SizedBox(height: 2),
                                Text(
                                  "${_date.month}/${_date.day}/${_date.year}",
                                  style: TextStyle(
                                    fontFamily: theme.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              if (widget.type == MediaCardType.myReview &&
                                  _isEditing)
                                PrivacySelector(
                                  startLabel: _privacyLabel,
                                  playlist: false,
                                  onChanged: (label) {
                                    setState(() {
                                      context.read<TtsService>().speak(
                                        "Privacy Changed To: ${label}",
                                      );
                                      _privacyLabel = label;
                                    });
                                  },
                                )
                              else
                                Row(
                                  children: [
                                    if (_privacyLabel == "public") ...[
                                      Image.asset(
                                        'assets/icons/public_icon.png',
                                        width: 35,
                                        height: 25,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Public",
                                        style: TextStyle(
                                          fontFamily: theme.fontFamily,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    if (_privacyLabel == "friends only") ...[
                                      Image.asset(
                                        'assets/icons/friends_only_icon.png',
                                        width: 35,
                                        height: 35,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "Friends Only",
                                        style: TextStyle(
                                          fontFamily: theme.fontFamily,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    if (_privacyLabel == "my eyes only") ...[
                                      Image.asset(
                                        'assets/icons/private_icon.png',
                                        width: 35,
                                        height: 25,
                                        fit: BoxFit.cover,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        "My Eyes Only",
                                        style: TextStyle(
                                          fontFamily: theme.fontFamily,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    SizedBox(height: 10),
                                  ],
                                ),
                              Row(
                                children: [
                                  //Pop badge web
                                  if (!_isEditing) ...[
                                    InkWell(
                                      child: !_badgeEarned
                                          ? Image.asset(
                                              'assets/badges/blankBadge.png',
                                              width: 65,
                                              height: 82,
                                              fit: BoxFit.cover,
                                            )
                                          : AlphaMaskedImage(
                                              imageUrl: widget.media.image,
                                              width: 85,
                                              height: 100,
                                            ),

                                      onTap: () async {
                                        if (_badgeEarned) {
                                          final badge =
                                              await DataService.getBadgeWithMediaId(
                                                widget.media.id,
                                              );

                                          if (!mounted) return;

                                          showDialog(
                                            context: context,
                                            useRootNavigator: true,
                                            builder: (context) =>
                                                BadgeEarnedPopUp(
                                                  badge: badge,
                                                  confetti:
                                                      UserSession.uid ==
                                                      widget.review.uid,
                                                ),
                                          );
                                        } else {
                                          showDialog(
                                            context: context,
                                            useRootNavigator: true,
                                            builder: (context) =>
                                                MediaBadgeLockedPopUp(
                                                  media: widget.media,
                                                  type: widget.type,
                                                  username:
                                                      widget.review.username,
                                                ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                  SizedBox(width: 20),
                                  if (!_badgeEarned && !_isEditing && widget.review.uid == UserSession.uid!) ...[
                                    ElevatedButton(
                                      onPressed: () async {
                                        if (UserSession.badgeProcessing) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Your previously submitted image is currently being processed. Please wait a moment and try again.",
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        try {
                                          final result = await FilePicker
                                              .platform
                                              .pickFiles(
                                                type: FileType.image,
                                                withData: true,
                                              );
                                          if (result == null ||
                                              result.files.single.bytes == null)
                                            return;

                                          final file = result.files.single;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Photo is being submitted for badge verification! This may take a moment.",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          );
                                          await DataService.verifyImageMatch(
                                            base64Encode(file.bytes!),
                                            widget.media,
                                            UserSession.uid!,
                                            _handleVerifyReturn,
                                            false,
                                          );
                                        } catch (e) {
                                          debugPrint("Upload failed: $e");
                                          context.read<TtsService>().speak(
                                            "Image Upload Failed",
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Upload failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },

                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          side: const BorderSide(
                                                  color: Colors.black,
                                                  width: 2,
                                                ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 2,
                                        ),
                                        elevation: 0,
                                      ),
                                      child: ComicTitle(
                                        title: 'Use Photo',
                                        size: 14,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              //]
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ---------- REVIEW ----------
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.name != 'Simple'
                                  ? theme.primaryColor
                                  : theme.accentColorThree,
                              width: 2,
                            ),
                            image: DecorationImage(
                              image: AssetImage(theme.subBackgroundImageOne),
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
                                children: [
                                  ComicTitle(title: '$media_type Review'),
                                  Consumer<TTSController>(
                                    builder: (context, ttsController, _) {
                                      if (!ttsController.ttsEnabled)
                                        return SizedBox.shrink();

                                      return IconButton(
                                        icon: Icon(Icons.volume_up),
                                        onPressed: () {
                                          context.read<TtsService>().speak(
                                            "${_reviewController.text}",
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  Spacer(),
                                  if (media_type == 'TV' &&
                                      !_isEditing &&
                                      widget.review.username !=
                                          widget.review.uid) ...[
                                    TextButton(
                                      onPressed: () {
                                        context.read<TtsService>().speak(
                                          "${"Opening Season By Season Review"}",
                                        );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SeasonReviewsPage(
                                                  media:
                                                      widget.media
                                                          as Television,
                                                  review: editedReview,
                                                  type: widget.type,
                                                ),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          side: const BorderSide(
                                            color: AppColors.teamPink,
                                            width: 4,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        "Season Reviews >",
                                        style: TextStyle(
                                          fontFamily: theme.fontFamily,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_reviewText.isNotEmpty || _isEditing) ...[
                                ChatBubble(
                                  message: _reviewController.text,
                                  width: double.infinity,
                                  isEditing: _isEditing,
                                  controller: _reviewController,
                                  spoilers: _spoilers,
                                  mine: widget.review.uid == UserSession.uid,
                                ),
                                const SizedBox(height: 10),
                              ] else ...[
                                Center(
                                  child: Text(
                                    'User did not leave a comment',
                                    style: TextStyle(
                                      fontFamily: theme.fontFamily,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: theme.primaryColor,
                                      backgroundColor:
                                          theme.mainBackgroundColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (!_isEditing) ...[
                          const SizedBox(height: 10),
                          Divider(
                            color: theme.primaryColor,
                            height: 10,
                            thickness: 2,
                            indent: 20,
                            endIndent: 20,
                          ),
                          const SizedBox(height: 10),
                          MediaSection<Review>(
                            title: 'Other Reviews',
                            count: true,
                            onNavigate: () {
                              context.read<TtsService>().speak(
                                "${"Opening Other Reviews of ${widget.media.name}"}",
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MediaReviewsPage(media: widget.media),
                                ),
                              );
                            },
                            borderColor: theme.name != 'Simple'
                                ? theme.primaryColor
                                : theme.accentColorTwo,
                            postReview: false,
                            friendSection: false,
                            sectionHeight: 175,
                            future: _reviews,
                            backgroundImage: theme.subBackgroundImageThree,
                            itemBuilder: (context, review) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
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
                        ],
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
