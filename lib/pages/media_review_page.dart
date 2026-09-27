import 'package:flutter/material.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/widgets/static_star_rating.dart';
import 'package:pop_media/models/review.dart';
import 'package:pop_media/widgets/generic_media_list.dart';
import 'package:pop_media/widgets/review_card.dart';
import 'package:pop_media/widgets/text_popup.dart';
import 'package:provider/provider.dart';

class MediaReviewsPage extends StatefulWidget {
  final Media media;

  const MediaReviewsPage({super.key, required this.media});

  @override
  State<MediaReviewsPage> createState() => _MediaReviewsPageState();
}

class _MediaReviewsPageState extends State<MediaReviewsPage> {
  bool expanded = false;
  late Future<List<Review>> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = DataService.getMediaReviews(UserSession.uid!, widget.media.id, "", false);
  }

  @override
  Widget build(BuildContext context){
    return MainScaffold(
      currentIndex: null, 
      body: LayoutBuilder(
        builder: (context, constraints){
          final width = constraints.maxWidth;
          final isDesktop = width >= 600;
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
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = context.watch<ThemeController>().currentTheme;

    return Stack(
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
        SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints( minHeight: screenHeight,), 
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 5, 0, 0),
            child: Column (
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
                width: 120,
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
                  border: Border.all(color: Colors.black, width: 2)
                ),
              child:Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    children: [
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
                    ],
                  ),

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Text preview
                  LayoutBuilder(
                  builder: (context, constraints) {
                  return Stack(
                  children: [
                  Text(
                    widget.media.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: theme.fontFamily,
                      fontSize: 14,),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                    onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(widget.media.name),
                        content: SingleChildScrollView(
                          child: Text(widget.media.description),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.only(left: 4),
                    color: Colors.white,
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue,
                    ),
                  ),
                ),
                ),
              ],
              );
            },
            ),
            ],
            ),
            ],
              ),
            ),),
          ],
        ),
        SizedBox(height: 5),
        // ---------- REVIEWS ----------
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
          child: Align(
            alignment: Alignment.centerLeft,
              child:ComicTitle(title: 'Reviews')
            ),
          ),
        const SizedBox(height: 10),
        SizedBox(
          height: 375,
          child: AsyncListBuilder<Review>(
            future: _reviews, //TODO: Check Reviews
            emptyMessage: 'No reviews yet!',
            itemBuilder: (context, review) {
              return ReviewCard(
                media: widget.media,
                review: review,
              );
            },
          )
        ),
        ],
        ),
        )
        ),
        ),
      ],
      );
  }

  Widget _buildWebLayout(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final theme = context.watch<ThemeController>().currentTheme;

  return Stack(
    children: [
      // ---------- BACKGROUND ----------
      Positioned.fill(
        child: Opacity(
          opacity: 0.4,
          child: Image.asset(
            theme.subBackgroundImageOne,
            fit: BoxFit.cover,
          ),
        ),
        ),

      // ---------- CONTENT ----------
      SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: screenHeight),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- LEFT: Summary + Poster ----------
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Summary box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.media.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: theme.fontFamily,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.media.date,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            TextPopUp(text: widget.media.genre, maxLines:2, type: "Genre", media: widget.media),
                            const SizedBox(height: 8),
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  children: [
                                    Text(
                                      widget.media.description,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: theme.fontFamily,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: Text(widget.media.name),
                                              content: SingleChildScrollView(
                                                child: Text(widget.media.description),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.only(left: 4),
                                          color: Colors.white,
                                          child: const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Poster
                      GestureDetector(
                        onTap: () {
                          // Optional: full-screen poster
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.transparent,
                              child: InteractiveViewer(
                                child: Image.network(widget.media.image, fit: BoxFit.contain),
                              ),
                            ),
                          );
                        },
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: Image.network(
                            widget.media.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 24),

                // ---------- RIGHT: Reviews ----------
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ComicTitle(title: 'Reviews'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: screenHeight * 0.8,
                        child: AsyncListBuilder<Review>(
                          future: _reviews, //TODO: Check Reviews
                          emptyMessage: 'No reviews yet!',
                          itemBuilder: (context, review) {
                            return ReviewCard(
                              media: widget.media,
                              review: review,
                            );
                          },
                        ),
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
