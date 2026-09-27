import 'package:flutter/material.dart' hide Badge;
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/pages/create_playlist_page.dart';
import 'package:pop_media/pages/my_reviews_page.dart';
import 'package:pop_media/pages/friends_grid.dart';
import 'package:pop_media/pages/my_badges_page.dart';
import 'package:pop_media/pages/playlists_page.dart';
import 'package:pop_media/session/user_session.dart';
import 'package:pop_media/text_speech/tts_service.dart';
import 'package:pop_media/theme/theme_controller.dart';
import 'package:pop_media/widgets/badge_earned_popup.dart';
import 'package:pop_media/widgets/main_scaffold.dart';
import 'package:pop_media/widgets/recap_card.dart';
import 'package:pop_media/widgets/report_popup.dart';
import 'package:pop_media/widgets/text_popup.dart';
import 'package:provider/provider.dart';
import 'package:pop_media/widgets/playlist_card.dart';
import 'followers_list.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/widgets/media_card.dart';
import 'package:pop_media/widgets/comic_title.dart';
import 'package:pop_media/widgets/user_card.dart';
import 'package:pop_media/widgets/badge_card.dart';
import 'package:pop_media/models/user.dart';
import 'package:pop_media/models/media_card_type.dart';
import 'package:pop_media/models/media_with_review.dart';
import 'package:pop_media/widgets/media_section.dart';
import 'package:pop_media/pages/edit_account_page.dart';
import 'package:pop_media/models/badge.dart';

class FollowButton extends StatefulWidget {
  final String followingId;
  final VoidCallback? onFollowChanged;

  const FollowButton({
    super.key,
    required this.followingId,
    this.onFollowChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool? _isFollowing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final isFollowing = await DataService.checkFollow(
        UserSession.uid!,
        widget.followingId,
      );
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_isFollowing == null) return;

    final wasFollowing = _isFollowing!;

    try {
      if (wasFollowing) {
        await DataService.deleteFollow(UserSession.uid!, widget.followingId);

        // Update state
        if (mounted) setState(() => _isFollowing = false);

        context.read<TtsService>().speak("Unfollowed");
        // Show snackbar after state update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully unfollowed!')),
        );
      } else {
        await DataService.createNewFollow(UserSession.uid!, widget.followingId);

        if (mounted) setState(() => _isFollowing = true);

        context.read<TtsService>().speak("Followed");

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Successfully followed!')));

        bool friends = await DataService.checkFriendship(
          UserSession.uid!,
          widget.followingId,
        );
        bool hasBadge = await DataService.checkBadgeEarned(
          UserSession.uid!,
          '6',
        );
        if (!hasBadge && friends) {
          UserSession.addBadgeEarned(6);
          final badge = await DataService.getBadge(bid: '6');
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                BadgeEarnedPopUp(badge: badge, confetti: true),
          );
        }
        hasBadge = await DataService.checkBadgeEarned(widget.followingId, '6');
        if (!hasBadge && friends) {
          DataService.postBadgeEarned(
            bid: 6,
            uid: widget.followingId,
            earned_at: DateTime.now(),
          );
        }
      }

      // Delay slightly to allow snackbar to finish layout
      await Future.delayed(const Duration(milliseconds: 50));

      // Trigger full page reload
      if (widget.onFollowChanged != null) {
        widget.onFollowChanged!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return TextButton(
        onPressed: null,
        child: ComicTitle(title: 'Follow', size: 12),
      );
    }

    return TextButton(
      onPressed: _toggleFollow,
      child: ComicTitle(
        title: _isFollowing == true ? 'Unfollow' : 'Follow',
        size: 12,
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final String userId;
  final bool adminAccess;

  const ProfilePage({
    super.key,
    required this.userId,
    required this.adminAccess,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? _user;
  bool _isLoading = true;
  List<Badge> badges = [];

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      final uid = widget.userId == 'me' ? UserSession.uid! : widget.userId;
      _user = await DataService.getUser(uid);
    } catch (e) {
      print("Error loading user: $e");
      _user = null;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadBadges(String uid) async {
    return UserSession.getBadges(UserSession.uid!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeController>().currentTheme;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final User user = _user!;

    return MainScaffold(
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
                  : Container(color: theme.mainBackgroundColor),
            ),
            Row(
              children: [
                Spacer(),
                Text(
                  "@${user.username}",
                  style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: theme.primaryColor,
                  ),
                ),
                Spacer(),
                if (user.uid != UserSession.uid) ...[
                  IconButton(
                    onPressed: () {
                      context.read<TtsService>().speak("Opened Report PopUp");
                      showDialog(
                        context: context,
                        builder: (context) => ReportPopUp(
                          type: "Profile",
                          associatedId: user.uid,
                        ),
                      );
                    },
                    icon: const Icon(Icons.flag),
                    color: Colors.red,
                  ),
                ],
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile picture
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 40),
                  child: ClipRSuperellipse(
                    borderRadius: BorderRadius.circular(35),
                    child: Image.network(
                      _user!.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Username + stats
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: Text(
                                _user!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: theme.fontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                            if (user.uid != UserSession.uid &&
                                !widget.adminAccess) ...[
                              const SizedBox(width: 10),
                              FollowButton(
                                followingId: user.uid,
                                onFollowChanged: () {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => ProfilePage(
                                        userId: widget.userId,
                                        adminAccess: false,
                                      ),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                            if (user.uid == UserSession.uid ||
                                widget.adminAccess) ...[
                              const SizedBox(width: 10),
                              TextButton(
                                onPressed: () {
                                  context.read<TtsService>().speak(
                                    "Opening Edit Account",
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          EditAccountAccountPage(uid: user.uid),
                                    ),
                                  );
                                },
                                child: ComicTitle(
                                  title: 'Edit Profile',
                                  size: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Stats row
                        FutureBuilder<List<dynamic>>(
                          future: Future.wait([
                            DataService.getReviewCount(uid: user.uid),
                            DataService.getBadgeCount(uid: user.uid),
                            DataService.loadFollowers(user.uid),
                            DataService.loadFollowing(user.uid),
                          ]),
                          builder: (context, countSnapshot) {
                            String reviewCount = "0";
                            String badgeCount = "0";
                            int followersCount = 0;
                            int followingCount = 0;

                            if (countSnapshot.hasData &&
                                countSnapshot.data != null) {
                              final reviews = countSnapshot.data![0];
                              final badges = countSnapshot.data![1];
                              final followers = countSnapshot.data![2];
                              final following = countSnapshot.data![3];

                              if (reviews.isNotEmpty) {
                                reviewCount = reviews;
                              }
                              if (badges.isNotEmpty) {
                                badgeCount = badges;
                              }
                              // Check if the result has an error key (as per DataService implementation)
                              if (followers.isNotEmpty &&
                                  !followers[0].containsKey('error')) {
                                followersCount = followers.length;
                              }
                              if (following.isNotEmpty &&
                                  !following[0].containsKey('error')) {
                                followingCount = following.length;
                              }
                            }

                            return FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () => {
                                      context.read<TtsService>().speak(
                                        "Opening ${user.name}'s Reviews",
                                      ),
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MyReviewsPage(
                                            uid: user.uid,
                                            username: user.name,
                                            hideName: true,
                                          ),
                                        ),
                                      ),
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          countSnapshot.connectionState ==
                                                  ConnectionState.waiting
                                              ? "..."
                                              : "$reviewCount",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          "reviews",
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  InkWell(
                                    onTap: () => {
                                      context.read<TtsService>().speak(
                                        "Opening ${user.name}'s Badges",
                                      ),
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MyBadgesPage(
                                            uid: user.uid,
                                            username: user.name,
                                          ),
                                        ),
                                      ),
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          countSnapshot.connectionState ==
                                                  ConnectionState.waiting
                                              ? "..."
                                              : "$badgeCount",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          "badges",
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  InkWell(
                                    onTap: () => {
                                      context.read<TtsService>().speak(
                                        "Opening ${user.name}'s Followers",
                                      ),
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FollowersListPage(
                                            userId: user.uid,
                                            searchForFollowers: true,
                                          ),
                                        ),
                                      ),
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          countSnapshot.connectionState ==
                                                  ConnectionState.waiting
                                              ? "..."
                                              : "$followersCount",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          "followers",
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 13),
                                  InkWell(
                                    onTap: () => {
                                      context.read<TtsService>().speak(
                                        "Opening ${user.name}'s Following",
                                      ),
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FollowersListPage(
                                            userId: user.uid,
                                            searchForFollowers: false,
                                          ),
                                        ),
                                      ),
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          countSnapshot.connectionState ==
                                                  ConnectionState.waiting
                                              ? "..."
                                              : "$followingCount",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            height: 1,
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                        Text(
                                          "following",
                                          style: TextStyle(
                                            color: theme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 120, left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextPopUp(
                    text: user.bio,
                    maxLines: 1,
                    type: "Profile",
                    user: user,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 145, left: 5, right: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- Following Section ----------------
                  MediaSection<Map<String, dynamic>>(
                    title: user.uid == UserSession.uid || user.uid == 'me'
                        ? 'My Friends'
                        : "${user.name}'s Friends",
                    count: false,
                    onNavigate: () {
                      context.read<TtsService>().speak(
                        "Opening ${user.name}'s Friends",
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FriendsGrid(
                            friends: DataService.getFriends(user.uid),
                            username: user.uid == UserSession.uid
                                ? null
                                : user.name,
                          ),
                        ),
                      );
                    },
                    borderColor: theme.name != 'Simple'
                        ? theme.primaryColor
                        : theme.accentColorTwo,
                    sectionHeight: 160,
                    postReview: false,
                    friendSection: true,
                    future: DataService.getFriends(user.uid),
                    backgroundImage: theme.subBackgroundImageTwo,
                    itemBuilder: (context, userMap) {
                      final uid = userMap['uid'];
                      final profilePicUrl = userMap['profile_pic_url'];

                      if (uid == null || uid is! String) {
                        return const SizedBox.shrink();
                      }

                      return UserCard(uid: uid, profilePicUrl: profilePicUrl);
                    },
                  ),
                  SizedBox(height: 15),
                  // ---------------- My Reviews ----------------
                  MediaSection<MediaWithReview>(
                    title: user.uid == UserSession.uid || user.uid == 'me'
                        ? 'My Reviews'
                        : "${user.name}'s Reviews",
                    count: false,
                    onNavigate: () {
                      context.read<TtsService>().speak(
                        "Opening ${user.name}'s Reviews",
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyReviewsPage(
                            uid: user.uid,
                            username: user.uid == UserSession.uid
                                ? null
                                : user.name,
                            hideName: true,
                          ),
                        ),
                      );
                    },
                    borderColor: theme.name != 'Simple'
                        ? theme.primaryColor
                        : theme.accentColor,
                    sectionHeight: 240,
                    postReview: false,
                    friendSection: false,
                    future: user.uid == UserSession.uid
                        ? UserSession.getUserReviews(user.uid, 'a')
                        : DataService.getUserReviews(
                            UserSession.uid!,
                            user.uid,
                            'a',
                          ),
                    backgroundImage: theme.subBackgroundImageTwo,
                    itemBuilder: (context, mediaWithReview) {
                      return MediaCard(
                        media: mediaWithReview.media,
                        review: mediaWithReview.review,
                        type: user.uid == UserSession.uid || user.uid == 'me'
                            ? MediaCardType.myReview
                            : MediaCardType.friendReview,
                        hideName: true,
                      );
                    },
                  ),

                  //playlists
                  SizedBox(height: 15),
                  MediaSection<Playlist>(
                    title: user.uid == UserSession.uid || user.uid == 'me'
                        ? 'My Playlists'
                        : "${user.name}'s Playlists",
                    count: false,
                    onNavigate:
                        (user.uid == UserSession.uid || user.uid == 'me')
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PlaylistsPage(),
                              ),
                            );
                          }
                        : null,
                    onNavigateUpload: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreatePlaylistPage()),
                      );
                    },
                    sectionHeight: 220,
                    postReview: false,
                    friendSection: false,
                    addPlaylist:
                        user.uid == UserSession.uid || user.uid == 'me',
                    future: DataService.getPlaylists(
                      user.uid,
                      user.uid != UserSession.uid && user.uid != 'me',
                    ),
                    borderColor: theme.name != 'Simple'
                        ? theme.primaryColor
                        : theme.accentColorThree,
                    backgroundImage: theme.subBackgroundImageTwo,
                    itemBuilder: (context, playlist) {
                      return PlaylistCard(playlist: playlist);
                    },
                  ),

                  SizedBox(height: 15),
                  // ---------------- My Badges ----------------
                  MediaSection<dynamic>(
                    title: user.uid == UserSession.uid || user.uid == 'me'
                        ? 'My Badges'
                        : "${user.name}'s Badges",
                    count: false,
                    onNavigate: () {
                      context.read<TtsService>().speak(
                        "Opening ${user.name}'s Badges",
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyBadgesPage(
                            uid: user.uid,
                            username: user.uid == UserSession.uid
                                ? null
                                : user.name,
                          ),
                        ),
                      );
                    },
                    borderColor: theme.name != 'Simple'
                        ? theme.primaryColor
                        : theme.accentColorThree,
                    sectionHeight: 165,
                    postReview: false,
                    friendSection: false,
                    future: user.uid == UserSession.uid
                        ? _loadBadges(user.uid)
                        : DataService.getBadgesEarned(user.uid),
                    backgroundImage: theme.subBackgroundImageTwo,

                    itemBuilder: user.uid == UserSession.uid
                        ? (context, item) {
                            return BadgeCard(
                              badge: item['badge'],
                              isEarned: item['isEarned'],
                            );
                          }
                        : (context, badge) {
                            return BadgeCard(badge: badge, isEarned: true);
                          },
                  ),
                  SizedBox(height: 15),
                  if (user.uid == UserSession.uid || user.uid == 'me') ...[
                    // ---------------- My Recaps Section ----------------
                    MediaSection<dynamic>(
                      title: 'Past Recaps',
                      count: false,
                      onNavigate: null,
                      borderColor: theme.name != 'Simple'
                          ? theme.primaryColor
                          : theme.accentColor,
                      sectionHeight: 200,
                      postReview: false,
                      friendSection: false,
                      future: Future.value(["2025", "2024"]),
                      backgroundImage: theme.subBackgroundImageTwo,
                      itemBuilder: (context, recap) {
                        return RecapCard(year: recap);
                      },
                    ),
                    SizedBox(height: 15),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      currentIndex: user.uid == UserSession.uid ? 4 : null,
    );
  }
}
