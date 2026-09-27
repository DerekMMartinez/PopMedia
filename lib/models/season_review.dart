class SeasonReview{
  final int review_id;
  final int season_number;
  final double rating;
  final String? review;
  final DateTime date;
  final bool spoilers;
  final bool watched;

  SeasonReview({required this.review_id, required this.season_number, required this.rating, required this.review, required this.date, required this.spoilers, required this.watched});

  factory SeasonReview.fromJson(Map<String, dynamic> dict) {
    return SeasonReview(
      review_id: dict['review_id'],
      season_number: dict['season_number'],
      rating: (dict['rating'] as num).toDouble(),
      review: dict['review_text'],
      date: DateTime.parse(dict['finished_on']),
      spoilers: dict['spoiler'] as bool,
      watched: dict['watched'] as bool
    );
  }
}