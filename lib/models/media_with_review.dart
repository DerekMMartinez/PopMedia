import 'media.dart';
import 'review.dart';

class MediaWithReview {
  final Media media;
  final Review? review;

  MediaWithReview({required this.media, required this.review});

  MediaWithReview copyWith({
    Review? review,
    Media? media,
  }) {
    return MediaWithReview(
      review: review ?? this.review,
      media: media ?? this.media,
    );
  }
}