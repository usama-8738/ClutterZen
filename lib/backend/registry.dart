import 'package:firebase_storage/firebase_storage.dart';

import '../app_firebase.dart';
import '../env.dart';
import 'interfaces/analysis_repository.dart';
import 'interfaces/storage_repository.dart';
import 'interfaces/vision_provider.dart';
import 'interfaces/generate_provider.dart';
import 'firebase/firebase_analysis_repository.dart';
import 'firebase/firebase_storage_repository.dart';
import '../services/vision_service.dart';
import '../models/vision_models.dart';
import '../services/replicate_service.dart';
import 'fakes/fake_analysis_repository.dart';
import 'fakes/fake_storage_repository.dart';
import 'fakes/fake_vision_provider.dart';
import 'fakes/fake_generate_provider.dart';
// import 'firebase/firebase_functions_provider.dart'; // Uncomment when Functions are deployed
import 'interfaces/local_store.dart';
import 'local/shared_prefs_store.dart';
import 'fakes/fake_local_store.dart';
import 'dart:typed_data';

class BackendRegistry {
  BackendRegistry._();

  static IAnalysisRepository analysisRepository() {
    // If Firestore available, prefer Firebase; otherwise fall back to fake
    try {
      return FirebaseAnalysisRepository(AppFirebase.firestore);
    } catch (_) {
      return FakeAnalysisRepository();
    }
  }

  static IStorageRepository storageRepository() {
    try {
      return FirebaseStorageRepository(FirebaseStorage.instance);
    } catch (_) {
      return FakeStorageRepository();
    }
  }

  static IVisionProvider visionProvider() {
    // Priority 1: Use Firebase Functions (most secure, recommended for production)
    // Uncomment when Functions are deployed with API keys configured
    // try {
    //   return FirebaseFunctionsVisionProvider();
    // } catch (e) {
    //   // Fall through to direct API if Functions fail
    // }
    
    // Priority 2: Use direct API if keys provided (development/testing)
    if (Env.visionApiKey.isNotEmpty) {
      final svc = VisionService(apiKey: Env.visionApiKey);
      return _VisionAdapter(svc);
    }
    
    // Priority 3: Fallback to fake provider (for UI testing)
    return FakeVisionProvider();
  }

  static IGenerateProvider generateProvider() {
    // Priority 1: Use Firebase Functions (most secure, recommended for production)
    // Uncomment when Functions are deployed with API keys configured
    // try {
    //   return FirebaseFunctionsGenerateProvider();
    // } catch (e) {
    //   // Fall through to direct API if Functions fail
    // }
    
    // Priority 2: Use direct API if keys provided (development/testing)
    if (Env.replicateToken.isNotEmpty) {
      final svc = ReplicateService(apiToken: Env.replicateToken);
      return _GenerateAdapter(svc);
    }
    
    // Priority 3: Fallback to fake provider (for UI testing)
    return FakeGenerateProvider();
  }

  static ILocalStore localStore() {
    try {
      return SharedPrefsStore();
    } catch (_) {
      return FakeLocalStore();
    }
  }
}

// Registry class for easy access to services
class Registry {
  static IAnalysisRepository _analysis = BackendRegistry.analysisRepository();
  static IStorageRepository _storage = BackendRegistry.storageRepository();
  static IVisionProvider _vision = BackendRegistry.visionProvider();
  static IGenerateProvider _replicate = BackendRegistry.generateProvider();

  static IAnalysisRepository get analysis => _analysis;
  static IStorageRepository get storage => _storage;
  static IVisionProvider get vision => _vision;
  static IGenerateProvider get replicate => _replicate;

  static void configure({
    IAnalysisRepository? analysis,
    IStorageRepository? storage,
    IVisionProvider? vision,
    IGenerateProvider? replicate,
  }) {
    if (analysis != null) _analysis = analysis;
    if (storage != null) _storage = storage;
    if (vision != null) _vision = vision;
    if (replicate != null) _replicate = replicate;
  }

  static void reset() {
    _analysis = BackendRegistry.analysisRepository();
    _storage = BackendRegistry.storageRepository();
    _vision = BackendRegistry.visionProvider();
    _replicate = BackendRegistry.generateProvider();
  }
}

class _VisionAdapter implements IVisionProvider {
  _VisionAdapter(this._svc);
  final VisionService _svc;
  @override
  Future<VisionAnalysis> analyzeImageBytes(Uint8List bytes) =>
      _svc.analyzeImageBytes(bytes);
  @override
  Future<VisionAnalysis> analyzeImageUrl(String imageUrl) =>
      _svc.analyzeImageUrl(imageUrl);
}

class _GenerateAdapter implements IGenerateProvider {
  _GenerateAdapter(this._svc);
  final ReplicateService _svc;
  @override
  Future<String> generateOrganizedImage({required String imageUrl}) =>
      _svc.generateOrganizedImage(imageUrl: imageUrl);
}
