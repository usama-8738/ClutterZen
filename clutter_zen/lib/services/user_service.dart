import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../app_firebase.dart';

class UserService {
  static Future<void> ensureUserProfile(
    User? user, {
    FirebaseFirestore? firestore,
  }) async {
    if (user == null) return;
    final store = firestore ?? AppFirebase.firestore;
    final doc = store.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'displayName': user.displayName,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'scanCredits': 3,
      });
    }
  }

  static Future<void> updateCredits(
    String uid,
    int credits, {
    FirebaseFirestore? firestore,
  }) async {
    final store = firestore ?? AppFirebase.firestore;
    await store.collection('users').doc(uid).update({
      'scanCredits': credits,
    });
  }

  static Future<int> getCredits(
    String uid, {
    FirebaseFirestore? firestore,
  }) async {
    final store = firestore ?? AppFirebase.firestore;
    final doc = await store.collection('users').doc(uid).get();
    return doc.data()?['scanCredits'] as int? ?? 0;
  }
}
