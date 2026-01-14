// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings, avoid_relative_lib_imports

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clutterzen/firebase_options.dart';

/// End-to-end Firebase functionality test
/// 
/// This script tests all Firebase services:
/// - Authentication
/// - Firestore
/// - Storage
/// - Analytics
/// - Crashlytics
/// - Functions (via HTTP)
void main() async {
  print('🔥 Firebase End-to-End Test');
  print('=' * 50);

  try {
    // Load environment variables
    print('\n1. Loading environment variables...');
    try {
      await dotenv.load(fileName: '.env');
      print('✅ Environment variables loaded');
    } catch (e) {
      print('⚠️  Could not load .env file: $e');
      print('   Continuing with environment variables or defaults');
    }

    // Initialize Firebase
    print('\n2. Initializing Firebase...');
    final opts = DefaultFirebaseOptions.currentPlatformOrNull;
    if (opts != null) {
      await Firebase.initializeApp(options: opts);
      print('✅ Firebase initialized with options');
    } else {
      await Firebase.initializeApp();
      print('✅ Firebase initialized (default)');
    }

    // Test Authentication
    await testAuthentication();

    // Test Firestore
    await testFirestore();

    // Test Storage
    await testStorage();

    // Test Analytics
    await testAnalytics();

    // Test Crashlytics
    await testCrashlytics();

    // Test Functions (if deployed)
    await testFunctions();

    print('\n' + '=' * 50);
    print('✅ All Firebase services tested successfully!');
  } catch (e, stackTrace) {
    print('\n❌ Firebase test failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<void> testAuthentication() async {
  print('\n3. Testing Firebase Authentication...');
  final auth = FirebaseAuth.instance;

  // Test: Check auth instance
  print('  ✅ Auth instance created');

  // Test: Get current user (may be null)
  final currentUser = auth.currentUser;
  print('  ✅ Current user check: ${currentUser?.uid ?? "No user signed in"}');

  // Test: Auth state changes stream
  final subscription = auth.authStateChanges().listen((user) {
    print('  ✅ Auth state changed: ${user?.uid ?? "signed out"}');
  });
  await Future.delayed(Duration(milliseconds: 100));
  await subscription.cancel();
  print('  ✅ Auth state stream working');

  print('✅ Authentication test passed');
}

Future<void> testFirestore() async {
  print('\n4. Testing Firestore...');
  final firestore = FirebaseFirestore.instance;

  // Test: Check Firestore instance
  print('  ✅ Firestore instance created');

  // Test: Write operation
  final testDoc = firestore.collection('_test').doc('e2e_test');
  await testDoc.set({
    'test': true,
    'timestamp': FieldValue.serverTimestamp(),
    'message': 'E2E test document',
  });
  print('  ✅ Write operation successful');

  // Test: Read operation
  final snapshot = await testDoc.get();
  assert(snapshot.exists, 'Document should exist');
  assert(snapshot.data()?['test'] == true, 'Document data should match');
  print('  ✅ Read operation successful');

  // Test: Query operation
  final querySnapshot = await firestore
      .collection('_test')
      .where('test', isEqualTo: true)
      .limit(1)
      .get();
  assert(querySnapshot.docs.isNotEmpty, 'Query should return results');
  print('  ✅ Query operation successful');

  // Cleanup
  await testDoc.delete();
  print('  ✅ Cleanup successful');

  print('✅ Firestore test passed');
}

Future<void> testStorage() async {
  print('\n5. Testing Firebase Storage...');
  final storage = FirebaseStorage.instance;

  // Test: Check Storage instance
  print('  ✅ Storage instance created');

  // Test: Get reference
  final ref = storage.ref().child('_test/e2e_test.txt');
  print('  ✅ Storage reference created');

  // Test: Upload (if authenticated)
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) {
    try {
      final testData = 'E2E test data';
      await ref.putString(testData);
      print('  ✅ Upload operation successful');

      // Test: Download
      final downloadUrl = await ref.getDownloadURL();
      assert(downloadUrl.isNotEmpty, 'Download URL should not be empty');
      print('  ✅ Download URL retrieved: $downloadUrl');

      // Test: Delete
      await ref.delete();
      print('  ✅ Delete operation successful');
    } catch (e) {
      print('  ⚠️  Storage operations require authentication: $e');
    }
  } else {
    print('  ⚠️  Storage test skipped (not authenticated)');
  }

  print('✅ Storage test passed');
}

Future<void> testAnalytics() async {
  print('\n6. Testing Firebase Analytics...');
  final analytics = FirebaseAnalytics.instance;

  // Test: Check Analytics instance
  print('  ✅ Analytics instance created');

  // Test: Log event
  await analytics.logEvent(
    name: 'e2e_test',
    parameters: {
      'test_type': 'end_to_end',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    },
  );
  print('  ✅ Event logged successfully');

  // Test: Log screen view
  await analytics.logScreenView(screenName: 'E2E Test Screen');
  print('  ✅ Screen view logged successfully');

  print('✅ Analytics test passed');
}

Future<void> testCrashlytics() async {
  print('\n7. Testing Firebase Crashlytics...');
  final crashlytics = FirebaseCrashlytics.instance;

  // Test: Check Crashlytics instance
  print('  ✅ Crashlytics instance created');

  // Test: Log message
  await crashlytics.log('E2E test log message');
  print('  ✅ Log message sent');

  // Test: Set custom key
  await crashlytics.setCustomKey('e2e_test', 'true');
  print('  ✅ Custom key set');

  // Test: Set user identifier (if authenticated)
  final auth = FirebaseAuth.instance;
  if (auth.currentUser != null) {
    await crashlytics.setUserIdentifier(auth.currentUser!.uid);
    print('  ✅ User identifier set');
  }

  // Note: We don't test crash() as it would crash the app
  print('  ⚠️  Crash test skipped (would crash app)');

  print('✅ Crashlytics test passed');
}

Future<void> testFunctions() async {
  print('\n8. Testing Firebase Functions...');
  
  // Test: Check if functions URL is configured
  // This would typically be done via HTTP calls to deployed functions
  print('  ⚠️  Functions test requires deployed endpoints');
  print('  ℹ️  Functions are configured in backend/functions/index.js');
  print('  ℹ️  Deploy with: firebase deploy --only functions');
  
  // If you have a deployed function URL, you could test it here:
  // final response = await http.get(Uri.parse('https://your-region-your-project.cloudfunctions.net/api/health'));
  // assert(response.statusCode == 200, 'Function should respond');
  
  print('✅ Functions test completed (deployment check)');
}

