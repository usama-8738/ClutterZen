import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/gemini_models.dart';

/// Service for interacting with Google Gemini AI API.
/// Provides smart recommendations based on detected objects and space analysis.
class GeminiService {
  GeminiService({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;
  // Prioritized list of models to try
  static const List<String> _modelHierarchy = [
    'gemini-3-pro-preview', // Primary: Latest Pro (High Intelligence)
    'gemini-3-flash-preview', // Fallback 1: Latest Flash (Speed/Efficiency)
    'gemini-flash-lite-latest', // Fallback 2: Flash Lite (Low latency/Cost effective)
  ];

  /// Analyzes detected objects and returns recommendations.
  Future<GeminiRecommendation> getRecommendations({
    String? spaceDescription,
    required List<String> detectedObjects,
    Uint8List? imageBytes,
  }) async {
    if (detectedObjects.isEmpty && spaceDescription == null) {
      return GeminiRecommendation.empty();
    }

    final prompt = _buildPrompt(
      spaceDescription: spaceDescription,
      detectedObjects: detectedObjects,
    );

    for (final modelName in _modelHierarchy) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.7,
            maxOutputTokens: 2048,
            responseMimeType: 'application/json',
          ),
        );

        final content = <Content>[];
        if (imageBytes != null) {
          content.add(Content.multi([
            DataPart('image/jpeg', imageBytes),
            TextPart(prompt),
          ]));
        } else {
          content.add(Content.text(prompt));
        }

        // Try to generate content with the current model
        final response = await model.generateContent(content);
        final text = response.text;

        if (text != null && text.isNotEmpty) {
          // If successful, parse and return immediately
          return _parseResponse(text);
        }
      } catch (e) {
        // Log the failure for this specific model but continue to the next one
        // In a real app, you might send this to Crashlytics
        continue;
      }
    }

    // If all models fail, return empty fallback
    return GeminiRecommendation(
      services: [],
      products: [],
      diyPlan: [],
      summary: 'Unable to generate recommendations from any AI model.',
    );
  }

  String _buildPrompt({
    String? spaceDescription,
    required List<String> detectedObjects,
  }) {
    final objectsList = detectedObjects.join(', ');

    return '''
You are a professional home organization expert. Analyze the following information and provide personalized recommendations.

${spaceDescription != null ? 'Space Description: $spaceDescription' : ''}
Detected Objects: $objectsList

Provide recommendations in the following JSON format:
{
  "summary": "Brief analysis of the space (2-3 sentences)",
  "services": [
    {
      "name": "Service name",
      "description": "What this service does",
      "category": "Category (e.g., Cleaning, Organization, Decluttering)",
      "estimatedCost": 100
    }
  ],
  "products": [
    {
      "name": "Product name",
      "description": "How this product helps",
      "category": "Category (e.g., Storage, Labels, Containers)",
      "price": 25
    }
  ],
  "diyPlan": [
    {
      "stepNumber": 1,
      "title": "Step title",
      "description": "Detailed instructions",
      "tips": ["Helpful tip 1", "Helpful tip 2"]
    }
  ]
}

Guidelines:
- Suggest 2-4 relevant services based on the detected clutter
- Recommend 3-6 products that would help organize the space
- Create a 4-6 step DIY plan for self-organization
- Be specific and actionable
- Consider the types of objects detected when making recommendations
''';
  }

  GeminiRecommendation _parseResponse(String text) {
    try {
      // Clean up potential markdown code blocks
      var cleanText = text.trim();
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      }
      if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      cleanText = cleanText.trim();

      final json = jsonDecode(cleanText) as Map<String, dynamic>;

      final services = (json['services'] as List<dynamic>?)
              ?.map((s) =>
                  ServiceRecommendation.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [];

      final products = (json['products'] as List<dynamic>?)
              ?.map((p) =>
                  ProductRecommendation.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [];

      final diyPlan = (json['diyPlan'] as List<dynamic>?)
              ?.map((d) => DiyStep.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [];

      return GeminiRecommendation(
        services: services,
        products: products,
        diyPlan: diyPlan,
        summary: json['summary'] as String?,
      );
    } catch (e) {
      // Return empty on parse failure
      return GeminiRecommendation(
        services: [],
        products: [],
        diyPlan: [],
        summary: 'Unable to parse recommendations.',
      );
    }
  }
}
