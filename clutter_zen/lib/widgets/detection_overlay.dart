import 'package:flutter/material.dart';

import '../models/vision_models.dart';

class DetectionOverlay extends StatelessWidget {
  const DetectionOverlay({
    super.key,
    this.image,
    this.imageUrl,
    required this.objects,
  }) : assert(image != null || imageUrl != null, 'Provide either image or imageUrl');

  final ImageProvider? image;
  final String? imageUrl;
  final List<DetectedObject> objects;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image(
            image: image ?? NetworkImage(imageUrl!),
            fit: BoxFit.contain,
          ),
        ),
        ...objects.map((obj) {
          return Positioned(
            left: obj.box.left * MediaQuery.of(context).size.width,
            top: obj.box.top * MediaQuery.of(context).size.width * 0.75,
            width: obj.box.width * MediaQuery.of(context).size.width,
            height: obj.box.height * MediaQuery.of(context).size.width * 0.75,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 2),
                color: Colors.blueAccent.withValues(alpha: 0.12),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${obj.name} ${(obj.confidence * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}


