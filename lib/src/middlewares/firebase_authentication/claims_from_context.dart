import 'package:arrow/src/request.dart';
import 'package:arrow/src/middlewares/firebase_authentication/firebase_token_claims.dart';
import 'package:arrow/src/middlewares/firebase_authentication/firebase_authentication.dart'
    show firebaseDefaultClaimsContextId, firebaseRawClaimsContextId;

FirebaseTokenClaims getFirebaseDefaultClaims(Request req) {
  return req.context
      .tryGet<FirebaseTokenClaims>(firebaseDefaultClaimsContextId);
}

Map<String, dynamic> getFirebaseRawTokenClaims(Request req) {
  return req.context.tryGet<Map<String, dynamic>>(firebaseRawClaimsContextId);
}
