import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/vision_models.dart';

class VisionService {
  VisionService({required this.apiKey});

  final String apiKey;

  Future<VisionAnalysis> analyzeImageUrl(String imageUrl) async {
    final uri = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    final body = {
      'requests': [
        {
          'image': {
            'source': {'imageUri': imageUrl}
          },
          'features': [
            {'type': 'OBJECT_LOCALIZATION', 'maxResults': 50},
            {'type': 'LABEL_DETECTION', 'maxResults': 20},
          ]
        }
      ]
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Vision API error: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final resp0 = (data['responses'] as List).isNotEmpty ? (data['responses'] as List).first : null;
    if (resp0 == null) {
      return const VisionAnalysis(objects: [], labels: []);
    }

    final List<dynamic> objectsRaw = resp0['localizedObjectAnnotations'] as List<dynamic>? ?? const [];
    final List<dynamic> labelsRaw = resp0['labelAnnotations'] as List<dynamic>? ?? const [];

    final objects = objectsRaw.map((o) {
      final name = (o['name'] ?? 'object').toString();
      final score = ((o['score'] ?? 0.0) as num).toDouble();
      final vertices = (o['boundingPoly']?['normalizedVertices'] as List<dynamic>? ?? const []);
      return DetectedObject(
        name: name,
        confidence: score,
        box: BoundingBoxNormalized.fromVertices(vertices),
      );
    }).toList();

    final labels = labelsRaw.map((l) => (l['description'] ?? '').toString()).where((s) => s.isNotEmpty).toList();

    return VisionAnalysis(objects: objects, labels: labels);
  }

  Future<VisionAnalysis> analyzeImageBytes(Uint8List bytes) async {
    final uri = Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$apiKey');

    final body = {
      'requests': [
        {
          'image': {'content': base64Encode(bytes)},
          'features': [
            {'type': 'OBJECT_LOCALIZATION', 'maxResults': 50},
            {'type': 'LABEL_DETECTION', 'maxResults': 20},
          ]
        }
      ]
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Vision API error: ${response.statusCode}');
    }

    final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
    final resp0 = (data['responses'] as List).isNotEmpty ? (data['responses'] as List).first : null;
    if (resp0 == null) {
      return const VisionAnalysis(objects: [], labels: []);
    }

    final List<dynamic> objectsRaw = resp0['localizedObjectAnnotations'] as List<dynamic>? ?? const [];
    final List<dynamic> labelsRaw = resp0['labelAnnotations'] as List<dynamic>? ?? const [];

    final objects = objectsRaw.map((o) {
      final name = (o['name'] ?? 'object').toString();
      final score = ((o['score'] ?? 0.0) as num).toDouble();
      final vertices = (o['boundingPoly']?['normalizedVertices'] as List<dynamic>? ?? const []);
      return DetectedObject(
        name: name,
        confidence: score,
        box: BoundingBoxNormalized.fromVertices(vertices),
      );
    }).toList();

    final labels = labelsRaw.map((l) => (l['description'] ?? '').toString()).where((s) => s.isNotEmpty).toList();

    return VisionAnalysis(objects: objects, labels: labels);
  }
}


