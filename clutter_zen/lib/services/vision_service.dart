import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/vision_models.dart';

class VisionService {
  VisionService({
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
    this.maxRetries = 2,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;
  final Duration timeout;
  final int maxRetries;

  static const List<Map<String, Object>> _features = [
    {'type': 'OBJECT_LOCALIZATION', 'maxResults': 50},
    {'type': 'LABEL_DETECTION', 'maxResults': 20},
  ];

  Future<VisionAnalysis> analyzeImageUrl(String imageUrl) {
    return _analyze({
      'source': {'imageUri': imageUrl}
    });
  }

  Future<VisionAnalysis> analyzeImageBytes(Uint8List bytes) {
    return _analyze({'content': base64Encode(bytes)});
  }

  Future<VisionAnalysis> _analyze(Map<String, Object> imagePayload) async {
    final uri = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$apiKey');
    final body = {
      'requests': [
        {
          'image': imagePayload,
          'features': _features,
        }
      ],
    };

    final response = await _postJsonWithRetry(uri, body);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final responses = decoded['responses'] as List<dynamic>? ?? const [];
    if (responses.isEmpty) {
      return const VisionAnalysis(objects: [], labels: []);
    }

    final Map<String, dynamic> primary =
        responses.first as Map<String, dynamic>;
    final objectsRaw =
        primary['localizedObjectAnnotations'] as List<dynamic>? ?? const [];
    final labelsRaw = primary['labelAnnotations'] as List<dynamic>? ?? const [];

    final objects = objectsRaw.map((raw) {
      final data = raw as Map<String, dynamic>;
      final vertices =
          data['boundingPoly']?['normalizedVertices'] as List<dynamic>? ??
              const [];
      return DetectedObject(
        name: (data['name'] ?? 'object').toString(),
        confidence: ((data['score'] ?? 0.0) as num).toDouble(),
        box: BoundingBoxNormalized.fromVertices(vertices),
      );
    }).toList();

    final labels = labelsRaw
        .map((entry) =>
            (entry as Map<String, dynamic>)['description']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    return VisionAnalysis(objects: objects, labels: labels);
  }

  Future<http.Response> _postJsonWithRetry(
      Uri uri, Map<String, Object?> body) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body),
            )
            .timeout(timeout);

        if (response.statusCode == 200) {
          return response;
        }

        if (response.statusCode >= 500 && attempt <= maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }

        throw Exception(
            _formatError('Vision API', response.statusCode, response.body));
      } on TimeoutException {
        if (attempt <= maxRetries) {
          await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
          continue;
        }
        rethrow;
      }
    }
  }

  String _formatError(String service, int status, String body) {
    final msg = switch (status) {
      400 => 'Bad request',
      401 => 'Unauthorized',
      403 => 'Forbidden',
      404 => 'Not found',
      429 => 'Rate limited',
      _ when status >= 500 => 'Server error',
      _ => 'HTTP $status',
    };
    final preview = body.length > 180 ? '${body.substring(0, 180)}...' : body;
    return '$service error ($msg): $preview';
  }
}
