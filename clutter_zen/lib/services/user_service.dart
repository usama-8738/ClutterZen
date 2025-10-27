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
    await store
        .collection('users')
        .doc(uid)
        .set({'scanCredits': credits}, SetOptions(merge: true));
  }

  static Future<void> applyPlan(
    String uid, {
    required String planName,
    required int scanCredits,
    int? creditsTotal,
    bool resetUsage = true,
    FirebaseFirestore? firestore,
  }) async {
    final store = firestore ?? AppFirebase.firestore;
    final payload = <String, Object?>{
      'plan': planName,
      'scanCredits': scanCredits,
      'planUpdatedAt': FieldValue.serverTimestamp(),
    };
    if (creditsTotal != null) {
      payload['creditsTotal'] = creditsTotal;
    } else {
      payload['creditsTotal'] = FieldValue.delete();
    }
    if (resetUsage) {
      payload['creditsUsed'] = 0;
    }
    await store
        .collection('users')
        .doc(uid)
        .set(payload, SetOptions(merge: true));
  }

  static Future<int> getCredits(
    String uid, {
    FirebaseFirestore? firestore,
  }) async {
    final store = firestore ?? AppFirebase.firestore;
    final doc = await store.collection('users').doc(uid).get();
    return doc.data()?['scanCredits'] as int? ?? 0;
  }

  static Future<bool> consumeCredit(
    String uid, {
    FirebaseFirestore? firestore,
  }) async {
    final store = firestore ?? AppFirebase.firestore;
    final ref = store.collection('users').doc(uid);
    return store.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final planName = (data['plan'] as String?) ?? '';
      final creditsTotal = (data['creditsTotal'] as num?)?.toInt();
      final bool unlimited =
          planName.toLowerCase() == 'pro' && (creditsTotal == null || creditsTotal <= 0);
      if (unlimited) {
        return true;
      }
      final current = (data['scanCredits'] as num?)?.toInt() ?? 0;
      if (current <= 0) {
        return false;
      }
      tx.set(ref, {'scanCredits': current - 1}, SetOptions(merge: true));
      return true;
    });
  }

  static Future<void> refundCredit(
    String uid, {
    FirebaseFirestore? firestore,
  }) async {
    final store = firestore ?? AppFirebase.firestore;
    final ref = store.collection('users').doc(uid);
    await store.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? const <String, dynamic>{};
      final planName = (data['plan'] as String?) ?? '';
      final creditsTotal = (data['creditsTotal'] as num?)?.toInt();
      final bool unlimited =
          planName.toLowerCase() == 'pro' && (creditsTotal == null || creditsTotal <= 0);
      if (unlimited) {
        return;
      }
      final current = (data['scanCredits'] as num?)?.toInt() ?? 0;
      tx.set(ref, {'scanCredits': current + 1}, SetOptions(merge: true));
    });
  }
}
