import 'package:flutter/material.dart';
import 'package:pop_media/models/season_review.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_controller.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/chat_bubble.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/star_rating.dart';
import 'package:pop_media/widgets/static_star_rating.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

class SeasonCard extends StatefulWidget {
  final int seasonNumber;
  final SeasonReview review;
  final String uid;
  final int review_id;

  const SeasonCard({
    super.key,
    required this.seasonNumber,
    required this.review,
    required this.uid,
    required this.review_id
  });

@override
  State<SeasonCard> createState() => _SeasonCardState();
}

class _SeasonCardState extends State<SeasonCard> {
  bool _isEditing = false;
  late TextEditingController _reviewController = TextEditingController();
  late String _reviewText;
  late bool _spoilers;
  late bool _watched;
  late DateTime _date;
  late double _rating;
  late bool _existsInDb;

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _date = widget.review.date;
    _reviewText = widget.review.review ?? '';
    _reviewController = TextEditingController(text: _reviewText);
    _spoilers = widget.review.spoilers;
    _watched = widget.review.watched;
    _existsInDb = widget.review.watched;
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
          height: 260,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            minimumDate: earliestPossibleDate,
            maximumDate: today,
            initialDateTime: _clampDate(_date),
            onDateTimeChanged: (DateTime date) {
              setState(() {
                context.read<TtsService>().speak("Date Changed To: ${_date.month}/${_date.day}/${_date.year}, ${widget.review.review}");
                _date = _clampDate(date);
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: theme.primaryColor, width: 2),
        color: theme.mainBackgroundColor,
        image: theme.mainBackgroundImage != null
            ? DecorationImage(
                image: AssetImage(theme.mainBackgroundImage!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(theme.imageOpactity),
                  BlendMode.lighten,
                ),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children:[
              ComicTitle(title: "Season ${widget.seasonNumber}"),
              Consumer<TTSController>(
                builder: (context, ttsController, _) {
                  if (!ttsController.ttsEnabled) return SizedBox.shrink();

                  return IconButton(
                    icon: Icon(Icons.volume_up),
                    onPressed: () {
                      context.read<TtsService>().speak("Season ${widget.review.season_number}, ${widget.review.rating} stars, reviewed on ${_date.month}/${_date.day}/${_date.year}, ${widget.review.review}");
                    },
                  );
                },
              ),
              Spacer(),
              if(widget.uid == UserSession.uid)...[
              IconButton(
              icon: Icon(_isEditing ? Icons.check : Icons.edit),
              color: Colors.black,
              style: IconButton.styleFrom(
                backgroundColor: _isEditing ? const Color.fromARGB(255, 136, 236, 139) : Colors.white,
              ),
            onPressed: () async {
              setState(() {
                _isEditing = !_isEditing;
              });
              if (!_isEditing) {
                try {
                  setState(() {
                    context.read<TtsService>().speak("Saving Edits");
                    _reviewText = _reviewController.text;
                    _watched = true;
                  });
                  if(_watched){
                    await DataService.updateSeasonReview(
                      review_id:widget.review.review_id,
                      season_number: widget.seasonNumber,
                      rating: _rating,
                      reviewText: _reviewText,
                      finished_on: _date,
                      spoilers: _spoilers,
                      watched: _watched
                    );
                    
                    _existsInDb = true;
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                          content: Text(
                              "Error posting review: $e")));
                }
              }
            },
          ),
          ],
          if(_isEditing)...[
            IconButton(
              onPressed: () async {
              setState(() {
                _isEditing = !_isEditing;
              });
              if (!_isEditing) {
                try {
                  setState(() {
                    _reviewText = "";
                    _reviewController.text = "";
                    _rating = 0;
                    _date = DateTime.now();
                    _spoilers = false;
                    _watched = false;
                  });
                if(_existsInDb){
                  context.read<TtsService>().speak("Review Deleted");
                  await DataService.deleteSeasonReview(
                    widget.review.review_id,
                    widget.seasonNumber
                  );

                  _existsInDb = false;
                }
                } catch (e) {
                  context.read<TtsService>().speak("Error Deleting Review");
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(
                          content: Text(
                              "Error deleting review: $e")));
                }
              }
            },
              icon: const Icon(Icons.delete),
              color: Colors.black,
              style: IconButton.styleFrom(
                backgroundColor: Colors.red,
              )
            ),  
          ]
            ]
          ),
          if(_isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width:2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: StarRatingWidget(initialRating: _rating, starSize:30,
                    onRatingChanged: (value) {
                      context.read<TtsService>().speak("Rating Changed To: ${value}");
                      _rating = value;
                    },)
                  ),
              ]
              else if(_watched) ...[
                staticStarRating(_rating),
              ],
          const SizedBox(height: 10),
          if (_reviewText.isNotEmpty || _isEditing) ...[
            ChatBubble(
              message: _reviewController.text,
              width: double.infinity,
              isEditing: _isEditing,
              controller: _reviewController,
              spoilers: _spoilers,
              mine: widget.uid == UserSession.uid
            ),
            const SizedBox(height: 10),
          ] else if(_watched)...[
            Center(
              child: Text(
                'User did not leave a comment',
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          ]
          else...[
            if(UserSession.uid! == widget.uid)...[
              Center(
                child: Text(
                  'Tap Edit to Review this Season',
                  style: TextStyle(
                    fontFamily: theme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ]
            else...[
              Center(
                child: Text(
                  "User hasn't reviewed this season",
                  style: TextStyle(
                    fontFamily: theme.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            ]
          ],
          if(_isEditing)...[
            Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width:2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // black box checkbox
                    Container(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _spoilers,
                        onChanged: (bool? value) {
                          setState(() {
                            context.read<TtsService>().speak("Contains Spoilers ${value}");
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
                ),
            SizedBox(height: 5)     
          ],
          Row(
            children: [
              if(_isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width:2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: GestureDetector(
                    onTap: () => _openDatePicker(context),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                      child: Text(
                        "Reviewed On: ${_date.month}/${_date.day}/${_date.year}",
                        style: TextStyle(
                          fontFamily: theme.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ]
              else if(_watched)...[
                Text(
                  "Reviewed On: ${_date.month}/${_date.day}/${_date.year}",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: theme.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ]
            ]
          )
        ]
      )
    );
  }
}