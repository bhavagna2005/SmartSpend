class UserModel {
  final String uid; // Unique ID from Auth Provider
  final String email;
  final String displayName;
  final String? photoUrl; // Nullable, as user might not have a profile pic
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  // --- JSON SERIALIZATION ---
  
  // Converts JSON from API/Database into a UserModel object
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Converts UserModel object into JSON for API/Database
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}