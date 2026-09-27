import 'review.dart';

class TelevisionReview extends Review{
  @override
  final String uid;
  @override
  final String username;
  final String tid;
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

  TelevisionReview({required this.uid, required this.username, required this.tid, required this.review_id, required this.rating, required this.review,  required this.visibility, required this.date, required this.spoilers});

  @override
  TelevisionReview copyWith({
    String? uid,
    String? username,
    String? tid,
    double? rating,
    String? review,
    String? visibility,
    DateTime? date,
    bool? spoilers,
  }) {
    return TelevisionReview(
      review_id: review_id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      tid: tid ?? this.tid,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      visibility: visibility ?? this.visibility,
      date: date ?? this.date,
      spoilers: spoilers ?? this.spoilers,
    );
  }
  
  factory TelevisionReview.fromJson(Map<String, dynamic> dict) {
    return TelevisionReview(
      uid: dict['uid'],
      username: dict['username'],
      tid: dict['media_id'],
      review_id: dict['id'] ?? -1,
      rating: (dict['rating'] as num).toDouble(),
      review: dict['review_text'],
      visibility: dict['review_visibility'],
      date: DateTime.parse(dict['finished_on']),
      spoilers: dict['spoiler'] as bool
    );
  }

  @override
  String get rid => tid;
}