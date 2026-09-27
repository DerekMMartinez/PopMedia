import 'review.dart';

class BookReview extends Review{
  @override
  final String uid;
  @override
  final String username;
  final String isbn;
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

  BookReview({required this.uid, required this.username, required this.isbn, required this.review_id, required this.rating, required this.review,  required this.visibility, required this.date, required this.spoilers});

  @override
  BookReview copyWith({
    String? uid,
    String? username,
    String? isbn,
    double? rating,
    String? review,
    String? visibility,
    DateTime? date,
    bool? spoilers,
  }) {
    return BookReview(
      review_id: review_id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      isbn: isbn ?? this.isbn,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      visibility: visibility ?? this.visibility,
      date: date ?? this.date,
      spoilers: spoilers ?? this.spoilers,
    );
  }

  factory BookReview.fromJson(Map<String, dynamic> dict) {
    return BookReview(
      uid: dict['uid'],
      username: dict['username'],
      isbn: dict['media_id'],
      review_id: dict['id'] ?? -1,
      rating: (dict['rating'] as num).toDouble(),
      review: dict['review_text'],
      visibility: dict['review_visibility'],
      date: DateTime.parse(dict['finished_on']),
      spoilers: dict['spoiler'] as bool
    );
  }

  @override
  String get rid => isbn;
}