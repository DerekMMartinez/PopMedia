import 'media.dart';

class Book extends Media{
  final String isbn;
  final String title;
  final String summary;
  final String author;
  final String publicationYear;
  final String genre;
  final double rating;
  final String imageUrl;

  Book({required this.isbn, required this.title, required this.summary, 
    required this.author, required this.publicationYear, required this.genre, required this.rating, 
    required this.imageUrl});

  factory Book.fromJson(Map<String, dynamic> dict) {
    return Book(
      isbn: dict['media_id'],
      title: dict['title'],
      summary: dict['description'],
      author: dict['creator'],
      publicationYear: dict['release_date'],
      genre: dict['genres'] is List ? helper(dict['genres']) : dict['genres']?.toString() ?? '',
      rating: (dict['overall_rating'] == -1 ? 2.5 : dict['overall_rating'] as num).toDouble(),
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
  String get id => isbn;

  @override
  String get name => title;

  @override
  String get image => imageUrl;

  @override
  String get date => publicationYear;

  @override
  String get description => summary;

  @override
  String get creator => author;

  @override
  double get rate => rating;

  @override
  String get type => "Book";
}