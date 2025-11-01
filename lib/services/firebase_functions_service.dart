import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/vision_models.dart';
import '../app_firebase.dart';

/// Service to call Firebase Cloud Functions for secure API proxy
/// This keeps API keys on the server side
/// 
/// Note: Requires Firebase Functions to be deployed and API keys configured
/// via: firebase functions:config:set vision.key="YOUR_KEY" replicate.token="YOUR_TOKEN"
class FirebaseFunctionsService {
  FirebaseFunctionsService({
    http.Client? client,
    String? functionsUrl,
  })  : _client = client ?? http.Client(),
        _functionsUrl = functionsUrl;

  final http.Client _client;
  final String? _functionsUrl;

  /// Get the Firebase Functions URL
  /// Falls back to default if not provided
  String get _baseUrl {
    if (_functionsUrl != null) return _functionsUrl!;
    // Default Firebase Functions URL pattern
    // This should match your deployed function URL
    return 'https://us-central1-clutterzen-test.cloudfunctions.net/api';
  }

  /// Get ID token for authenticated requests
  Future<String?> _getIdToken() async {
    try {
      final user = AppFirebase.auth.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (e) {
      return null;
    }
  }

  /// Call Vision API via Firebase Cloud Function
  Future<VisionAnalysis> analyzeImageViaFunction({
    String? imageUrl,
    Uint8List? imageBytes,
  }) async {
    if (imageUrl == null && imageBytes == null) {
      throw ArgumentError('Either imageUrl or imageBytes must be provided');
    }

    try {
      final idToken = await _getIdToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }

      final body = <String, dynamic>{};
      if (imageUrl != null) {
        body['imageUrl'] = imageUrl;
      } else if (imageBytes != null) {
        body['imageBase64'] = base64Encode(imageBytes);
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/vision/analyze'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Vision API failed: ${response.statusCode} ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final responses = data['responses'] as List<dynamic>? ?? const [];

      if (responses.isEmpty) {
        return const VisionAnalysis(objects: [], labels: []);
      }

      final primary = responses.first as Map<String, dynamic>;
      final objectsRaw =
          primary['localizedObjectAnnotations'] as List<dynamic>? ?? const [];
      final labelsRaw =
          primary['labelAnnotations'] as List<dynamic>? ?? const [];

      final objects = objectsRaw.map((raw) {
        final data = raw as Map<String, dynamic>;
        final vertices = data['boundingPoly']?['normalizedVertices'] as List<dynamic>? ?? const [];
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
    } catch (e) {
      throw Exception('Vision analysis via Firebase Function failed: $e');
    }
  }

  /// Call Replicate API via Firebase Cloud Function
  Future<String> generateOrganizedImageViaFunction({
    required String imageUrl,
  }) async {
    try {
      final idToken = await _getIdToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (idToken != null) {
        headers['Authorization'] = 'Bearer $idToken';
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/replicate/generate'),
        headers: headers,
        body: jsonEncode({'imageUrl': imageUrl}),
      ).timeout(const Duration(seconds: 120)); // Longer timeout for generation

      if (response.statusCode != 200) {
        throw Exception('Replicate API failed: ${response.statusCode} ${response.body}');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as Map<String, dynamic>;
      final outputUrl = data['outputUrl'] as String;

      if (outputUrl.isEmpty) {
        throw Exception('Replicate returned empty output URL');
      }

      return outputUrl;
    } catch (e) {
      throw Exception('Replicate generation via Firebase Function failed: $e');
    }
  }
}

