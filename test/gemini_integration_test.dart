import 'dart:io';
import 'package:clutterzen/backend/registry.dart';
import 'package:clutterzen/env.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    // Attempt to load .env; fallback to manual load if standard fails in test environment
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      final file = File('.env');
      if (file.existsSync()) {
        dotenv.testLoad(fileInput: file.readAsStringSync());
      }
    }
  });

  test('Gemini Service Integration Test', () async {
    if (Env.geminiApiKey.isEmpty ||
        Env.geminiApiKey == 'your_gemini_api_key_here') {
      fail('Gemini API Key is missing or still a placeholder in .env');
    }

    debugPrint(
        'Testing Gemini with key: ${Env.geminiApiKey.substring(0, 5)}...');

    try {
      final recommendation = await Registry.gemini.getRecommendations(
        detectedObjects: ['messy desk', 'laptop', 'stray papers', 'coffee mug'],
        spaceDescription: 'A cluttered home office desk',
      );

      debugPrint('Summary: ${recommendation.summary}');
      debugPrint('Services: ${recommendation.services.length}');
      debugPrint('Products: ${recommendation.products.length}');
      debugPrint('DIY Steps: ${recommendation.diyPlan.length}');

      expect(recommendation.summary, isNotNull);
      expect(recommendation.summary!.isNotEmpty, true);
      expect(recommendation.diyPlan.isNotEmpty, true);

      debugPrint('✅ Gemini Integration Test Passed!');
    } catch (e) {
      fail('Gemini API call failed: $e');
    }
  });
}
