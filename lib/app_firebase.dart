import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central place to access Firebase instances so we can override them in demo
/// or test builds without touching UI code.
class AppFirebase {
  AppFirebase._();

  static FirebaseAuth? _authOverride;
  static FirebaseFirestore? _firestoreOverride;

  static FirebaseAuth get auth => _authOverride ?? FirebaseAuth.instance;
  static FirebaseFirestore get firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  static void configure({
    FirebaseAuth? authOverride,
    FirebaseFirestore? firestoreOverride,
  }) {
    _authOverride = authOverride ?? _authOverride;
    _firestoreOverride = firestoreOverride ?? _firestoreOverride;
  }

  static void reset() {
    _authOverride = null;
    _firestoreOverride = null;
  }
}
