import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ReplicateService {
  ReplicateService(
      {required this.apiToken,
      http.Client? client,
      this.timeout = const Duration(seconds: 20),
      this.maxPollSeconds = 60})
      : _client = client ?? http.Client();

  final String apiToken;
  final http.Client _client;
  final Duration timeout;
  final int maxPollSeconds;

  // Returns generated image URL
  Future<String> generateOrganizedImage({required String imageUrl}) async {
    final start = await _client.post(
      Uri.parse('https://api.replicate.com/v1/predictions'),
      headers: {
        'Authorization': 'Token $apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        // SDXL image-to-image refiner version
        'version':
            '39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
        'input': {
          'image': imageUrl,
          'prompt':
              'same space perfectly organized and tidy, clean surfaces, everything stored, high quality, photorealistic',
          'prompt_strength': 0.7,
          'num_inference_steps': 28,
        }
      }),
    );
    if (start.statusCode != 201) {
      throw Exception(
          'Replicate start failed: ${start.statusCode} ${start.body}');
    }
    final startJson = jsonDecode(start.body) as Map<String, dynamic>;
    final String id = (startJson['id'] as String);
    // poll
    for (int i = 0; i < maxPollSeconds; i++) {
      await Future.delayed(const Duration(seconds: 1));
      final res = await _client.get(
        Uri.parse('https://api.replicate.com/v1/predictions/$id'),
        headers: {'Authorization': 'Token $apiToken'},
      ).timeout(timeout);
      if (res.statusCode != 200) continue;
      final js = jsonDecode(res.body) as Map<String, dynamic>;
      final status = js['status'] as String?;
      if (status == 'succeeded') {
        final out = js['output'];
        if (out is List && out.isNotEmpty) {
          return out.first.toString();
        } else if (out is String) {
          return out;
        }
        throw Exception('Replicate returned no output');
      }
      if (status == 'failed' || status == 'canceled') {
        throw Exception('Replicate failed: ${js['error']}');
      }
    }
    throw Exception('Replicate timed out');
  }
}
