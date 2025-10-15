import 'dart:typed_data';
import '../../models/vision_models.dart';
import '../interfaces/vision_provider.dart';

class FakeVisionProvider implements IVisionProvider {
  @override
  Future<VisionAnalysis> analyzeImageBytes(Uint8List bytes) async {
    return const VisionAnalysis(objects: [], labels: ['room', 'objects']);
  }

  @override
  Future<VisionAnalysis> analyzeImageUrl(String imageUrl) async {
    return const VisionAnalysis(objects: [], labels: ['room', 'objects']);
  }
}


