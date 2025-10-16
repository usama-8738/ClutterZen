import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/vision_models.dart';

class VisionService {
  VisionService({required this.apiKey, http.Client? client, this.timeout = const Duration(seconds: 20), this.maxRetries = 2})
      : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final Duration timeout;
  final int maxRetries;

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

    final response = await _postJsonWithRetry(uri, body);

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

    final response = await _postJsonWithRetry(uri, body);

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

  Future<http.Response> _postJsonWithRetry(Uri uri, Map<String, dynamic> body) async {
    int attempt = 0;
    late http.Response res;
    while (true) {
      attempt++;
      try {
        res = await _client
            .post(
              uri,
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              body: jsonEncode(body),
            )
            .timeout(timeout);
        if (res.statusCode == 200) return res;
        // Retry on transient server/network errors
        if (res.statusCode >= 500 && attempt <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        throw Exception(_formatError('Vision API', res.statusCode, res.body));
      } on TimeoutException {
        if (attempt <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        rethrow;
      }
    }
  }

  String _formatError(String service, int status, String body) {
    String msg;
    if (status == 400) msg = 'Bad request';
    else if (status == 401) msg = 'Unauthorized';
    else if (status == 403) msg = 'Forbidden';
    else if (status == 404) msg = 'Not found';
    else if (status == 429) msg = 'Rate limited';
    else if (status >= 500) msg = 'Server error';
    else msg = 'HTTP $status';
    // Truncate body for safety
    final preview = body.length > 180 ? body.substring(0, 180) + '…' : body;
    return '$service error ($msg): $preview';
  }
}


