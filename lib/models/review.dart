abstract class Review{
  String get uid;
  String get username;
  String get rid;
  int get review_id;
  double get rating;
  String get visibility;
  String? get review;
  DateTime get date;
  bool get spoilers;

  Review copyWith({String? username});
}