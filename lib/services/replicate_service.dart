import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'replicate_error_handler.dart';

/// Callback for progress updates during image generation
typedef ReplicateProgressCallback = void Function(ReplicateProgress progress);

class ReplicateService {
  ReplicateService({
    required this.apiToken,
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.maxPollSeconds = 120, // Increased from 60 to 120
    this.pollInterval = const Duration(seconds: 2), // Poll every 2 seconds instead of 1
    this.onProgress,
  }) : _client = client ?? http.Client();

  final String apiToken;
  final http.Client _client;
  final Duration timeout;
  final int maxPollSeconds;
  final Duration pollInterval;
  final ReplicateProgressCallback? onProgress;

  /// Generates an organized image using Replicate API
  /// 
  /// [imageUrl] - URL of the image to process
  /// [fallbackToOriginal] - If true, returns original image URL on failure
  /// 
  /// Returns generated image URL, or original URL if fallback is enabled
  Future<String> generateOrganizedImage({
    required String imageUrl,
    bool fallbackToOriginal = true,
  }) async {
    try {
      // Start prediction
      final startResponse = await _client
          .post(
            Uri.parse('https://api.replicate.com/v1/predictions'),
            headers: {
              'Authorization': 'Token $apiToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
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
          )
          .timeout(timeout);

      if (startResponse.statusCode != 201) {
        final error = ReplicateErrorHandler.parseErrorResponse(startResponse);
        if (error != null) {
          if (fallbackToOriginal && !error.isRetryable) {
            return imageUrl; // Fallback to original
          }
          throw error;
        }
        throw Exception(
            'Replicate start failed: ${startResponse.statusCode} ${startResponse.body}');
      }

      final startJson = jsonDecode(startResponse.body) as Map<String, dynamic>;
      final String predictionId = (startJson['id'] as String);

      // Notify progress: starting
      onProgress?.call(ReplicateProgress(
        status: ReplicateStatus.starting,
        progress: 0.0,
        statusMessage: 'Starting image generation...',
      ));

      // Poll for completion
      final maxAttempts = (maxPollSeconds / pollInterval.inSeconds).ceil();
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        await Future.delayed(pollInterval);

        try {
          final statusResponse = await _client
              .get(
                Uri.parse('https://api.replicate.com/v1/predictions/$predictionId'),
                headers: {'Authorization': 'Token $apiToken'},
              )
              .timeout(timeout);

          if (statusResponse.statusCode != 200) {
            // Continue polling on non-200 status (might be temporary)
            continue;
          }

          final statusJson =
              jsonDecode(statusResponse.body) as Map<String, dynamic>;
          final status = _parseStatus(statusJson['status'] as String?);
          final logs = statusJson['logs'] as String?;
          final error = statusJson['error'] as String?;

          // Calculate progress (rough estimate based on attempt number)
          final estimatedProgress = (attempt / maxAttempts).clamp(0.0, 0.95);

          // Update progress
          onProgress?.call(ReplicateProgress(
            status: status,
            progress: estimatedProgress,
            statusMessage: _getStatusMessage(status),
            logs: logs,
          ));

          // Check status
          if (status == ReplicateStatus.succeeded) {
            final output = statusJson['output'];
            String? outputUrl;

            if (output is List && output.isNotEmpty) {
              outputUrl = output.first.toString();
            } else if (output is String) {
              outputUrl = output;
            }

            if (outputUrl != null && outputUrl.isNotEmpty) {
              // Notify completion
              onProgress?.call(ReplicateProgress(
                status: ReplicateStatus.succeeded,
                progress: 1.0,
                statusMessage: 'Generation complete!',
              ));
              return outputUrl;
            }

            // No output URL found
            if (fallbackToOriginal) {
              return imageUrl;
            }
            throw Exception('Replicate returned no output URL');
          }

          if (status == ReplicateStatus.failed || status == ReplicateStatus.canceled) {
            final errorMessage = error ?? 'Generation failed';
            if (fallbackToOriginal) {
              onProgress?.call(ReplicateProgress(
                status: status,
                progress: null,
                statusMessage: 'Generation failed, using original image',
              ));
              return imageUrl; // Fallback to original
            }
            throw Exception('Replicate failed: $errorMessage');
          }

          // Continue polling for processing/queued/starting status
        } on TimeoutException {
          // Individual poll timeout, continue to next attempt
          continue;
        } catch (e) {
          // Network error during polling, continue if we have attempts left
          if (attempt < maxAttempts - 1) {
            continue;
          }
          // Last attempt failed
          if (fallbackToOriginal) {
            return imageUrl;
          }
          rethrow;
        }
      }

      // Timeout: max attempts reached
      if (fallbackToOriginal) {
        onProgress?.call(ReplicateProgress(
          status: ReplicateStatus.failed,
          progress: null,
          statusMessage: 'Generation timed out, using original image',
        ));
        return imageUrl; // Fallback to original
      }
      throw TimeoutException(
        'Replicate generation timed out after $maxPollSeconds seconds',
        const Duration(seconds: 120),
      );
    } on ReplicateApiError {
      rethrow;
    } on TimeoutException {
      if (fallbackToOriginal) {
        return imageUrl;
      }
      rethrow;
    } catch (e) {
      if (fallbackToOriginal) {
        return imageUrl; // Fallback on any error
      }
      throw Exception('Replicate generation failed: $e');
    }
  }

  /// Parses Replicate status string to enum
  ReplicateStatus _parseStatus(String? status) {
    if (status == null) return ReplicateStatus.unknown;
    switch (status.toLowerCase()) {
      case 'starting':
        return ReplicateStatus.starting;
      case 'processing':
        return ReplicateStatus.processing;
      case 'succeeded':
        return ReplicateStatus.succeeded;
      case 'failed':
        return ReplicateStatus.failed;
      case 'canceled':
        return ReplicateStatus.canceled;
      case 'queued':
        return ReplicateStatus.queued;
      default:
        return ReplicateStatus.unknown;
    }
  }

  /// Gets user-friendly status message
  String _getStatusMessage(ReplicateStatus status) {
    switch (status) {
      case ReplicateStatus.starting:
        return 'Starting generation...';
      case ReplicateStatus.processing:
        return 'Processing image...';
      case ReplicateStatus.queued:
        return 'Queued for processing...';
      case ReplicateStatus.succeeded:
        return 'Generation complete!';
      case ReplicateStatus.failed:
        return 'Generation failed';
      case ReplicateStatus.canceled:
        return 'Generation canceled';
      case ReplicateStatus.unknown:
        return 'Processing...';
    }
  }
}
