class Playlist {
  final int pid;
  final String uid; //owner/creator
  final String name;
  final String description;
  final String imageUrl;
  final bool public;

  Playlist({required this.pid, required this.uid, required this.name, 
    required this.description, required this.imageUrl, required this.public});

  factory Playlist.fromJson(Map<String, dynamic> dict) {
    return Playlist(
      pid: dict['pid'],
      uid: dict['uid'],
      name: dict['name'],
      description: dict['description'],
      imageUrl: dict['image_url'],
      public: dict['public'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pid': pid,
      'uid': uid,
      'name': name,
      'description': description,
      'image': imageUrl,
    };
  }
}