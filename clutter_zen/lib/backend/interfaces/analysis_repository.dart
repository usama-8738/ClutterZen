import '../../models/vision_models.dart';

abstract class IAnalysisRepository {
  Future<void> saveAnalysis({required String uid, required String imageUrl, required VisionAnalysis analysis});
  Stream<List<StoredAnalysis>> watchUserAnalyses(String uid, {int limit});
}

class StoredAnalysis {
  final String id;
  final String imageUrl;
  final String title;
  final double clutterScore;
  final String primaryCategory;
  final List<String> categories;
  final List<String> labels;
  final DateTime createdAt;

  const StoredAnalysis({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.clutterScore,
    required this.primaryCategory,
    required this.categories,
    required this.labels,
    required this.createdAt,
  });
}


