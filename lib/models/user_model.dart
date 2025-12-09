class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarBase64;
  final String? status;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarBase64,
    this.status,
  });

  // з JSON
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarBase64: map['avatarBase64'],
      status: map['status'],
    );
  }

  // в JSON
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarBase64': avatarBase64,
      'status': status,
    };
  }
}