import 'dart:async';
import '../../models/vision_models.dart';
import '../interfaces/analysis_repository.dart';

class FakeAnalysisRepository implements IAnalysisRepository {
  final Map<String, List<StoredAnalysis>> _userData = {};

  @override
  Future<void> saveAnalysis({required String uid, required String imageUrl, required VisionAnalysis analysis}) async {
    final list = _userData.putIfAbsent(uid, () => <StoredAnalysis>[]);
    final now = DateTime.now();
    list.insert(
      0,
      StoredAnalysis(
        id: 'fake_${now.millisecondsSinceEpoch}',
        imageUrl: imageUrl,
        title: analysis.labels.isEmpty ? 'Scan' : analysis.labels.take(2).join(' '),
        clutterScore: (analysis.objects.length.clamp(0, 50) / 5).toDouble().clamp(1.0, 10.0),
        primaryCategory: analysis.labels.isNotEmpty ? analysis.labels.first.toLowerCase() : 'general',
        categories: analysis.labels.take(5).map((e) => e.toLowerCase()).toList(),
        labels: analysis.labels,
        createdAt: now,
      ),
    );
  }

  @override
  Stream<List<StoredAnalysis>> watchUserAnalyses(String uid, {int limit = 20}) {
    // Emit current and then periodic updates when changes occur
    final controller = StreamController<List<StoredAnalysis>>.broadcast();
    void emit() => controller.add(List<StoredAnalysis>.from(_userData[uid] ?? const []));
    emit();
    // In a real fake we'd notify on save; simplistic here
    return controller.stream;
  }

  @override
  Future<void> create({required String uid, required String title, required String imageUrl, required String organizedImageUrl, required VisionAnalysis analysis}) async {
    final list = _userData.putIfAbsent(uid, () => <StoredAnalysis>[]);
    final now = DateTime.now();
    list.insert(
      0,
      StoredAnalysis(
        id: 'fake_${now.millisecondsSinceEpoch}',
        imageUrl: imageUrl,
        title: title,
        clutterScore: (analysis.objects.length.clamp(0, 50) / 5).toDouble().clamp(1.0, 10.0),
        primaryCategory: analysis.labels.isNotEmpty ? analysis.labels.first.toLowerCase() : 'general',
        categories: analysis.labels.take(5).map((e) => e.toLowerCase()).toList(),
        labels: analysis.labels,
        createdAt: now,
      ),
    );
  }
}


