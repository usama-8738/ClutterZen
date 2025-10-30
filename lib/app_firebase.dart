import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Central place to access Firebase instances so we can override them in demo
/// or test builds without touching UI code.
class AppFirebase {
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  static void configure({
    FirebaseAuth? authOverride,
    FirebaseFirestore? firestoreOverride,
  }) {
    if (authOverride != null) {
      auth = authOverride;
    }
    if (firestoreOverride != null) {
      firestore = firestoreOverride;
    }
  }

  static void reset() {
    auth = FirebaseAuth.instance;
    firestore = FirebaseFirestore.instance;
  }
}
