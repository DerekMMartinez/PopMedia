class User {
  final String uid;
  final String username;
  final String name;
  final String bio;
  final String imageUrl;
  final String email;
  final bool admin;

  User({required this.uid, required this.username, required this.name, required this.bio,  required this.imageUrl, required this.email, required this.admin});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'],
      username: json['username'],
      name: json['name'],
      bio: json['bio'],
      imageUrl: json['profile_pic_url'],
      email: json['email'],
      admin: json['admin']
    );
  }
}

extension UserCopyWith on User {
  User copyWith({
    String? uid,
    String? email,
    String? username,
    String? name,
    String? bio,
    String? imageUrl,
    bool? admin,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      imageUrl: imageUrl ?? this.imageUrl,
      admin: admin ?? this.admin
    );
  }
}
