import 'media.dart';

class Television extends Media{
  final String tid;
  final String title;
  final String overview;
  final String director;
  final String releaseDate;
  final String genre;
  final double rating;
  final String imageUrl;
  final int seasonNumber;

  Television({required this.tid, required this.title, required this.overview,  required this.imageUrl, 
    required this.director, required this.releaseDate, required this.rating, required this.genre,
    required this.seasonNumber});

  factory Television.fromJson(Map<String, dynamic> dict) {
    return Television(
      tid: dict['media_id'],
      title: dict['title'],
      overview: dict['description'],
      director: dict['creator'],
      releaseDate: dict['release_date'],
      genre: dict['genres'] is List ? helper(dict['genres']) : dict['genres']?.toString() ?? '',
      rating: (dict['overall_rating'] == -1 ? 2.5 : dict['overall_rating'] as num).toDouble(),
      imageUrl: dict['image'],
      seasonNumber: dict['season_count'] ?? -1,
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
  String get id => tid;

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
  String get type => "Tv";
}
