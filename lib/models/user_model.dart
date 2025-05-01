class AppUser {
  final String uid;
  final String email;
  final String role; // citizen, government, advertiser

  AppUser({required this.uid, required this.email, required this.role});

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'citizen',
    );
  }

  Map<String, dynamic> toMap() {
    return {'email': email, 'role': role};
  }
}
