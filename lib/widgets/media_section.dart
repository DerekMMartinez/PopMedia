import 'package:flutter/material.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

class MediaSection<T> extends StatelessWidget {
  final String title;
  final bool count;
  final bool postReview;
  final VoidCallback? onNavigate;
  final VoidCallback? onNavigateUpload;
  final Future<List<T>> future;
  final Widget Function(BuildContext, T) itemBuilder;
  final String? backgroundImage; 
  final double sectionHeight;
  final bool friendSection;
  final Color borderColor;
  final bool? playlistCollaborator;
  final bool? addPlaylist;

  const MediaSection({
    Key? key,
    required this.title,
    required this.count,
    required this.postReview,
    required this.onNavigate,
    this.onNavigateUpload,
    required this.future,
    required this.itemBuilder,
    this.backgroundImage,
    required this.sectionHeight,
    required this.friendSection,
    required this.borderColor,
    this.addPlaylist,
    this.playlistCollaborator,
  }) : super(key: key);

  @override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final theme = context.watch<ThemeController>().currentTheme;

  return FutureBuilder<List<T>>(
    future: future,
    builder: (context, snapshot) {
      final isLoading = snapshot.connectionState == ConnectionState.waiting;
      final hasError = snapshot.hasError;
      final items = snapshot.data ?? [];

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          image: backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(backgroundImage!),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ComicTitle(title: title),
                    if (count && !isLoading && !hasError)
                      Text(" (${items.length})", style: TextStyle(
                            fontFamily: theme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 92, 91, 91),
                          ),),
                    if (count && isLoading)
                      Text(" (...)", style: TextStyle(
                            fontFamily: theme.fontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 92, 91, 91),
                          ),),
                    if (friendSection) _buildFriendInfo(context, theme),
                  ],
                ),
              Row(
                children: [
                  if (onNavigateUpload != null) ...[
                    if (postReview)
                      TextButton(
                        onPressed: onNavigateUpload,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(color: theme.accentColor, width: 4),
                          ),
                        ),
                        child: Text(
                          "Post Review",
                          style: TextStyle(
                            fontFamily: theme.fontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (addPlaylist != null && addPlaylist!)
                        TextButton(
                          onPressed: onNavigateUpload,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: theme.accentColor, width: 4),
                            ),
                          ),
                          child: Text(
                            "Add New Playlist",
                            style: TextStyle(
                              fontFamily: theme.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      if (playlistCollaborator != null && playlistCollaborator!)
                        TextButton(
                          onPressed: onNavigateUpload,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(color: theme.accentColor, width: 4),
                            ),
                          ),
                          child: Text(
                            screenWidth < 500 ? "Manage" : "Manage Collaborators",
                            style: TextStyle(
                              fontFamily: theme.fontFamily,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                  ],
                  if (onNavigate != null) ...[
                    const SizedBox(width: 8), // optional spacing
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Container(
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
                        child: IconButton(
                          key: Key('${title}_button'),
                          icon: Icon(Icons.arrow_forward, color: theme.primaryColor),
                          padding: EdgeInsets.zero,
                          onPressed: onNavigate,
                        ),
                      ),
                    ),
                  ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: sectionHeight,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                      ? Center(child: Text('Error: ${snapshot.error}'))
                      : items.isEmpty
                          ? const Center(child: Text('No items found.'))
                          : ScrollConfiguration(
                              behavior: const MaterialScrollBehavior().copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.trackpad,
                                },
                              ),
                              child: GestureDetector(
                                onHorizontalDragStart: (_) {},
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    return itemBuilder(context, items[index]);
                                  },
                                ),
                              ),
                            ),
            ),
          ],
        ),
      );
    },
  );
}

  Widget _buildFriendInfo(context, theme) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 300,
                height: 350,
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
                        "Friends are people who follow you and you follow them back. \n You can search users in the discover page to make friends.\n Friends will be able to see your friends only posts and vice versa.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: theme.fontFamily,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.mainBackgroundColor,
                        side: BorderSide(color: theme.primaryColor, width: 2),
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
        size: 25,
        color: theme.primaryColor,
      ),
    );
  }
}