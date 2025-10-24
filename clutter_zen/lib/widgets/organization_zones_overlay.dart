import 'package:flutter/material.dart';

import '../../../models/vision_models.dart';

class OrganizationZonesOverlay extends StatelessWidget {
  const OrganizationZonesOverlay({
    super.key,
    required this.analysis,
    required this.child,
  });

  final VisionAnalysis analysis;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Note: This is a simplified placeholder for the zone generation logic.
    // In a real app, this would use the more complex logic from the documentation.
    final zones = _generateSimpleZones(analysis.objects);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            child,
            ...zones.map((zone) {
              return Positioned(
                left: zone.box.left * constraints.maxWidth,
                top: zone.box.top * constraints.maxHeight,
                width: zone.box.width * constraints.maxWidth,
                height: zone.box.height * constraints.maxHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: zone.color,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      zone.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.black45,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  List<_Zone> _generateSimpleZones(List<DetectedObject> objects) {
    if (objects.isEmpty) return [];

    // This is a placeholder. A real implementation would use the templates
    // and space-type analysis from the documentation.
    return [
      _Zone(
        name: 'Primary Zone',
        box: const BoundingBoxNormalized(
            left: 0.1, top: 0.1, width: 0.4, height: 0.8),
        color: Colors.blue.withAlpha(102),
      ),
      _Zone(
        name: 'Secondary Zone',
        box: const BoundingBoxNormalized(
            left: 0.6, top: 0.2, width: 0.3, height: 0.6),
        color: Colors.green.withAlpha(102),
      ),
    ];
  }
}

class _Zone {
  const _Zone({required this.name, required this.box, required this.color});
  final String name;
  final BoundingBoxNormalized box;
  final Color color;
}
