import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/vision_models.dart';

class AnalysisRepository {
  AnalysisRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> saveAnalysis({required String imageUrl, required VisionAnalysis analysis}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    await _db.collection('analyses').add({
      'uid': uid,
      'imageUrl': imageUrl,
      'labels': analysis.labels,
      'objects': analysis.objects.map((o) => {
        'name': o.name,
        'confidence': o.confidence,
        'box': {
          'left': o.box.left,
          'top': o.box.top,
          'width': o.box.width,
          'height': o.box.height,
        }
      }).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}


