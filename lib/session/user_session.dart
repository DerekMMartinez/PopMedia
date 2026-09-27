import 'package:pop_media/models/badge.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/media_with_review.dart';
import 'package:pop_media/service/data_service.dart';
import 'package:pop_media/models/user.dart';

class UserSession {
  static String? uid;
  static User? currentUser;
  static List<MediaWithReview>? userReviews;
  static List<MediaWithReview>? userMovieReviews;
  static List<MediaWithReview>? userTVReviews;
  static List<MediaWithReview>? userBookReviews;
  static List<Media>? trending;
  static List<Media>? trendingMovie;
  static List<Media>? trendingTV;
  static List<Media>? trendingBook;
  static List<Media>? recommended;
  static List<Media>? recommendedMovie;
  static List<Media>? recommendedTV;
  static List<Media>? recommendedBook;
  static List<Map<String, dynamic>>? badges;
  //recaps

  //booleans
  static bool uidBool = false;
  static bool userReviewsBool = false;
  static bool userMovieReviewsBool = false;
  static bool userTVReviewsBool = false;
  static bool userBookReviewsBool = false;
  static bool trendingBool  = false;
  static bool trendingMovieBool  = false;
  static bool trendingTVBool  = false;
  static bool trendingBookBool  = false;
  static bool recommendedBool  = false;
  static bool recommendedMovieBool  = false;
  static bool recommendedTVBool  = false;
  static bool recommendedBookBool  = false;
  static bool badgesBool = false;
  static bool badgeProcessing = false;
  //recaps

  //Setters
  static void setUserId(String userId) async {
    uid = userId;
    uidBool = true;
    setUser(await DataService.getUser(userId));
  }

  static void setUser(User user){
    currentUser = user;
  }

  //Add to lists
  static void addUserReview(MediaWithReview newReview) {
    if(newReview.media.id[0] == 'm' && userMovieReviewsBool)
      if(userMovieReviews!.length == 0 || userMovieReviews![0].media.id != newReview.media.id)
        userMovieReviews?.insert(0, newReview);
    if(newReview.media.id[0] == 't' && userTVReviewsBool)
      if(userTVReviews!.length == 0 || userTVReviews![0].media.id != newReview.media.id)
        userTVReviews?.insert(0, newReview);
    if(newReview.media.id[0] == 'b' && userBookReviewsBool)
      if(userBookReviews!.length == 0 || userBookReviews![0].media.id != newReview.media.id)
        userBookReviews?.insert(0, newReview);
    if(userReviewsBool)
      if(userReviews!.length == 0 || userReviews![0].media.id != newReview.media.id)
        userReviews?.insert(0, newReview);

    clearRecommended();
  }

  //edit review
  static void editUserReview(MediaWithReview newReview) {
    if(newReview.media.id[0] == 'm' && userMovieReviewsBool){
      userMovieReviews!.removeWhere((element) =>
          element.media.id == newReview.media.id &&
          element.review!.uid == newReview.review!.uid
      );
      userMovieReviews?.insert(0, newReview);
    }
    if(newReview.media.id[0] == 't' && userTVReviewsBool){
      userTVReviews!.removeWhere((element) =>
          element.media.id == newReview.media.id &&
          element.review!.uid == newReview.review!.uid
      );
      userTVReviews?.insert(0, newReview);
    }
    if(newReview.media.id[0] == 'b' && userBookReviewsBool){
      userBookReviews!.removeWhere((element) =>
          element.media.id == newReview.media.id &&
          element.review!.uid == newReview.review!.uid
      );
      userBookReviews?.insert(0, newReview);
    }
    if(userReviewsBool){
      userReviews!.removeWhere((element) =>
          element.media.id == newReview.media.id &&
          element.review!.uid == newReview.review!.uid
      );
      userReviews?.insert(0, newReview);
    }

    clearRecommended();
  }

  //Get and/or cache lists
  static Future<List<MediaWithReview>> getUserReviews(String uid, String type) async {
    if(type == 'm'){
      if(!userMovieReviewsBool){
        userMovieReviews = await DataService.getUserReviews(uid, uid, type);
        userMovieReviewsBool = true;
      }
      return userMovieReviews!;
    }
    if(type == 't'){
      if(!userTVReviewsBool){
        userTVReviews = await DataService.getUserReviews(uid, uid, type);
        userTVReviewsBool = true;
      }
      return userTVReviews!;
    }
    if(type == 'b'){
      if(!userBookReviewsBool){
        userBookReviews = await DataService.getUserReviews(uid, uid, type);
        userBookReviewsBool = true;
      }
      return userBookReviews!;
    }
    //all
    if(!userReviewsBool){
      userReviews = await DataService.getUserReviews(uid, uid, type);
      userReviewsBool = true;
    }
    return userReviews!;
  }

  static Future<List<Media>> getTrending(String type) async {
    if(type == 'm'){
      if(!trendingMovieBool){
        trendingMovie = await DataService.getTrending(type);
        trendingMovieBool = true;
      }
      return trendingMovie!;
    }
    if(type == 't'){
      if(!trendingTVBool){
        trendingTV = await DataService.getTrending(type);
        trendingTVBool = true;
      }
      return trendingTV!;
    }
    if(type == 'b'){
      if(!trendingBookBool){
        trendingBook = await DataService.getTrending(type);
        trendingBookBool = true;
      }
      return trendingBook!;
    }
    //all
    if(!trendingBool){
      trending = await DataService.getTrending(type);
      trendingBool = true;
    }
    return trending!;
  }

  static Future<List<Media>> getRecForUser(String uid, String type) async {
    if(type == 'm'){
      if(!recommendedMovieBool){
        recommendedMovie = await DataService.getRecForUser(uid, type);
        recommendedMovieBool = true;
      }
      return recommendedMovie!;
    }
    if(type == 't'){
      if(!recommendedTVBool){
        recommendedTV = await DataService.getRecForUser(uid, type);
        recommendedTVBool = true;
      }
      return recommendedTV!;
    }
    if(type == 'b'){
      if(!recommendedBookBool){
        recommendedBook = await DataService.getRecForUser(uid, type);
        recommendedBookBool = true;
      }
      return recommendedBook!;
    }
    //all
    if(!recommendedBool){
      recommended = await DataService.getRecForUser(uid, type);
      recommendedBool = true;
    }
    return recommended!;
  }

  static void clearRecommended() {
    recommended = null;
    recommendedMovie = null;
    recommendedTV = null;
    recommendedBook = null;
    recommendedBool = false;
    recommendedMovieBool = false;
    recommendedTVBool = false;
    recommendedBookBool = false;
  }

  static void clear() {
    uid = null;
    currentUser = null;
    userReviews = null;
    userMovieReviews = null;
    userTVReviews = null;
    userBookReviews = null;
    trending = null;
    trendingMovie = null;
    trendingTV = null;
    trendingBook = null;
    recommended = null;
    recommendedMovie = null;
    recommendedTV = null;
    recommendedBook = null;
    badges = null;

    uidBool = false;
    userReviewsBool = false;
    userMovieReviewsBool = false;
    userTVReviewsBool = false;
    userBookReviewsBool = false;
    trendingBool = false;
    trendingMovieBool = false;
    trendingTVBool = false;
    trendingBookBool = false;
    recommendedBool = false;
    recommendedMovieBool = false;
    recommendedTVBool = false;
    recommendedBookBool = false;
    badgesBool = false;
  }

  static Future<bool> deleteUserReview(String uid, String media_id) async {
    if(await DataService.deleteUserReview(uid, media_id)){
      if(media_id[0] == 'm' && userMovieReviewsBool){
        userMovieReviews!.removeWhere((element) =>
            element.media.id == media_id
        );
      }
      if(media_id[0] == 't' && userTVReviewsBool){
        userTVReviews!.removeWhere((element) =>
            element.media.id == media_id
        );
      }
      if(media_id[0] == 'b' && userBookReviewsBool){
        userBookReviews!.removeWhere((element) =>
            element.media.id == media_id
        );
      }
      if(userReviewsBool){
        userReviews!.removeWhere((element) =>
            element.media.id == media_id
        );
      }
      
      clearRecommended();
      return true;
    }

    return false;
  }

  static Future<List<Map<String, dynamic>>> getBadges(String uid) async {
  if (!badgesBool) {
    final List<Badge> allBadges = [];

    for (int i = 1; i <= 6; i++) {
      final badge = await DataService.getBadge(bid: i.toString());
      allBadges.add(badge);
    }

    final earnedBadges = await DataService.getBadgesEarned(uid);
    final earnedIds = earnedBadges.map((b) => b.bid).toSet();

    for (final earned in earnedBadges) {
      final id = int.tryParse(earned.bid.toString());
      if (id != null && id > 6) {
        allBadges.add(earned);
      }
    }

    badges = allBadges.map<Map<String, dynamic>>((badge) {
      return <String, dynamic>{
        'badge': badge,
        'isEarned': earnedIds.contains(badge.bid),
      };
    }).toList();

    badgesBool = true;
  }

  return badges!;
}

  static void addBadgeEarned(int bid) {
    DataService.postBadgeEarned(bid: bid, uid: UserSession.uid!, earned_at: DateTime.now());
    
    if(badgesBool){
      for (var badgeMap in badges!) {
        final badge = badgeMap['badge'] as Badge;

        if (badge.bid == bid) {
          badgeMap['isEarned'] = true;
          break;
        }
      }
    }
  }

  static void addNewBadge(Badge newBadge) {    
    if(badgesBool){
      try{
        badges!.add(<String, dynamic>{
          'badge': newBadge,
          'isEarned': true,
        });
      }
      catch(e){
        print("add new badge to cache error: ${e}");
      }
    }
  }

  static void updateUsername(String newUsername) {
    if(userMovieReviewsBool) {
      userMovieReviews = userMovieReviews
        ?.map((item) => item.copyWith(
              review: item.review!.copyWith(username: newUsername),
            ))
        .toList();
    }
    if(userTVReviewsBool) {
      userTVReviews = userTVReviews
        ?.map((item) => item.copyWith(
              review: item.review!.copyWith(username: newUsername),
            ))
        .toList();
    }
    if(userBookReviewsBool){
      userBookReviews = userBookReviews
        ?.map((item) => item.copyWith(
              review: item.review!.copyWith(username: newUsername),
            ))
        .toList();
    }
    if(userReviewsBool){
      userReviews = userReviews
        ?.map((item) => item.copyWith(
              review: item.review!.copyWith(username: newUsername),
            ))
        .toList();
    }
  }
  
}