import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static Future<void> ensureUserProfile(User? user) async {
    if (user == null) return;
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
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

  static Future<void> updateCredits(String uid, int credits) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'scanCredits': credits,
    });
  }

  static Future<int> getCredits(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['scanCredits'] as int? ?? 0;
  }
}
