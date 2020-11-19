import 'package:arrow/src/request.dart';
import 'package:arrow/src/middlewares/firebase_authentication/firebase_token_claims.dart';
import 'package:arrow/src/middlewares/firebase_authentication/firebase_authentication.dart'
    show firebaseDefaultTokenClaimsContext, firebaseRawTokenClaimsContext;

FirebaseTokenClaims getFirebaseDefaultTokenClaims(Request req) {
  return req.context
      .get<FirebaseTokenClaims>(firebaseDefaultTokenClaimsContext);
}

Map<String, Object> getFirebaseRawTokenClaims(Request req) {
  return (req.context.get(firebaseRawTokenClaimsContext)
      as Map<String, Object>);
}
