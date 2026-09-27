class Badge {
  final int bid;
  final String name;
  final String type;
  final String? mediaId;
  final String description;
  final String? imageUrl;
  final String howTo;

  Badge({required this.bid, required this.type, required this.name, 
   this.mediaId, required this.description, required this.howTo, this.imageUrl});

  factory Badge.fromJson(Map<String, dynamic> dict) {
    return Badge(
      bid: dict['bid'],
      type: dict['type'],
      name: dict['name'],
      mediaId: dict["media_id"],
      description: dict['description'],
      howTo: dict['how_to'],
      imageUrl: dict['image_url'],
    );
  }
}