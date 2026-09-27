import 'package:pop_media/models/review.dart';

class MovieReview extends Review{
  @override
  final String uid;
  @override
  final String username;
  final String mid;
  @override
  final int review_id;
  @override
  final double rating;
  @override
  final String? review;
  @override
  final String visibility;
  @override
  final DateTime date;
  @override
  final bool spoilers;

  MovieReview({required this.uid, required this.username, required this.mid, required this.review_id, required this.rating, required this.review,  required this.visibility, required this.date, required this.spoilers});

  @override
  MovieReview copyWith({
    String? uid,
    String? username,
    String? mid,
    double? rating,
    String? review,
    String? visibility,
    DateTime? date,
    bool? spoilers,
  }) {
    return MovieReview(
      review_id: review_id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      mid: mid ?? this.mid,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      visibility: visibility ?? this.visibility,
      date: date ?? this.date,
      spoilers: spoilers ?? this.spoilers,
    );
  }

  factory MovieReview.fromJson(Map<String, dynamic> dict) {
    return MovieReview(
      uid: dict['uid'],
      username: dict['username'],
      mid: dict['media_id'],
      review_id: dict['id'] ?? -1,
      rating: (dict['rating'] as num).toDouble(),
      review: dict['review_text'],
      visibility: dict['review_visibility'],
      date: DateTime.parse(dict['finished_on']),
      spoilers: dict['spoiler'] as bool
    );
  }

  @override
  String get rid => mid;
}