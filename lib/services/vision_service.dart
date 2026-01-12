import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/vision_models.dart';
import 'vision_error_handler.dart';

class VisionService {
  VisionService({
    required this.apiKey,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    RetryConfig? retryConfig,
  }) : _client = client ?? http.Client(),
       _retryConfig = retryConfig ?? RetryConfig.visionAnalysis;

  final String apiKey;
  final http.Client _client;
  final Duration timeout;
  final RetryConfig _retryConfig;

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
    
    // Parse response and handle errors
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    
    // Check for errors in response
    if (decoded.containsKey('error')) {
      final error = VisionErrorHandler.parseErrorResponse(response);
      if (error != null) {
        throw error;
      }
    }
    
    final responses = decoded['responses'] as List<dynamic>? ?? const [];
    if (responses.isEmpty) {
      return const VisionAnalysis(objects: [], labels: []);
    }

    final Map<String, dynamic> primary =
        responses.first as Map<String, dynamic>;
    
    // Check for errors in individual response
    if (primary.containsKey('error')) {
      final errorData = primary['error'] as Map<String, dynamic>;
      throw VisionApiError(
        statusCode: response.statusCode,
        message: errorData['message'] as String? ?? 'Vision API error',
        errorCode: errorData['code']?.toString(),
        isRetryable: false, // Individual response errors are usually not retryable
        isRateLimit: false,
      );
    }
    
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
    VisionApiError? lastError;
    
    for (int attempt = 1; attempt <= _retryConfig.maxAttempts; attempt++) {
      try {
        final response = await _client
            .post(
              uri,
              headers: const {
                'Content-Type': 'application/json; charset=utf-8'
              },
              body: jsonEncode(body),
            )
            .timeout(_retryConfig.timeout);

        // Success
        if (response.statusCode == 200) {
          return response;
        }

        // Parse error response
        final error = VisionErrorHandler.parseErrorResponse(response);
        if (error == null) {
          throw Exception(
              _formatError('Vision API', response.statusCode, response.body));
        }

        lastError = error;

        // Check if we should retry
        final shouldRetry = _shouldRetry(error, attempt);
        if (!shouldRetry) {
          throw error;
        }

        // Calculate delay before retry
        Duration delay;
        if (error.isRateLimit) {
          // Use Retry-After header if available, otherwise use exponential backoff
          delay = VisionErrorHandler.extractRetryAfter(response) ??
              VisionErrorHandler.calculateBackoffDelay(
                attempt,
                baseDelay: _retryConfig.baseDelay,
                maxDelaySeconds: _retryConfig.maxDelay.inSeconds.toDouble(),
              );
        } else {
          // Use exponential backoff for other retryable errors
          delay = VisionErrorHandler.calculateBackoffDelay(
            attempt,
            baseDelay: _retryConfig.baseDelay,
            maxDelaySeconds: _retryConfig.maxDelay.inSeconds.toDouble(),
          );
        }

        // Wait before retrying (except on last attempt)
        if (attempt < _retryConfig.maxAttempts) {
          await Future<void>.delayed(delay);
        }
      } on TimeoutException catch (e) {
        lastError = VisionApiError(
          statusCode: 408,
          message: 'Request timeout: ${e.toString()}',
          isRetryable: _retryConfig.retryOnTimeout && attempt < _retryConfig.maxAttempts,
          isRateLimit: false,
        );

        if (!lastError.isRetryable) {
          throw lastError;
        }

        // Wait before retrying
        if (attempt < _retryConfig.maxAttempts) {
          final delay = VisionErrorHandler.calculateBackoffDelay(
            attempt,
            baseDelay: _retryConfig.baseDelay,
            maxDelaySeconds: _retryConfig.maxDelay.inSeconds.toDouble(),
          );
          await Future<void>.delayed(delay);
        }
      } on VisionApiError catch (e) {
        lastError = e;
        if (!e.isRetryable || attempt >= _retryConfig.maxAttempts) {
          rethrow;
        }
        // Wait before retrying
        final delay = VisionErrorHandler.calculateBackoffDelay(
          attempt,
          baseDelay: _retryConfig.baseDelay,
          maxDelaySeconds: _retryConfig.maxDelay.inSeconds.toDouble(),
        );
        await Future<void>.delayed(delay);
      } catch (e) {
        // Non-retryable error or network error
        if (e is VisionApiError) {
        rethrow;
        }
        throw Exception('Vision API request failed: $e');
      }
    }

    // All retries exhausted
    throw lastError ?? 
        Exception('Vision API request failed after ${_retryConfig.maxAttempts} attempts');
  }

  /// Determines if we should retry based on error and attempt number
  bool _shouldRetry(VisionApiError error, int attempt) {
    if (attempt >= _retryConfig.maxAttempts) {
      return false;
    }

    if (!error.isRetryable) {
      return false;
    }

    if (error.isRateLimit && !_retryConfig.retryOnRateLimit) {
      return false;
    }

    if (error.statusCode >= 500 && !_retryConfig.retryOnServerError) {
      return false;
    }

    return true;
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

  /// Gets user-friendly error message for the last error
  String? getLastErrorMessage(VisionApiError? error) {
    if (error == null) return null;
    return VisionErrorHandler.getUserFriendlyMessage(error);
  }
}
