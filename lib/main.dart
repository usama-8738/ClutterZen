import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_firebase.dart';
import 'demo/demo_mode.dart';
import 'env.dart';
import 'firebase_options.dart';
import 'routes.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (DemoMode.enabled) {
    await DemoMode.configure();
  } else {
    try {
      final opts = DefaultFirebaseOptions.currentPlatformOrNull;
      if (opts != null) {
        await Firebase.initializeApp(options: opts);
      } else {
        await Firebase.initializeApp();
      }
    } catch (e, stackTrace) {
      debugPrint('Firebase initialization failed: $e');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  runApp(MyApp(
    enableAuthGate: DemoMode.enabled ? false : null,
    initialRoute: DemoMode.enabled ? DemoMode.initialRoute : null,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, bool? enableAuthGate, String? initialRoute})
      : _enableAuthGate = enableAuthGate ?? !Env.disableAuthGate,
        _initialRoute = initialRoute ?? '/onboarding';

  final bool _enableAuthGate;
  final String _initialRoute;

  @override
  Widget build(BuildContext context) {
    if (!_enableAuthGate) {
      return MaterialApp(
        title: 'Clutter Zen',
        theme: buildAppTheme(),
        routes: AppRoutes.routes,
        initialRoute: _initialRoute,
      );
    }

    return StreamBuilder<User?>(
      stream: AppFirebase.auth.authStateChanges(),
      builder: (context, snapshot) {
        final route = snapshot.connectionState == ConnectionState.waiting
            ? '/splash'
            : snapshot.hasData
                ? '/home'
                : '/onboarding';

        return MaterialApp(
          key: ValueKey(route),
          title: 'Clutter Zen',
          theme: buildAppTheme(),
          routes: AppRoutes.routes,
          initialRoute: route,
        );
      },
    );
  }
}
