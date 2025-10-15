import 'package:firebase_core/firebase_core.dart';
import 'env.dart';

class DefaultFirebaseOptions {
  // Returns null if required values are not provided via Env
  static FirebaseOptions? get currentPlatformOrNull {
    if (Env.firebaseApiKey.isEmpty ||
        Env.firebaseAppId.isEmpty ||
        Env.firebaseMessagingSenderId.isEmpty ||
        Env.firebaseProjectId.isEmpty) {
      return null;
    }
    return FirebaseOptions(
      apiKey: Env.firebaseApiKey,
      appId: Env.firebaseAppId,
      messagingSenderId: Env.firebaseMessagingSenderId,
      projectId: Env.firebaseProjectId,
      authDomain: Env.firebaseAuthDomain.isEmpty ? null : Env.firebaseAuthDomain,
      storageBucket: Env.firebaseStorageBucket.isEmpty ? null : Env.firebaseStorageBucket,
    );
  }
}


