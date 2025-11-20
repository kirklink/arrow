class FirebaseTokenClaims {
  final String uid;
  final DateTime authExpiry;
  final String email;
  final bool emailVerified;

  FirebaseTokenClaims(
      this.uid, this.email, this.emailVerified, this.authExpiry);

  factory FirebaseTokenClaims.fromJson(Map<String, Object> json) {
    return FirebaseTokenClaims(
        json['sub'] as String? ?? '',
        json['email'] as String? ?? '',
        json['email_verified'] as bool? ?? false,
        DateTime.fromMillisecondsSinceEpoch(
            ((json['exp'] as int? ?? 0) * 1000)));
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
