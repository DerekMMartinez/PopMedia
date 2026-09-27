import 'media.dart';

class Movie extends Media{
  final String mid;
  final String title;
  final String overview;
  final String director;
  final String releaseDate;
  final String genre;
  final double rating;
  final String imageUrl;

  Movie({required this.mid, required this.title, required this.overview, 
    required this.director, required this.releaseDate, required this.genre, required this.rating, required this.imageUrl});

  factory Movie.fromJson(Map<String, dynamic> dict) {
    return Movie(
      mid: dict['media_id'],
      title: dict['title'],
      overview: dict['description'],
      director: dict['creator'],
      releaseDate: dict['release_date'],
      genre: dict['genres'] is List ? helper(dict['genres']) : dict['genres']?.toString() ?? '',
      rating: (dict['overall_rating'] == -1 ? 2.5 : dict['overall_rating']as num).toDouble(),
      imageUrl: dict['image'],
    );
  }

  static String helper(List<dynamic> genres){
    String helper = '';
    for(var genre in genres){
      String clean = genre.replaceAll('[', '').replaceAll(']', '').replaceAll(',','').replaceAll("'",'');
      helper += ', ' + clean;
    }
    if(helper != '')
      return helper.substring(2);
    return helper;
  }

   @override
  String get id => mid;

  @override
  String get name => title;

  @override
  String get image => imageUrl;

  @override
  String get date => releaseDate;

  @override
  String get description => overview;

  @override
  String get creator => director;

  @override
  double get rate => rating;

  @override
  String get type => "Movie";
}
