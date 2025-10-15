import '../../models/vision_models.dart';
import 'dart:typed_data';

abstract class IVisionProvider {
  Future<VisionAnalysis> analyzeImageUrl(String imageUrl);
  Future<VisionAnalysis> analyzeImageBytes(Uint8List bytes);
}


