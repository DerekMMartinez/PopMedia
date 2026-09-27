import 'package:flutter/material.dart';
import 'package:pop_media/models/book.dart';
import 'package:pop_media/models/book_review.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/models/movie.dart';
import 'package:pop_media/models/movie_review.dart';
import 'package:pop_media/models/report.dart';
import 'package:pop_media/models/television.dart';
import 'package:pop_media/models/television_review.dart';
import 'package:pop_media/pages/profile_page.dart';
import 'package:pop_media/pages/single_review_page.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:provider/provider.dart';

class ReportCard extends StatefulWidget {
  final Report report;
  final Future<void> Function() onResolved;

  const ReportCard({
    super.key,
    required this.report,
    required this.onResolved,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final result = await DataService.getUsername(uid: widget.report.reporter);
    if (!mounted) return;
    setState(() {
      username = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;

    return Container(
      padding: const EdgeInsets.all(8),
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
            children: [
              ComicTitle(title: "Report"),
              Spacer(),
              if(!widget.report.resolved)...[
                TextButton(
                  onPressed: () async {
                    await DataService.resolveReport(issue_id: widget.report.issue_id, resolved: true);
                    await widget.onResolved();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.green, width: 4),
                    ),
                  ),
                  child: Text(
                    "Mark Resolved",
                    style: TextStyle(
                      fontFamily: theme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ]
              else...[
                TextButton(
                  onPressed: () async {
                    await DataService.resolveReport(issue_id: widget.report.issue_id, resolved: false);
                    await widget.onResolved();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(color: Colors.green, width: 4),
                    ),
                  ),
                  child: Text(
                    "Mark Unresolved",
                    style: TextStyle(
                      fontFamily: theme.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ]
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Text(
                "Report Type: ${widget.report.type}",
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Spacer(),
              Text(
                "Reporter: ${username ?? 'Loading...'}",
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.report.reason,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: theme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          if (widget.report.type == "Profile")
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ProfilePage(userId: widget.report.associated_id, adminAccess: true),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: theme.accentColor, width: 4),
                ),
              ),
              child: Text(
                "Go To Reported Profile",
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          if (widget.report.type == "Review")
            TextButton(
              onPressed: () async { 
                try {
                  final List<dynamic> reviewInfo = await DataService.getReviewFromReport(associated_id: widget.report.associated_id);

                  if (!context.mounted) return;

                  var review;
                  if(reviewInfo[0] == 'm'){
                    review = MovieReview.fromJson(reviewInfo[1]);
                  }
                  else if(reviewInfo[0] == 't'){
                    review = TelevisionReview.fromJson(reviewInfo[1]);
                  }
                  else{
                    review = BookReview.fromJson(reviewInfo[1]);
                  }

                  var media;
                  if(reviewInfo[0] == 'm'){
                    media = Movie.fromJson(reviewInfo[2]);
                  }
                  else if(reviewInfo[0] == 't'){
                    media = Television.fromJson(reviewInfo[2]);
                  }
                  else{
                    media = Book.fromJson(reviewInfo[2]);
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SingleReviewsPage(
                        review: review,
                        media: media,
                        type: MediaCardType.myReview,
                      ),
                    ),
                  );
                } catch (e) {
                  print("Error loading review/media: $e");
                }
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: theme.accentColor, width: 4),
                ),
              ),
              child: Text(
                "Go To Reported Review",
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          SizedBox(height: 12),
          Text(
            "Date Reported: ${widget.report.created_at.toString().substring(0, 10)}",
            style: TextStyle(
              fontFamily: theme.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}