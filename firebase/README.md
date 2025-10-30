Firebase setup (non-blocking UI):

1) Install CLI and configure project
   - dart pub global activate flutterfire_cli
   - flutterfire configure --project <gcp-project-id>

2) Add keys via dart-define (optional during UI testing)
   - See ENV_TEMPLATE.txt for FIREBASE_* vars
   - Run example (Windows):
     flutter run --dart-define=FIREBASE_API_KEY=%FIREBASE_API_KEY% --dart-define=FIREBASE_APP_ID=%FIREBASE_APP_ID% --dart-define=FIREBASE_PROJECT_ID=%FIREBASE_PROJECT_ID% --dart-define=FIREBASE_MESSAGING_SENDER_ID=%FIREBASE_MESSAGING_SENDER_ID%

3) Apply security rules
   - Firestore: firebase deploy --only firestore:rules
   - Storage:   firebase deploy --only storage:rules

4) Platform config
   - Android:
     * Place google-services.json under android/app/
     * Add Internet/Camera/Photos permissions in AndroidManifest.xml
     * In Firebase console, add SHA-1 and SHA-256 for the app signing key
     * Enable Google Sign-In provider, add reversed client ID if needed
   - iOS:
     * Place GoogleService-Info.plist under ios/Runner/
     * Add camera/photo usage strings to Info.plist (NSCameraUsageDescription, NSPhotoLibraryUsageDescription)
     * Add URL types: reverse client ID from GoogleService-Info.plist for Google Sign-In
     * Enable Sign in with Apple capability and add associated entitlements
   - Web:
     * Ensure web index.html includes the necessary Firebase JS SDK if not using flutterfire-generated options
     * Or supply FIREBASE_* via dart-define (see ENV_TEMPLATE.txt)
   - Phone Auth:
     * Configure reCAPTCHA (web/Android) and APNs (iOS) per Firebase docs

UI will keep working without keys; features that need Firebase will no-op or show placeholders.

