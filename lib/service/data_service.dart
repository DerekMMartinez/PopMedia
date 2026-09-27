import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pop_media/models/movie.dart';
import 'package:pop_media/models/book.dart';
import 'package:pop_media/models/report.dart';
import 'package:pop_media/models/season_review.dart';
import 'package:pop_media/models/television.dart';
import 'package:pop_media/models/badge.dart';
import 'package:pop_media/models/book_review.dart';
import 'package:pop_media/models/playlist.dart';
import 'package:pop_media/models/review.dart';
import 'package:pop_media/models/television_review.dart';
import 'package:pop_media/models/movie_review.dart';
import 'package:pop_media/models/media.dart';
import 'package:pop_media/models/user.dart';
import 'package:pop_media/models/media_with_review.dart';
import 'package:pop_media/widgets/media_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'dart:io';
import 'package:retry/retry.dart';
import 'package:pop_media/session/user_session.dart';

class DataService {
  // Cross-platform backend URL
  static String get baseUrl {
    return "https://api.thepopmedia.com";
  }

  static String get visionUrl {
    return "http://54.200.180.117:8000";
  }

  // Fetch media titles based on query
  static Future<List<Map<String, dynamic>>> loadMedia(
    String input,
    RadioType type,
  ) async {
    try {
      if (input.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }
      ;

      var mediaType;

      if (type == RadioType.movie)
        mediaType = "m";
      else if (type == RadioType.television)
        mediaType = 't';
      else if (type == RadioType.book)
        mediaType = 'b';
      else
        mediaType = 'a';

      final response = await http.post(
        Uri.parse('$baseUrl/getMediaUsingSearch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'input': input, 'type': mediaType}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> mediaList = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final Map<String, int> titleCounts = {};

        //Count titles for duplicates
        for (final media in mediaList) {
          final title = media['title'];
          titleCounts[title] = (titleCounts[title] ?? 0) + 1;
        }

        //Add year to duplicate titles
        for (final media in mediaList) {
          final title = media['title'];
          if (titleCounts[title]! > 1) {
            final release_date = media['release_date'];
            media['title'] = '$title ($release_date)';
          }
        }

        return mediaList;
      } else {
        print("loadMedia response status code: ${response.statusCode}");
        throw Exception('Failed to load media');
      }
    } catch (e) {
      print("loadMedia Error: $e");
      throw Exception('Failed to load media');
    }
  }

  // Fetch media titles based on query
  static Future<List<Map<String, dynamic>>> discoverSearch(
    String input,
    String type,
  ) async {
    try {
      if (input.trim().isEmpty) {
        throw ArgumentError('Input cannot be empty');
      }
      ;

      final response = await http.post(
        Uri.parse('$baseUrl/getDiscoverSearch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'input': input, 'type': type}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> searchList = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        return searchList;
      } else {
        print("discoverSearch response status code: ${response.statusCode}");
        throw Exception('Failed to load media');
      }
    } catch (e) {
      print("discoverSearch Error: $e");
      throw Exception('Failed to load media');
    }
  }

  //Post a new review to the database
  static Future<void> postReview({
    required String uid,
    required String mediaId,
    required double rating,
    required String review_visibility,
    required String reviewText,
    required DateTime finishedOn,
    required bool spoilers,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/postUserReview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'media_id': mediaId,
          'rating': rating,
          'review_visibility': review_visibility,
          'review_text': reviewText,
          'finished_on': finishedOn.toIso8601String().split('T').first,
          'spoiler': spoilers,
        }),
      );

      if (response.statusCode != 200) {
        print("postReview response status code: ${response.statusCode}");
        throw Exception('Failed to post review');
      }
    } catch (e) {
      print("postReview Error: $e");
      throw Exception('Failed to post review');
    }
  }

  static Future<void> updateReview({
    required String uid,
    required String mediaId,
    required double rating,
    required String reviewText,
    required String review_visibility,
    required DateTime finished_on,
    required bool spoilers,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();

      final response = await http.post(
        Uri.parse('$baseUrl/updateUserReview'),
        headers: {
          'Content-Type': 'application/json',
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          'uid': uid,
          'media_id': mediaId,
          'rating': rating,
          'review_text': reviewText,
          'review_visibility': review_visibility,
          'finished_on': finished_on.toIso8601String().split('T').first,
          'spoiler': spoilers,
        }),
      );

      if (response.statusCode != 200) {
        print("updateReview response status code: ${response.statusCode}");
        throw Exception('Failed to update review');
      }
    } catch (e) {
      print("updateReview Error: $e");
      throw Exception('Failed to update review');
    }
  }

  static Future<void> postUser({
    required String uid,
    required String username,
    required String email,
    required String name,
    required String bio,
    required String profile_pic_url,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/postNewUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'username': username,
          'email': email,
          'name': name,
          'bio': bio,
          'profile_pic_url': profile_pic_url,
        }),
      );

      if (response.statusCode != 200) {
        print("postUser response status code: ${response.statusCode}");
        throw Exception('Failed to create user');
      }
    } catch (e) {
      print("postUser Error: $e");
      throw Exception('Failed to create user');
    }
  }

  //Confirm that a user exists in the database
  static Future<bool> checkUser({required String uid}) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/getCheckUser',
      ).replace(queryParameters: {'uid': uid});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print("checkUser response status code: ${response.statusCode}");
        throw Exception('Something went wrong');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        print('checkUser Unexpected response format');
        throw Exception('Something went wrong');
      }

      return decoded['exists'] == true;
    } catch (e) {
      print("checkUser Error: $e");
      throw Exception('Something went wrong');
    }
  }

  static Future<bool> checkBadgeEarned(String uid, String bid) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/checkBadgeEarned',
      ).replace(queryParameters: {'uid': uid, 'bid': bid});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print("checkBadgeEarned response status code: ${response.statusCode}");
        throw Exception('Something went wrong');
      }

      final decoded = jsonDecode(response.body);

      return decoded;
    } catch (e) {
      print("checkBadgedEarned Error: $e");
      throw Exception('Something went wrong');
    }
  }

  static Future<bool> checkFriendship(
    String request_uid,
    String target_uid,
  ) async {
    try {
      if (request_uid.trim().isEmpty || target_uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/checkFriendship',
      ).replace(queryParameters: {'uid1': request_uid, 'uid2': target_uid});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print("checkFriendship response status code: ${response.statusCode}");
        throw Exception('Something went wrong');
      }

      final decoded = jsonDecode(response.body);

      return decoded;
    } catch (e) {
      print("checkFriendship Error: $e");
      throw Exception('Something went wrong');
    }
  }

  static Future<bool> checkUsernameTaken({
    required String username,
    required String email,
  }) async {
    try {
      if (username.trim().isEmpty) {
        throw ArgumentError('username cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/checkUsernameTaken',
      ).replace(queryParameters: {'username': username, 'email': email});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print(
          "checkUsernameTaken response status code: ${response.statusCode}",
        );
        throw Exception('Something went wrong');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        print('checkUsernameTaken Unexpected response format');
        throw Exception('Something went wrong');
      }
      print("USERNAME EXISTS? = " + decoded['exists'] == true);
      return decoded['exists'] == "true";
    } catch (e) {
      print("checkUserNameTaken Error: $e");
      throw Exception('Something went wrong');
    }
  }

  // Fetch reviews based on a user and what type of reviews (b, m, t, a)
  static Future<List<MediaWithReview>> getUserReviews(
    String request_uid,
    String target_uid,
    String type,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/getUserMediaReviews').replace(
        queryParameters: {
          'request_uid': request_uid,
          'target_uid': target_uid,
          'type': type,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<MediaWithReview> mediaReviews = [];

        for (final mediaReview in data) {
          var review = mediaReview[0];
          var media = mediaReview[1];

          if (media['media_id'][0] == 'm') {
            Movie movie = Movie.fromJson(media);
            MovieReview movieReview = MovieReview.fromJson(review);
            MediaWithReview mediaReview = MediaWithReview(
              media: movie,
              review: movieReview,
            );
            mediaReviews.add(mediaReview);
          } else if (media['media_id'][0] == 't') {
            Television television = Television.fromJson(media);
            TelevisionReview televisionReview = TelevisionReview.fromJson(
              review,
            );
            MediaWithReview mediaReview = MediaWithReview(
              media: television,
              review: televisionReview,
            );
            mediaReviews.add(mediaReview);
          } else if (media['media_id'][0] == 'b') {
            Book book = Book.fromJson(media);
            BookReview bookReview = BookReview.fromJson(review);
            MediaWithReview mediaReview = MediaWithReview(
              media: book,
              review: bookReview,
            );
            mediaReviews.add(mediaReview);
          }
        }

        return mediaReviews;
      } else {
        print("getUserReviews response status code: ${response.statusCode}");
        throw Exception('Failed to load user reviews');
      }
    } catch (e) {
      print("getUserReviews Error: $e");
      throw Exception('Failed to load user reviews');
    }
  }

  // Fetch reviews of friends of the requested user (should only ever be passed 'me')
  static Future<List<MediaWithReview>> getFollowingReviews(
    String uid,
    String type,
  ) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }
      ;
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();

      final uri = Uri.parse(
        '$baseUrl/getFollowingMediaReviews',
      ).replace(queryParameters: {'uid': uid, 'type': type});

      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<MediaWithReview> mediaReviews = [];

        for (final mediaReview in data) {
          var review = mediaReview[0];
          var media = mediaReview[1];

          if (media['media_id'][0] == 'm') {
            Movie movie = Movie.fromJson(media);
            MovieReview movieReview = MovieReview.fromJson(review);
            MediaWithReview mediaReview = MediaWithReview(
              media: movie,
              review: movieReview,
            );
            mediaReviews.add(mediaReview);
          } else if (media['media_id'][0] == 't') {
            Television television = Television.fromJson(media);
            TelevisionReview televisionReview = TelevisionReview.fromJson(
              review,
            );
            MediaWithReview mediaReview = MediaWithReview(
              media: television,
              review: televisionReview,
            );
            mediaReviews.add(mediaReview);
          } else if (media['media_id'][0] == 'b') {
            Book book = Book.fromJson(media);
            BookReview bookReview = BookReview.fromJson(review);
            MediaWithReview mediaReview = MediaWithReview(
              media: book,
              review: bookReview,
            );
            mediaReviews.add(mediaReview);
          }
        }
        return mediaReviews;
      } else {
        print(
          "getFollowingReviews response status code: ${response.statusCode}",
        );
        throw Exception('Failed to load following reviews');
      }
    } catch (e) {
      print("getFollowingReviews Error: $e");
      throw Exception('Failed to load following reviews');
    }
  }

  //get a username based off of a uid
  static Future<String> getUsername({required String uid}) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/getUsername',
      ).replace(queryParameters: {'uid': uid});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print("getUsername response status code: ${response.statusCode}");
        throw Exception('Failed to get username');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        print('getUsername Unexpected response format');
        throw Exception('Failed to get username');
      }

      return decoded['username'];
    } catch (e) {
      print("getUsername Error: $e");
      throw Exception('Failed to get media');
    }
  }

  // Fetch trending media based on what type of media (b, m, t, a)
  static Future<List<Media>> getTrending(String type) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getTrending'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'type': type}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<Media> medias = [];

        for (final key in data.keys) {
          for (final media in data[key]) {
            if (media['media_id'][0] == 'm') {
              Movie movie = Movie.fromJson(media);
              medias.add(movie);
            } else if (media['media_id'][0] == 't') {
              Television television = Television.fromJson(media);
              medias.add(television);
            } else if (media['media_id'][0] == 'b') {
              Book book = Book.fromJson(media);
              medias.add(book);
            }
          }
        }

        return medias;
      } else {
        print("getTrending response status code: ${response.statusCode}");
        throw Exception('Failed to get trending');
      }
    } catch (e) {
      print("getTrending Error: $e");
      throw Exception('Failed to get trending');
    }
  }

  //#returns all users that follow THIS user
  static Future<List<Map<String, dynamic>>> loadFollowers(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();

      final uri = Uri.parse(
        '$baseUrl/fetchFollowers',
      ).replace(queryParameters: {'following_id': userId});

      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        print("loadFollowers response status code: ${response.statusCode}");
        throw Exception('Failed to load followers');
      }
    } catch (e) {
      print("loadFollowers Error: $e");
      throw Exception('Failed to load followers');
    }
  }

  //#returns all users that THIS user follows
  static Future<List<Map<String, dynamic>>> loadFollowing(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();
      final uri = Uri.parse(
        '$baseUrl/fetchFollowing',
      ).replace(queryParameters: {'user_id': userId});

      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        print("loadFollowing response status code: ${response.statusCode}");
        throw Exception('Failed to load following');
      }
    } catch (e) {
      print("loadFollowing Error: $e");
      throw Exception('Failed to load following');
    }
  }

  static Future<User> getUser(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();
      final uri = Uri.parse(
        "$baseUrl/getUser",
      ).replace(queryParameters: {'uid': userId});

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);

        if (data is List && data.isNotEmpty) {
          return User.fromJson(
            data[0],
          ); //the list should only have 1 thing and that's what we want to return
        } else {
          print('getUser Unexpected response format');
          throw Exception("Failed to get user");
        }
      } else {
        print("getUser response status code: ${response.statusCode}");
        throw Exception('Failed to get user');
      }
    } catch (e) {
      print("getUser Error: $e");
      throw Exception('Failed to get user');
    }
  }

  static Future<bool> checkFollow(String user_id, String following_id) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();

      final uri = Uri.parse('$baseUrl/checkFollow').replace(
        queryParameters: {'user_id': user_id, 'following_id': following_id},
      );
      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        return data['is_following'] == true;
      } else {
        print("checkFollow response status code: ${response.statusCode}");
        throw Exception('Something went wrong');
      }
    } catch (e) {
      print("checkFollow Error: $e");
      throw Exception('Something went wrong');
    }
  }

  static Future<void> createNewFollow(
    String user_id,
    String following_id,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();

      final uri = Uri.parse('$baseUrl/createNewFollow').replace(
        queryParameters: {'user_id': user_id, 'following_id': following_id},
      );
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        print("creating follow response 200!");
      } else {
        print("createNewFollow response status code: ${response.statusCode}");
        throw Exception('Failed to follow');
      }
    } catch (e) {
      print("createNewFollow Error: $e");
      throw Exception('Failed to follow');
    }
  }

  static Future<void> deleteFollow(String user_id, String following_id) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();

      final uri = Uri.parse('$baseUrl/deleteFollow').replace(
        queryParameters: {'user_id': user_id, 'following_id': following_id},
      );
      final response = await http.post(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        print("deleting follow response 200!");
      } else {
        print("deleteFollow response status code: ${response.statusCode}");
        throw Exception('Failed to unfollow');
      }
    } catch (e) {
      print("deleteFollow Error: $e");
      throw Exception('Failed to unfollow');
    }
  }

  // Fetch recommended media based on a specific user
  static Future<List<Media>> getRecForUser(String uid, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getRecommendationsForUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'type': type}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Media> medias = [];

        for (final media in data) {
          if (media['media_id'][0] == 'm') {
            Movie movie = Movie.fromJson(media);
            medias.add(movie);
          } else if (media['media_id'][0] == 't') {
            Television television = Television.fromJson(media);
            medias.add(television);
          } else if (media['media_id'][0] == 'b') {
            Book book = Book.fromJson(media);
            medias.add(book);
          }
        }

        return medias;
      } else {
        print("getRecForUser response status code: ${response.statusCode}");
        throw Exception('Failed to load recommended media');
      }
    } catch (e) {
      print("getRecForUser Error: $e");
      throw Exception('Failed to load recommended media');
    }
  }

  // Fetch recommended media based on a specific piece of media
  static Future<List<Media>> getRecForMedia(
    String media_id,
    String type,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getRecommendationsForMedia'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'media_id': media_id, 'type': type}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Media> medias = [];

        for (final media in data) {
          if (media['media_id'][0] == 'm') {
            Movie movie = Movie.fromJson(media);
            medias.add(movie);
          } else if (media['media_id'][0] == 't') {
            Television television = Television.fromJson(media);
            medias.add(television);
          } else if (media['media_id'][0] == 'b') {
            Book book = Book.fromJson(media);
            medias.add(book);
          }
        }
        return medias;
      } else {
        print("getRecForMedia response status code: ${response.statusCode}");
        throw Exception('Failed to load recommended media');
      }
    } catch (e) {
      print("getRecForMedia Error: $e");
      throw Exception('Failed to load recommended media');
    }
  }

  // Fetch recommended media based on a specific piece of media
  static Future<List<Media>> getVibeSearch(
    String uid,
    String type,
    String text,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getRecommendationsForVibeSearch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'type': type, 'text': text}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Media> medias = [];

        for (final media in data) {
          if (media['media_id'][0] == 'm') {
            Movie movie = Movie.fromJson(media);
            medias.add(movie);
          } else if (media['media_id'][0] == 't') {
            Television television = Television.fromJson(media);
            medias.add(television);
          } else if (media['media_id'][0] == 'b') {
            Book book = Book.fromJson(media);
            medias.add(book);
          }
        }

        return medias;
      } else {
        print("getVibeSearch response status code: ${response.statusCode}");
        throw Exception('Failed to load media');
      }
    } catch (e) {
      print("getVibeSearch Error: $e");
      throw Exception('Failed to load media');
    }
  }

  static Future<String> getReviewCount({required String uid}) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/getReviewCount',
      ).replace(queryParameters: {'uid': uid});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print('getReviewCount response status code: ${response.statusCode}');
        throw Exception('Failed to get review count');
      }

      return int.parse(response.body).toString();
    } catch (e) {
      print("getReviewCount Error: $e");
      throw Exception('Failed to get review count');
    }
  }

  static Future<String> getBadgeCount({required String uid}) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/getBadgeCount',
      ).replace(queryParameters: {'uid': uid});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print('getBadgeCount response status code: ${response.statusCode}');
        throw Exception("Failed to get badge count");
      }

      return int.parse(response.body).toString();
    } catch (e) {
      print("getBadgeCount Error: $e");
      throw Exception('Failed to get badge count');
    }
  }

  // Fetch reviews based on a user and what type of reviews (b, m, t, a)
  static Future<List<Review>> getMediaReviews(
    String uid,
    String media_id,
    String reviewUsername,
    bool ignoreCurr,
  ) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }
      ;

      final uri = Uri.parse(
        '$baseUrl/getMediaReviews',
      ).replace(queryParameters: {'media_id': media_id});

      final response = await http.get(uri);

      final List<Review> mediaReviews = [];

      List<Review> sortedReviews;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (media_id[0] == 'b') {
          for (final review in data) {
            if (ignoreCurr && review['username'] == reviewUsername) {
              continue;
            }
            mediaReviews.add(BookReview.fromJson(review));
          }
        } else if (media_id[0] == 'm') {
          for (final review in data) {
            if (ignoreCurr && review['username'] == reviewUsername) {
              continue;
            }
            mediaReviews.add(MovieReview.fromJson(review));
          }
        } else if (media_id[0] == 't') {
          for (final review in data) {
            if (ignoreCurr && review['username'] == reviewUsername) {
              continue;
            }
            mediaReviews.add(TelevisionReview.fromJson(review));
          }
        }

        sortedReviews = await sortMediaReviews(uid, mediaReviews);

        final apiUri = Uri.parse(
          '$baseUrl/getReviewsFromMediaAPI',
        ).replace(queryParameters: {'media_id': media_id});
        final apiResponse = await http.get(apiUri);

        List<Review> apiMediaReviews = [];
        if (apiResponse.statusCode == 200) {
          final data = jsonDecode(apiResponse.body);

          if (media_id[0] == 'b') {
            for (final review in data) {
              if (ignoreCurr && review['username'] == reviewUsername) {
                continue;
              }
              apiMediaReviews.add(BookReview.fromJson(review));
            }
          } else if (media_id[0] == 'm') {
            for (final review in data) {
              if (ignoreCurr && review['username'] == reviewUsername) {
                continue;
              }
              apiMediaReviews.add(MovieReview.fromJson(review));
            }
          } else if (media_id[0] == 't') {
            for (final review in data) {
              if (ignoreCurr && review['username'] == reviewUsername) {
                continue;
              }
              apiMediaReviews.add(TelevisionReview.fromJson(review));
            }
          }
        }

        sortedReviews.addAll(apiMediaReviews);
        return sortedReviews;
      } else {
        print("getMediaReviews response status code: ${response.statusCode}");
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      print("getMediaReviews Error: $e");
      throw Exception('Failed to load reviews');
    }
  }

  static Future<List<Review>> sortMediaReviews(
    String uid,
    List<Review> mediaReviews,
  ) async {
    try {
      final List<Review> myReview = [];
      final List<Review> friendReviews = [];
      final List<Review> followingReviews = [];
      final List<Review> otherReviews = [];

      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();
      final uriFriends = Uri.parse(
        '$baseUrl/getFriends',
      ).replace(queryParameters: {'user_id': uid});

      final responseFriends = await http.get(
        uriFriends,
        headers: {"Authorization": "Bearer $token"},
      );
      final decodedFriends = jsonDecode(responseFriends.body);

      final List<dynamic> friends = decodedFriends
          .map((item) => item['uid'] as String)
          .toList();

      final uri = Uri.parse(
        '$baseUrl/fetchFollowing',
      ).replace(queryParameters: {'user_id': uid});
      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );
      final decoded = jsonDecode(response.body);

      final List<dynamic> following = decoded
          .map((item) => item['uid'] as String)
          .toList();

      for (final review in mediaReviews) {
        if (review.review == null || review.review!.isEmpty) {
          continue;
        }
        if (review.uid == uid) {
          myReview.add(review);
        } else if (friends.contains(review.uid) &&
            review.visibility != "My Eyes Only") {
          friendReviews.add(review);
        } else if (following.contains(review.uid) &&
            review.visibility == "Public") {
          followingReviews.add(review);
        } else if (review.visibility == "Public") {
          otherReviews.add(review);
        }
      }

      final List<Review> allReviews = [];
      allReviews.addAll(myReview);
      allReviews.addAll(friendReviews);
      allReviews.addAll(followingReviews);
      allReviews.addAll(otherReviews);

      return allReviews;
    } catch (e) {
      print("sortMediaReviews Error: $e");
      throw Exception('Failed to sort reviews');
    }
  }

  static Future<void> postBadgeEarned({
    required int bid,
    required String uid,
    required DateTime earned_at,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/postNewBadgeEarned'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bid': bid,
          'uid': uid,
          'earned_at': earned_at.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        print("postBadgeEarned response status code: ${response.statusCode}");
        throw Exception('Failed to post badge earned');
      }
    } catch (e) {
      print("postBadgeEarned Error: $e");
      throw Exception('Failed to post badge earned');
    }
  }

  // Fetch reviews based on a user and what type of reviews (b, m, t, a)
  static Future<List<Badge>> getBadgesEarned(String uid) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }
      ;

      final uri = Uri.parse(
        '$baseUrl/getBadgesEarned',
      ).replace(queryParameters: {'uid': uid});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Badge> badges = [];

        for (final item in data) {
          var badge_earned = item[0];
          var badge = item[1];
          final complete = Badge.fromJson({...badge_earned, ...badge});
          badges.add(complete);
        }

        return badges;
      } else {
        print("getBadgesEarned response status code: ${response.statusCode}");
        throw Exception('Failed to load badges earned');
      }
    } catch (e) {
      print("getBadgesEarned Error: $e");
      throw Exception('Failed to load badges earned');
    }
  }

  //get a username based off of a uid
  static Future<Badge> getBadge({required String bid}) async {
    try {
      if (bid.trim().isEmpty) {
        throw ArgumentError('BID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/getBadge',
      ).replace(queryParameters: {'bid': bid});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print("getBadge response status code: ${response.statusCode}");
        throw Exception('Failed to load badge');
      }

      final decoded = jsonDecode(response.body);
      return Badge.fromJson(decoded[0]);
    } catch (e) {
      print("getBadge Error: $e");
      throw Exception('Failed to load badge');
    }
  }

  static Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();
      final uri = Uri.parse(
        '$baseUrl/getFriends',
      ).replace(queryParameters: {'user_id': userId});

      final response = await http.get(
        uri,
        headers: {"Authorization": "Bearer $token"},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      print("getFriends response status code: ${response.statusCode}");
      throw Exception('Failed to load friends');
    } catch (e) {
      print("getFriends Error: $e");
      throw Exception('Failed to load friends');
    }
  }

  /// Request a presigned upload from your backend.
  /// Returns the parsed JSON map from the server.
  static Future<Map<String, dynamic>> getPreSignedUrl({
    required String fileName,
    String? clientContentType, // optional hint
    String method = 'put',
    String? pictureType, // request 'put' or 'post' (server may ignore)
  }) async {
    try {
      if (pictureType == null) {
        pictureType = "profile";
      }
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();

      final payload = {
        'filename': fileName,
        'method': method,
        'pictureType': pictureType,
        // optionally include a hint about content type (server may ignore)
        if (clientContentType != null) 'contentType': clientContentType,
      };

      final resp = await http.post(
        Uri.parse('$baseUrl/getPreSignedUrl'), // exact route name as backend
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        print('Failed to get presigned URL: ${resp.statusCode}');
        throw Exception('Faled to get presigned url');
      }
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      print("getPresignedUrl Error: $e");
      throw Exception('Failed to get presigned url');
    }
  }

  /// Upload using presigned PUT. Returns true on success.
  /// progressCallback(bytesSent, totalBytes) optional
  static Future<bool> uploadPut(
    String presignedUrl,
    Uint8List bytes, {
    required String contentType,
    void Function(int sent, int total)? progressCallback,
  }) async {
    try {
      // Use a retry policy to tolerate transient network errors
      final r = RetryOptions(maxAttempts: 3);
      return await r.retry(() async {
        // http.put doesn't offer progress; for progress use dio or multipart streaming
        final resp = await http.put(
          Uri.parse(presignedUrl),
          headers: {'Content-Type': contentType},
          body: bytes,
        );
        if (resp.statusCode == 200) return true;
        // S3 PUT returns 200 on success; treat others as errors
        print('S3 PUT failed: ${resp.statusCode}');
        throw Exception('Failed to upload put');
      }, retryIf: (e) => e is http.ClientException || e is SocketException);
    } catch (e) {
      print("uploadPut Error: $e");
      throw Exception('Failed to upload put');
    }
  }

  /// Upload using presigned POST. uploadData is the object returned by boto3.generate_presigned_post()
  /// uploadData: { "url": "...", "fields": {...} }
  static Future<bool> uploadPost(
    String url,
    Map<String, String> fields,
    Uint8List bytes, {
    required String filenameFieldName,
  }) async {
    try {
      // construct multipart/form-data body
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      // add returned fields
      fields.forEach((k, v) {
        request.fields[k] = v;
      });

      // add the file - the field name expected by S3 is 'file'
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filenameFieldName,
        ),
      );

      final streamedResp = await request.send();
      final resp = await http.Response.fromStream(streamedResp);

      // S3 returns 204 or 201 depending on config
      if (resp.statusCode == 204 || resp.statusCode == 201) {
        return true;
      } else {
        print('S3 POST failed: ${resp.statusCode}');
        throw Exception("failed to upload post");
      }
    } catch (e) {
      print("uploadPost Error: $e");
      throw Exception('Failed to upload post');
    }
  }

  /// After successful upload, call the backend to confirm the uploaded objectKey
  static Future<bool> confirmUpload(String objectKey) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final token = await user.getIdToken();

      final resp = await http.post(
        Uri.parse('$baseUrl/confirmUpload'), // must match backend
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'objectKey': objectKey}),
      );

      if (resp.statusCode == 200) {
        // optionally parse JSON and validate
        return true;
      } else {
        print('confirmUpload failed: ${resp.statusCode}');
        throw Exception("Failed to confirm upload");
      }
    } catch (e) {
      print("confirmUpload Error: $e");
      throw Exception('Failed to confirm upload');
    }
  }

  /// Full flow: request presigned, upload, confirm
  static Future<String> uploadProfilePicture({
    required String fileName,
    required Uint8List bytes,
    required String guessedContentType, // e.g., image/jpeg
    void Function(int sent, int total)? progressCallback,
    String? pictureType,
  }) async {
    try {
      final presign = await getPreSignedUrl(
        fileName: fileName,
        clientContentType: guessedContentType,
        method: 'put', // or 'post' if you prefer server to return POST
        pictureType: pictureType,
      );

      final method = (presign['method'] as String?) ?? 'put';
      final objectKey = presign['objectKey'] as String?;
      if (objectKey == null) {
        print("No objectKey returned from presign");
        throw Exception('Failed to upload profile picture');
      }

      // server-returned contentType (use this for upload if present)
      final serverContentType =
          presign['contentType'] as String? ?? guessedContentType;

      if (method == 'put') {
        final uploadUrl = presign['uploadUrl'] as String?;
        if (uploadUrl == null) {
          print("No uploadUrl for put method");
          throw Exception('Failed to upload profile picture');
        }
        await uploadPut(
          uploadUrl,
          bytes,
          contentType: serverContentType,
          progressCallback: progressCallback,
        );
      } else if (method == 'post') {
        final uploadData = presign['uploadData'] as Map<String, dynamic>?;
        if (uploadData == null) {
          print("No uploadData for post method");
          throw Exception('Failed to upload profile picture');
        }
        final url = uploadData['url'] as String;
        final fields = Map<String, String>.from(uploadData['fields'] as Map);
        await uploadPost(url, fields, bytes, filenameFieldName: fileName);
      } else {
        print('Unsupported upload method');
        throw Exception('Failed to upload profile photo');
      }

      // after successful upload, confirm it with backend
      final ok = await confirmUpload(objectKey);
      if (!ok) {
        print("Confirm upload failed");
        throw Exception('Failed to upload profile picture');
      }
      // return CDN url if server included it
      final cdnUrl = presign['cdnUrl'] as String?;
      return cdnUrl ?? objectKey;
    } catch (e) {
      print("uploadProfilePicture Error: $e");
      throw Exception('Failed to upload profile picture');
    }
  }

  static Future<bool> deleteUserReview(String uid, String media_id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/deleteUserReview',
      ).replace(queryParameters: {'uid': uid, 'media_id': media_id});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return true;
      }
      print("deleteUserReview response status code: ${response.statusCode}");
      return false;
    } catch (e) {
      print("deleteUserReview Error: $e");
      return false;
    }
  }

  static Future<double> getBookRating(String media_id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/getBookRatingInfo',
      ).replace(queryParameters: {'book_id': media_id});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        double rating = (data[0] == -1 ? 2.5 : data[0] as num).toDouble();
        return rating;
      }
      print("getBookRating response status code: ${response.statusCode}");
      return -1;
    } catch (e) {
      print("getBookRating Error: $e");
      return -1;
    }
  }

  static Future<bool> deleteUserPhoto(String uid) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/deleteUserPhoto',
      ).replace(queryParameters: {'uid': uid});

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      }
      print("deleteUserPhoto response status code ${response.statusCode}");
      return false;
    } catch (e) {
      print("deleteUserPhoto Error: $e");
      return false;
    }
  }

  static Future<bool> deleteAccount(String uid) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/deleteAccount',
      ).replace(queryParameters: {'uid': uid});

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        await FirebaseAuth.instance.currentUser?.delete();
        return true;
      }
      print("deleteAccount response status code: ${response.statusCode}");
      return false;
    } catch (e) {
      print("deleteAccount Error: $e");
      return false;
    }
  }

  static Future<List<SeasonReview>> getSeasonReviews(int review_id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/getSeasonReviews',
      ).replace(queryParameters: {'review_id': review_id.toString()});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load reviews');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) {
              try {
                return SeasonReview.fromJson(e);
              } catch (err) {
                print("Error parsing item: $e");
                print("Parse error: $err");
                return null;
              }
            })
            .whereType<SeasonReview>()
            .toList();
      }

      if (decoded == null || decoded == 0) {
        print("Empty response from server");
        return [];
      }

      print("Unexpected response type: ${decoded.runtimeType}");
      return [];
    } catch (e) {
      print("getSeasonReviews Error: $e");
      return [];
    }
  }

  static Future<void> updateSeasonReview({
    required int review_id,
    required int season_number,
    required double rating,
    required String reviewText,
    required DateTime finished_on,
    required bool spoilers,
    required bool watched,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/updateSeasonReview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'review_id': review_id,
          'season_number': season_number,
          'rating': rating,
          'review_text': reviewText,
          'finished_on': finished_on.toIso8601String().split('T').first,
          'spoiler': spoilers,
          'watched': watched,
        }),
      );

      if (response.statusCode != 200) {
        print("updateReview response status code: ${response.statusCode}");
        throw Exception('Failed to update review');
      }
    } catch (e) {
      print("updateReview Error: $e");
      throw Exception('Failed to update review');
    }
  }

  static Future<bool> deleteSeasonReview(
    int review_id,
    int season_number,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/deleteSeasonReview').replace(
        queryParameters: {
          'rid': review_id.toString(),
          'season_number': season_number.toString(),
        },
      );

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      }
      print("deleteSeasonReview response status code: ${response.statusCode}");
      return false;
    } catch (e) {
      print("deleteSeasonReview Error: $e");
      return false;
    }
  }

  static Future<void> postReport({
    required String associated_id,
    required String type,
    required String reason,
    required String reporter,
    required DateTime created_at,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/postReport').replace(
        queryParameters: {
          'associated_id': associated_id,
          'type': type,
          'reason': reason,
          'reporter': reporter,
          'created_at': created_at.toIso8601String().split('T').first,
          'resolved': 'false',
        },
      );

      final response = await http.post(uri);

      if (response.statusCode != 200) {
        print(
          "postReport response status code: ${response.statusCode}",
        );
        throw Exception('Failed to post report');
      }
    } catch (e) {
      print("postReport Error: $e");
      throw Exception('Failed to post report');
    }
  }

  static Future<bool> checkAdmin({required String uid}) async {
    try {
      if (uid.trim().isEmpty) {
        throw ArgumentError('UID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/getAdmin',
      ).replace(queryParameters: {'user_id': uid});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print("checkAdmin response status code: ${response.statusCode}");
        throw Exception('Something went wrong');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        print('checkAdmin Unexpected response format');
        throw Exception('Something went wrong');
      }

      return decoded['is_admin'] == true;
    } catch (e) {
      print("checkAdmin Error: $e");
      throw Exception('Something went wrong');
    }
  }

  static Future<List<Report>> getReport({required bool resolved}) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/getReport',
      ).replace(queryParameters: {'resolved': resolved.toString()});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load report');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) {
              try {
                return Report.fromJson(e);
              } catch (err) {
                print("Error parsing item: $e");
                print("Parse error: $err");
                return null;
              }
            })
            .whereType<Report>()
            .toList();
      }

      if (decoded == null || decoded == 0) {
        print("Empty response from server");
        return [];
      }

      print("Unexpected response type: ${decoded.runtimeType}");
      return [];
    } catch (e) {
      print("getReport Error: $e");
      return [];
    }
  }

  static Future<void> resolveReport({
    required int issue_id,
    required bool resolved,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/resolveReport').replace(
        queryParameters: {
          'issue_id': issue_id.toString(),
          'resolved': resolved.toString(),
        },
      );

      final response = await http.post(uri);

      if (response.statusCode != 200) {
        print("resolveReport response status code: ${response.statusCode}");
        throw Exception('Failed to resolve report');
      }
    } catch (e) {
      print("resolveReport Error: $e");
      throw Exception('Failed to resovle report');
    }
  }

  static Future<List<dynamic>> getReviewFromReport({
    required String associated_id,
  }) async {
    try {
      if (associated_id.trim().isEmpty) {
        throw ArgumentError('ID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/getReviewFromReport',
      ).replace(queryParameters: {'associated_id': associated_id});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print(
          "getReviewFromReport response status code: ${response.statusCode}",
        );
        throw Exception('Failed to get review');
      }

      final List<dynamic> data = jsonDecode(response.body);

      print(data);

      return data;
    } catch (e) {
      print("getReviewFromReport Error: $e");
      throw Exception('Failed to get review');
    }
  }

  static Future<List<Playlist>> getPlaylists(String uid, bool public) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/getPlaylists',
      ).replace(queryParameters: {'uid': uid});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Playlist> playlists = [];
        for (final playlist in data) {
          if (!public) {
            playlists.add(Playlist.fromJson(playlist));
          } else if (playlist["public"]) {
            playlists.add(Playlist.fromJson(playlist));
          }
        }

        return playlists;
      } else {
        print("getPlaylists response status code: ${response.statusCode}");
        throw Exception('Failed to load playlists');
      }
    } catch (e) {
      print("getPlaylists Error: $e");
      throw Exception('Failed to load playlists');
    }
  }

  static Future<int> postPlaylist({
    required String uid,
    required String name,
    required String description,
    required String cover_pic_url,
    required bool public,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/postPlaylist').replace(
        queryParameters: {
          'uid': uid,
          'name': name,
          'description': description,
          'image_url': cover_pic_url,
          'public': public.toString(),
        },
      );

      final response = await http.post(uri);

      if (response.statusCode != 200) {
        print("postPlaylist response status code: ${response.statusCode}");
        throw Exception('Failed to post playlist');
      }

      return jsonDecode(response.body);
    } catch (e) {
      print("postPlaylist Error: $e");
      throw Exception('Failed to post playlist');
    }
  }

  static Future<int> updatePlaylist(
    int pid,
    String uid,
    String name,
    String description,
    String imageUrl,
    bool public,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/updatePlaylist').replace(
        queryParameters: {
          'pid': pid.toString(),
          'uid': uid,
          'name': name,
          'description': description,
          'image_url': imageUrl,
          'public': public.toString(),
        },
      );

      final response = await http.post(uri);

      if (response.statusCode != 200) {
        print("updatePlaylist response status code: ${response.statusCode}");
        throw Exception('Failed to update playlist');
      }

      return pid;
    } catch (e) {
      print("updatePlaylist Error: $e");
      throw Exception('Failed to update playlist');
    }
  }

  static Future<bool> deletePlaylist(int pid) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/deletePlaylist',
      ).replace(queryParameters: {'pid': pid.toString()});

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      }
      print("deletePlaylist response status code: ${response.statusCode}");
      return false;
    } catch (e) {
      print("deletePlaylist Error: $e");
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getCollaborators(
    int pid,
    bool includeOwner,
    String ownerId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/getCollaborators').replace(
        queryParameters: {
          'pid': pid.toString(),
          'includeOwner': includeOwner.toString(),
          'ownerId': ownerId,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          return decoded
              .whereType<Map<String, dynamic>>()
              .map((e) {
                try {
                  return e;
                } catch (err) {
                  print("Error parsing item: $e");
                  print("Parse error: $err");
                  return null;
                }
              })
              .whereType<Map<String, dynamic>>()
              .toList();
        }

        if (decoded == null || decoded == 0) {
          print("Empty response from server");
          return [];
        }

        print("Unexpected response type: ${decoded.runtimeType}");
        return [];
      } else {
        print("getCollaborators response status code: ${response.statusCode}");
        throw Exception('Failed to load collaborators');
      }
    } catch (e) {
      print("getCollaborators Error: $e");
      throw Exception('Failed to load collaborators');
    }
  }

  static Future<List<Media>> getPlaylistMedia(int pid, String type) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/getPlaylistMedia',
      ).replace(queryParameters: {'pid': pid.toString(), 'media_type': type});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded is List) {
          final List<Media> medias = [];

          for (final item in decoded) {
            if (item is! Map<String, dynamic>) {
              continue;
            }

            try {
              final mediaId = item['media_id'];

              if (mediaId == null || mediaId is! String || mediaId.isEmpty) {
                print("Invalid media_id");
                continue;
              }

              if (mediaId[0] == 'm') {
                medias.add(Movie.fromJson(item));
              } else if (mediaId[0] == 't') {
                medias.add(Television.fromJson(item));
              } else if (mediaId[0] == 'b') {
                medias.add(Book.fromJson(item));
              } else {
                print("Unknown media type");
              }
            } catch (err) {
              print("Error parsing item: $item");
              print("Parse error: $err");
            }
          }

          return medias;
        }

        if (decoded == null || decoded == 0) {
          print("Empty response from server");
          return [];
        }

        print("Unexpected response type: ${decoded.runtimeType}");
        return [];
      } else {
        print("getPlaylistMedia response status code: ${response.statusCode}");
        throw Exception('Failed to load playlist media');
      }
    } catch (e) {
      print("getPlaylists Error: $e");
      throw Exception('Failed to load playlists');
    }
  }

  static Future<bool> addMediaToPlaylist(int pid, String media_id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/addMediaToPlaylist',
      ).replace(queryParameters: {'pid': pid.toString(), 'media_id': media_id});

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      }
      print("addMediaToPlaylist response status code: ${response.statusCode}");
      return false;
    } catch (e) {
      print("addMediaToPlaylist Error: $e");
      return false;
    }
  }

  static Future<bool> addCollaboratorToPlaylist(int pid, String uid) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/addCollaboratorToPlaylist',
      ).replace(queryParameters: {'pid': pid.toString(), 'uid': uid});

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      }
      print(
        "addCollaboratorToPlaylist response status code: ${response.statusCode}",
      );
      return false;
    } catch (e) {
      print("addCollaboratorToPlaylist Error: $e");
      return false;
    }
  }

  static Future<bool> deleteCollaboratorFromPlaylist(
    int pid,
    String uid,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/deleteCollaboratorFromPlaylist',
      ).replace(queryParameters: {'pid': pid.toString(), 'uid': uid});

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      }
      print(
        "deleteCollaboratorFromPlaylist response status code: ${response.statusCode}",
      );
      return false;
    } catch (e) {
      print("deleteCollaboratorFromPlaylist Error: $e");
      return false;
    }
  }

  static Future<bool> deleteMediaFromPlaylist(int pid, String media_id) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/deleteMediaFromPlaylist',
      ).replace(queryParameters: {'pid': pid.toString(), 'media_id': media_id});

      final response = await http.post(uri);

      if (response.statusCode == 200) {
        return true;
      }
      print(
        "deleteMediaFromPlaylist response status code: ${response.statusCode}",
      );
      return false;
    } catch (e) {
      print("deleteMediaFromPlaylist Error: $e");
      return false;
    }
  }

  static List<dynamic> getReviewMediaList(List<dynamic> list) {
    List<dynamic> mediaReviews = [];

    for (final mediaReview in list) {
      var review = mediaReview[0];
      var media = mediaReview[1];

      if (media['media_id'][0] == 'm') {
        Movie movie = Movie.fromJson(media);
        MovieReview movieReview = MovieReview.fromJson(review);
        List<dynamic> mediaReview = [movieReview, movie];
        mediaReviews.add(mediaReview);
      } else if (media['media_id'][0] == 't') {
        Television television = Television.fromJson(media);
        TelevisionReview televisionReview = TelevisionReview.fromJson(review);
        List<dynamic> mediaReview = [televisionReview, television];
        mediaReviews.add(mediaReview);
      } else if (media['media_id'][0] == 'b') {
        Book book = Book.fromJson(media);
        BookReview bookReview = BookReview.fromJson(review);
        List<dynamic> mediaReview = [bookReview, book];
        mediaReviews.add(mediaReview);
      }
    }
    return mediaReviews;
  }

  static List<dynamic> getBadgesList(List<dynamic> badges_data) {
    List<dynamic> result_badges = [];

    for (final badge_json in badges_data) {
      final dejson = Badge.fromJson(badge_json);
      result_badges.add(dejson);
    }

    return result_badges;
  }

  static Future<Map<String, dynamic>> getAnnualRecapForUser({
    required String uid,
    String? year,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/getAnnualRecapDataForUser').replace(
        queryParameters: {
          'uid': uid,
          if (year != null && year.isNotEmpty) 'year': year,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print("getRecapForUser response status code: ${response.statusCode}");
        throw Exception('Failed to get annual recap data for user');
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      List<dynamic> favorite_movies = getReviewMediaList(
        data['favorite_movies'],
      );
      List<dynamic> favorite_books = getReviewMediaList(data['favorite_books']);
      List<dynamic> favorite_tv = getReviewMediaList(data['favorite_tv']);

      data['favorite_movies'] = favorite_movies;
      data['favorite_books'] = favorite_books;
      data['favorite_tv'] = favorite_tv;

      List<dynamic> badges_earned = getBadgesList(data['badges_earned']);
      data['badges_earned'] = badges_earned;

      return data;
    } catch (e) {
      print("getRecapForUser response status code: $e");
      throw Exception('Failed to get annual recap data for user');
    }
  }

  static Future<bool> verifyImageMatch(
    String base64image,
    Media media,
    String uid,
    void Function(bool result)? onComplete,
    bool stillUploading,
  ) async {
    UserSession.badgeProcessing = true;
    bool accepted = false;

    try {
      var jsonBody = jsonEncode({
        'canonical_image_url': media.image,
        'uid': uid,
        'metadata': {'name': media.name, 'id': media.id},
        'stillUploading': stillUploading,
        'user_image_base64': base64image,
      });

      final response = await http.post(
        Uri.parse('$visionUrl/verifyImageMatch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonBody,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        accepted = decoded['accepted'] == true;
        return accepted;
      } else {
        throw Exception('Failed to verify scanned image');
      }
    } catch (e) {
      print("Error in verifying: $e");
      return false;
    } finally {
      UserSession.badgeProcessing = false;
      onComplete?.call(accepted);
    }
  }

  static Future<bool> postMediaBadgeEarned(
    String media_id,
    String uid,
    String name,
    String image_url,
  ) async {
    final uri = Uri.parse('$baseUrl/postMediaBadgeEarned').replace(
      queryParameters: {
        'media_id': media_id,
        'uid': uid,
        'name': name,
        'image_url': image_url,
      },
    );
    final response = await http.post(uri);
    if (response.statusCode != 200) {
      print(
        "postMediaBadgeEarned response status code: ${response.statusCode}",
      );
      throw Exception('Failed to post badge earned');
    } else
      return true;
  }

  static Future<bool> checkMediaBadgeEarned(
    String mediaId,
    String userId,
  ) async {
    try {
      if (mediaId.trim().isEmpty || userId.trim().isEmpty) {
        throw ArgumentError('Media ID and User ID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/checkMediaBadgeEarned',
      ).replace(queryParameters: {'media_id': mediaId, 'uid': userId});

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        print(
          "checkMediaBadgeEarned response status code: ${response.statusCode}",
        );
        throw Exception('Failed to check badge');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        print('checkMediaBadgeEarned Unexpected response format');
        throw Exception('Failed to check badge');
      }

      return decoded['earned'] == true;
    } catch (e) {
      print("checkMediaBadgeEarned Error: $e");
      throw Exception('Failed to check badge');
    }
  }

  static Future<Badge> getBadgeWithMediaId(String mediaId) async {
    try {
      if (mediaId.trim().isEmpty) {
        throw ArgumentError('Media ID cannot be empty');
      }

      final uri = Uri.parse(
        '$baseUrl/getBadgeWithMediaId',
      ).replace(queryParameters: {'media_id': mediaId});

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        print(
          "getBadgeWithMediaId response status code: ${response.statusCode}",
        );
        throw Exception('Failed to load badge');
      }

      final decoded = jsonDecode(response.body);
      return Badge.fromJson(decoded);
    } catch (e) {
      print("getBadgeWithMediaId Error: $e");
      throw Exception('Failed to load badge: $e');
    }
  }

  Future<List<MediaWithReview>> getTopMedia(
    String request_uid,
    String target_uid,
    String type,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/getUserMediaReviews').replace(
        queryParameters: {
          'request_uid': request_uid,
          'target_uid': target_uid,
          'type': type,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<MediaWithReview> mediaReviews = [];

        for (final mediaReview in data) {
          var review = mediaReview[0];
          var media = mediaReview[1];

          if (media['media_id'][0] == 'm') {
            Movie movie = Movie.fromJson(media);
            MovieReview movieReview = MovieReview.fromJson(review);
            MediaWithReview mediaReview = MediaWithReview(
              media: movie,
              review: movieReview,
            );
            mediaReviews.add(mediaReview);
          } else if (media['media_id'][0] == 't') {
            Television television = Television.fromJson(media);
            TelevisionReview televisionReview = TelevisionReview.fromJson(
              review,
            );
            MediaWithReview mediaReview = MediaWithReview(
              media: television,
              review: televisionReview,
            );
            mediaReviews.add(mediaReview);
          } else if (media['media_id'][0] == 'b') {
            Book book = Book.fromJson(media);
            BookReview bookReview = BookReview.fromJson(review);
            MediaWithReview mediaReview = MediaWithReview(
              media: book,
              review: bookReview,
            );
            mediaReviews.add(mediaReview);
          }
        }

        return mediaReviews;
      } else {
        print("getUserReviews response status code: ${response.statusCode}");
        throw Exception('Failed to load user reviews');
      }
    } catch (e) {
      print("getUserReviews Error: $e");
      throw Exception('Failed to load user reviews');
    }
  }
}
