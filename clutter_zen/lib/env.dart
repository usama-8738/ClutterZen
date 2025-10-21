class Env {
  static const visionApiKey =
      String.fromEnvironment('VISION_API_KEY', defaultValue: '');
  static const replicateToken =
      String.fromEnvironment('REPLICATE_API_TOKEN', defaultValue: '');

  // Optional Firebase web config (for web only setups)
  static const firebaseApiKey =
      String.fromEnvironment('FIREBASE_API_KEY', defaultValue: '');
  static const firebaseAuthDomain =
      String.fromEnvironment('FIREBASE_AUTH_DOMAIN', defaultValue: '');
  static const firebaseProjectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID', defaultValue: '');
  static const firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET', defaultValue: '');
  static const firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID', defaultValue: '');
  static const firebaseAppId =
      String.fromEnvironment('FIREBASE_APP_ID', defaultValue: '');

  // Dev toggle: disable authentication gate for UI testing
  static const disableAuthGate =
      bool.fromEnvironment('DISABLE_AUTH_GATE', defaultValue: false);
}
