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
   - Android: add Internet, Camera, Photos permissions in AndroidManifest; add SHA-1 for Google Sign-In
   - iOS: add camera/photo usage strings to Info.plist; enable Sign In with Apple
   - Phone Auth: configure reCAPTCHA/APNs per Firebase docs

UI will keep working without keys; features that need Firebase will no-op or show placeholders.

