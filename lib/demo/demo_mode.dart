import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../app_firebase.dart';
import '../backend/fakes/fake_analysis_repository.dart';
import '../backend/fakes/fake_generate_provider.dart';
import '../backend/fakes/fake_storage_repository.dart';
import '../backend/fakes/fake_vision_provider.dart';
import '../backend/registry.dart';

class DemoMode {
  static const bool enabled =
      bool.fromEnvironment('DEMO_MODE', defaultValue: false);
  static const String initialRoute =
      String.fromEnvironment('INITIAL_ROUTE', defaultValue: '/splash');

  static Future<void> configure() async {
    if (!enabled) return;

    final mockUser = MockUser(
      uid: 'demo-user',
      email: 'demo@example.com',
      displayName: 'Demo User',
      photoURL:
          'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=200',
    );
    final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
    final firestore = FakeFirebaseFirestore();

    await _seedDemoData(firestore, mockUser);

    AppFirebase.configure(
      authOverride: auth,
      firestoreOverride: firestore,
    );

    Registry.configure(
      analysis: FakeAnalysisRepository(),
      storage: FakeStorageRepository(),
      vision: FakeVisionProvider(),
      replicate: FakeGenerateProvider(),
    );
  }

  static Future<void> _seedDemoData(
      FakeFirebaseFirestore store, MockUser user) async {
    await store.collection('users').doc(user.uid).set({
      'displayName': user.displayName,
      'email': user.email,
      'scanCredits': 5,
    });

    final now = DateTime.now();
    final analyses = [
      {
        'id': 'living-room',
        'title': 'Living Room Refresh',
        'imageUrl':
            'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=640',
        'organizedImageUrl':
            'https://images.unsplash.com/photo-1493666438817-866a91353ca9?w=640',
        'primaryCategory': 'living room',
        'categories': ['living room', 'decor', 'storage'],
        'labels': ['Messy couch', 'Scattered items', 'Clutter'],
        'clutterScore': 7.8,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'objects': [
          {
            'name': 'Sofa',
            'confidence': 0.92,
            'box': {'left': 0.1, 'top': 0.2, 'width': 0.4, 'height': 0.4}
          },
          {
            'name': 'Coffee table',
            'confidence': 0.74,
            'box': {'left': 0.35, 'top': 0.55, 'width': 0.3, 'height': 0.2}
          },
        ],
      },
      {
        'id': 'workspace',
        'title': 'Workspace Declutter',
        'imageUrl':
            'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=640',
        'organizedImageUrl':
            'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=640',
        'primaryCategory': 'workspace',
        'categories': ['workspace', 'documents', 'electronics'],
        'labels': ['Papers', 'Laptop', 'Messy desk'],
        'clutterScore': 6.1,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'objects': [
          {
            'name': 'Laptop',
            'confidence': 0.88,
            'box': {'left': 0.2, 'top': 0.25, 'width': 0.3, 'height': 0.25}
          },
          {
            'name': 'Notebook',
            'confidence': 0.69,
            'box': {'left': 0.55, 'top': 0.35, 'width': 0.25, 'height': 0.2}
          },
        ],
      },
    ];

    for (final entry in analyses) {
      await store.collection('analyses').doc(entry['id']! as String).set({
        'uid': user.uid,
        'title': entry['title'],
        'imageUrl': entry['imageUrl'],
        'organizedImageUrl': entry['organizedImageUrl'],
        'primaryCategory': entry['primaryCategory'],
        'categories': entry['categories'],
        'labels': entry['labels'],
        'clutterScore': entry['clutterScore'],
        'createdAt': entry['createdAt'],
        'objects': entry['objects'],
      });
    }
  }
}
