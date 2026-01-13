import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  // --- AI Services ---
  // Prioritize build-time value (dart-define), fallback to .env file
  static String get visionApiKey =>
      _get('VISION_API_KEY', const String.fromEnvironment('VISION_API_KEY'));
  static String get replicateToken => _get('REPLICATE_API_TOKEN',
      const String.fromEnvironment('REPLICATE_API_TOKEN'));

  // --- Google Gemini AI ---
  static String get geminiApiKey =>
      _get('GEMINI_API_KEY', const String.fromEnvironment('GEMINI_API_KEY'));

  // --- Firebase Web Config (Optional - use google-services.json instead for Android/iOS) ---
  static String get firebaseApiKey => _get(
      'FIREBASE_API_KEY', const String.fromEnvironment('FIREBASE_API_KEY'));
  static String get firebaseAuthDomain => _get('FIREBASE_AUTH_DOMAIN',
      const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'));
  static String get firebaseProjectId => _get('FIREBASE_PROJECT_ID',
      const String.fromEnvironment('FIREBASE_PROJECT_ID'));
  static String get firebaseStorageBucket => _get('FIREBASE_STORAGE_BUCKET',
      const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'));
  static String get firebaseMessagingSenderId => _get(
      'FIREBASE_MESSAGING_SENDER_ID',
      const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'));
  static String get firebaseAppId =>
      _get('FIREBASE_APP_ID', const String.fromEnvironment('FIREBASE_APP_ID'));

  // --- Google Sign In ---
  static String get googleServerClientId => _get('GOOGLE_SERVER_CLIENT_ID',
      const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'));

  // --- Dev Toggles ---
  static bool get disableAuthGate {
    if (const bool.fromEnvironment('DISABLE_AUTH_GATE')) return true;
    return dotenv.env['DISABLE_AUTH_GATE']?.toLowerCase() == 'true';
  }

  // --- Helper ---
  static String _get(String key, String buildTimeValue) {
    if (buildTimeValue.isNotEmpty) return buildTimeValue;
    return dotenv.env[key] ?? '';
  }
}
