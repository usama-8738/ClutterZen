class BoundingBoxNormalized {
  final double left;
  final double top;
  final double width;
  final double height;

  const BoundingBoxNormalized({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  factory BoundingBoxNormalized.fromVertices(List<dynamic> vertices) {
    if (vertices.isEmpty) {
      return const BoundingBoxNormalized(left: 0, top: 0, width: 0, height: 0);
    }

    double minX = 1.0, minY = 1.0, maxX = 0.0, maxY = 0.0;
    for (final v in vertices) {
      final double x = (v['x'] ?? 0.0).toDouble();
      final double y = (v['y'] ?? 0.0).toDouble();
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    return BoundingBoxNormalized(
      left: minX,
      top: minY,
      width: (maxX - minX).clamp(0.0, 1.0),
      height: (maxY - minY).clamp(0.0, 1.0),
    );
    }
}

class DetectedObject {
  final String name;
  final double confidence;
  final BoundingBoxNormalized box;

  const DetectedObject({
    required this.name,
    required this.confidence,
    required this.box,
  });
}

class VisionAnalysis {
  final List<DetectedObject> objects;
  final List<String> labels;

  const VisionAnalysis({
    required this.objects,
    required this.labels,
  });
}


