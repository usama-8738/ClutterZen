import 'dart:convert';
import 'package:http/http.dart' as http;

/// Error handling for Replicate API
class ReplicateErrorHandler {
  /// Determines if an error is retryable
  static bool isRetryableError(int statusCode, {String? status}) {
    // Retryable errors
    if (statusCode == 429) return true; // Rate limit
    if (statusCode >= 500 && statusCode < 600) return true; // Server errors
    if (statusCode == 408) return true; // Request timeout
    if (statusCode == 503) return true; // Service unavailable
    
    // Replicate-specific status checks
    if (status != null) {
      final lowerStatus = status.toLowerCase();
      if (lowerStatus == 'starting' || 
          lowerStatus == 'processing' ||
          lowerStatus == 'queued') {
        return true; // Still processing, can retry
      }
    }
    
    return false;
  }

  /// Parses Replicate API error response
  static ReplicateApiError? parseErrorResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>?;
      if (body == null) return null;

      final detail = body['detail'] as String?;
      final error = body['error'] as String?;
      final message = detail ?? error ?? 'Unknown error';

      return ReplicateApiError(
        statusCode: response.statusCode,
        message: message,
        isRetryable: isRetryableError(response.statusCode),
      );
    } catch (e) {
      return ReplicateApiError(
        statusCode: response.statusCode,
        message: response.body.isNotEmpty 
            ? response.body.substring(0, response.body.length.clamp(0, 200))
            : 'Unknown error',
        isRetryable: isRetryableError(response.statusCode),
      );
    }
  }

  /// Gets user-friendly error message
  static String getUserFriendlyMessage(ReplicateApiError error) {
    switch (error.statusCode) {
      case 400:
        return 'Invalid image. Please try a different photo.';
      case 401:
        return 'Authentication failed. Please check your API key.';
      case 403:
        return 'Access denied. Please check your permissions.';
      case 404:
        return 'Prediction not found. Please try again.';
      case 408:
        return 'Request timed out. The image generation is taking longer than expected.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Service temporarily unavailable. Please try again in a moment.';
      default:
        if (error.message.contains('timeout') || error.message.contains('Timeout')) {
          return 'Generation timed out. Please try again with a smaller image.';
        }
        if (error.message.contains('quota') || error.message.contains('rate')) {
          return 'API quota exceeded. Please try again later.';
        }
        return error.message.isNotEmpty 
            ? error.message 
            : 'Image generation failed. Please try again.';
    }
  }
}

/// Represents a Replicate API error
class ReplicateApiError implements Exception {
  final int statusCode;
  final String message;
  final bool isRetryable;

  ReplicateApiError({
    required this.statusCode,
    required this.message,
    required this.isRetryable,
  });

  @override
  String toString() {
    return 'ReplicateApiError($statusCode): $message';
  }
}

/// Replicate prediction status
enum ReplicateStatus {
  starting,
  processing,
  succeeded,
  failed,
  canceled,
  queued,
  unknown,
}

/// Replicate generation progress information
class ReplicateProgress {
  final ReplicateStatus status;
  final double? progress; // 0.0 to 1.0, null if unknown
  final String? statusMessage;
  final String? logs;

  ReplicateProgress({
    required this.status,
    this.progress,
    this.statusMessage,
    this.logs,
  });

  bool get isComplete => status == ReplicateStatus.succeeded;
  bool get isFailed => status == ReplicateStatus.failed || status == ReplicateStatus.canceled;
  bool get isProcessing => status == ReplicateStatus.processing || 
                          status == ReplicateStatus.starting ||
                          status == ReplicateStatus.queued;
}

