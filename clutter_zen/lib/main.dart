import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme.dart';
import 'routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured yet; continue without blocking dev flow.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clutter Zen',
      theme: buildAppTheme(),
      routes: AppRoutes.routes,
      initialRoute: '/splash',
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
 
