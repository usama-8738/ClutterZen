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
import 'interfaces/local_store.dart';
import 'local/shared_prefs_store.dart';
import 'dart:typed_data';
import 'interfaces/gemini_provider.dart';
import '../services/gemini_service.dart';
import '../models/gemini_models.dart';

class BackendRegistry {
  BackendRegistry._();

  static IAnalysisRepository analysisRepository() {
    return FirebaseAnalysisRepository(AppFirebase.firestore);
  }

  static IStorageRepository storageRepository() {
    return FirebaseStorageRepository(FirebaseStorage.instance);
  }

  static IVisionProvider visionProvider() {
    if (Env.visionApiKey.isEmpty) {
      throw StateError(
          'VISION_API_KEY is not configured. Add it to your .env file.');
    }
    final svc = VisionService(apiKey: Env.visionApiKey);
    return _VisionAdapter(svc);
  }

  static IGenerateProvider generateProvider() {
    if (Env.replicateToken.isEmpty) {
      throw StateError(
          'REPLICATE_API_TOKEN is not configured. Add it to your .env file.');
    }
    final svc = ReplicateService(apiToken: Env.replicateToken);
    return _GenerateAdapter(svc);
  }

  static ILocalStore localStore() {
    return SharedPrefsStore();
  }

  static IGeminiProvider geminiProvider() {
    if (Env.geminiApiKey.isEmpty) {
      throw StateError(
          'GEMINI_API_KEY is not configured. Add it to your .env file.');
    }
    final svc = GeminiService(apiKey: Env.geminiApiKey);
    return _GeminiAdapter(svc);
  }
}

// Registry class for easy access to services
class Registry {
  static IAnalysisRepository? _analysis;
  static IStorageRepository? _storage;
  static IVisionProvider? _vision;
  static IGenerateProvider? _replicate;
  static IGeminiProvider? _gemini;

  static IAnalysisRepository get analysis =>
      _analysis ??= BackendRegistry.analysisRepository();
  static IStorageRepository get storage =>
      _storage ??= BackendRegistry.storageRepository();
  static IVisionProvider get vision =>
      _vision ??= BackendRegistry.visionProvider();
  static IGenerateProvider get replicate =>
      _replicate ??= BackendRegistry.generateProvider();
  static IGeminiProvider get gemini =>
      _gemini ??= BackendRegistry.geminiProvider();

  static void configure({
    IAnalysisRepository? analysis,
    IStorageRepository? storage,
    IVisionProvider? vision,
    IGenerateProvider? replicate,
    IGeminiProvider? gemini,
  }) {
    if (analysis != null) _analysis = analysis;
    if (storage != null) _storage = storage;
    if (vision != null) _vision = vision;
    if (replicate != null) _replicate = replicate;
    if (gemini != null) _gemini = gemini;
  }

  static void reset() {
    _analysis = null;
    _storage = null;
    _vision = null;
    _replicate = null;
    _gemini = null;
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
      _svc.generateOrganizedImage(
        imageUrl: imageUrl,
        fallbackToOriginal: true,
      );
}

class _GeminiAdapter implements IGeminiProvider {
  _GeminiAdapter(this._svc);
  final GeminiService _svc;
  @override
  Future<GeminiRecommendation> getRecommendations({
    String? spaceDescription,
    required List<String> detectedObjects,
    Uint8List? imageBytes,
    double? clutterScore,
  }) =>
      _svc.getRecommendations(
        spaceDescription: spaceDescription,
        detectedObjects: detectedObjects,
        imageBytes: imageBytes,
        clutterScore: clutterScore,
      );
}
