class FirebaseTokenClaims {
  String uid;
  DateTime authExpiry;
  String email;
  bool emailVerified;
  bool active;

  FirebaseTokenClaims();

  factory FirebaseTokenClaims.fromJson(Map<String, Object> json) {
    return FirebaseTokenClaims()
      ..uid = json['sub'] as String
      ..email = json['email'] as String
      ..emailVerified = json['email_verified'] as bool
      ..authExpiry =
          DateTime.fromMillisecondsSinceEpoch(((json['exp'] as int) * 1000));
  }

  Map<String, Object> toJson() {
    return {
      'sub': uid,
      'email': email,
      'email_verified': emailVerified,
      'exp': authExpiry.millisecondsSinceEpoch / 1000,
    };
  }
}
