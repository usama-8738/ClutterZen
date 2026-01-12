import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

/// Service for intelligent image compression that preserves visual quality
/// while significantly reducing file size using modern algorithms.
class ImageCompressionService {
  /// Compression quality levels
  static const int highQuality = 90;
  static const int mediumQuality = 85;
  static const int lowQuality = 80;

  /// Maximum dimensions for different use cases
  static const int maxDimensionForAnalysis = 1920; // For Vision API
  static const int maxDimensionForStorage = 1600; // For storage optimization
  static const int maxDimensionForThumbnail = 800; // For thumbnails

  /// Maximum file size targets (in bytes)
  static const int maxFileSizeForUpload = 5 * 1024 * 1024; // 5MB
  static const int maxFileSizeForAnalysis = 20 * 1024 * 1024; // 20MB (Vision API limit)

  /// Compresses an image file while preserving visual quality.
  /// 
  /// Uses intelligent compression that:
  /// - Maintains aspect ratio
  /// - Preserves visual quality (minQuality ensures no visible degradation)
  /// - Reduces file size significantly
  /// - Handles both JPEG and PNG formats
  /// 
  /// [filePath] - Path to the source image file
  /// [targetMaxDimension] - Maximum width or height (default: 1920 for analysis)
  /// [minQuality] - Minimum quality to preserve (default: 85, range: 0-100)
  /// [maxFileSize] - Target maximum file size in bytes (optional)
  /// 
  /// Returns compressed image bytes and metadata
  Future<CompressedImageResult> compressImageFile({
    required String filePath,
    int? targetMaxDimension,
    int minQuality = mediumQuality,
    int? maxFileSize,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Image file not found: $filePath');
      }

      final originalBytes = await file.readAsBytes();
      final originalSize = originalBytes.length;
      
      // Determine target dimensions
      final maxDimension = targetMaxDimension ?? maxDimensionForAnalysis;
      
      // Get image info to determine compression strategy
      final imageInfo = await _getImageInfo(filePath);
      final needsResize = imageInfo.width > maxDimension || 
                        imageInfo.height > maxDimension;
      
      // If image is already small and within size limit, return as-is
      if (!needsResize && 
          originalSize <= (maxFileSize ?? maxFileSizeForUpload) &&
          minQuality >= highQuality) {
        return CompressedImageResult(
          bytes: originalBytes,
          originalSize: originalSize,
          compressedSize: originalSize,
          compressionRatio: 1.0,
          width: imageInfo.width,
          height: imageInfo.height,
          format: imageInfo.format ?? CompressFormat.jpeg,
        );
      }

      // Calculate optimal dimensions maintaining aspect ratio
      int targetWidth = imageInfo.width;
      int targetHeight = imageInfo.height;
      
      if (needsResize) {
        if (imageInfo.width > imageInfo.height) {
          targetWidth = maxDimension;
          targetHeight = (imageInfo.height * maxDimension / imageInfo.width).round();
        } else {
          targetHeight = maxDimension;
          targetWidth = (imageInfo.width * maxDimension / imageInfo.height).round();
        }
      }

      // Determine format - prefer JPEG for photos, PNG for graphics
      final format = _determineOptimalFormat(filePath, imageInfo.format);
      final isJpeg = format == CompressFormat.jpeg;

      // Use adaptive quality based on original file size
      int quality = _calculateOptimalQuality(
        originalSize: originalSize,
        targetSize: maxFileSize ?? maxFileSizeForUpload,
        minQuality: minQuality,
        isJpeg: isJpeg,
      );

      // Perform compression using flutter_image_compress (native, fast)
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        filePath,
        minWidth: targetWidth,
        minHeight: targetHeight,
        quality: quality,
        format: format,
        keepExif: false, // Remove EXIF to reduce size
        // Use advanced compression options
        autoCorrectionAngle: true, // Auto-rotate if needed
      );

      if (compressedBytes == null || compressedBytes.isEmpty) {
        throw Exception('Compression failed: result is null or empty');
      }

      final compressedSize = compressedBytes.length;
      final compressionRatio = originalSize > 0 
          ? compressedSize / originalSize 
          : 1.0;

      // If still too large, apply additional compression pass
      if (maxFileSize != null && compressedSize > maxFileSize && quality > 60) {
        return await _applyAdditionalCompression(
          compressedBytes: compressedBytes,
          targetSize: maxFileSize,
          currentQuality: quality,
          minQuality: minQuality,
          width: targetWidth,
          height: targetHeight,
          format: format,
        );
      }

      return CompressedImageResult(
        bytes: compressedBytes,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
        width: targetWidth,
        height: targetHeight,
        format: format,
      );
    } catch (e) {
      throw Exception('Image compression failed: $e');
    }
  }

  /// Compresses image from bytes (useful for in-memory images)
  Future<CompressedImageResult> compressImageBytes({
    required Uint8List imageBytes,
    int? targetMaxDimension,
    int minQuality = mediumQuality,
    int? maxFileSize,
  }) async {
    try {
      final originalSize = imageBytes.length;
      
      // Decode image to get dimensions
      final decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }

      final originalWidth = decodedImage.width;
      final originalHeight = decodedImage.height;
      
      // Determine target dimensions
      final maxDimension = targetMaxDimension ?? maxDimensionForAnalysis;
      final needsResize = originalWidth > maxDimension || 
                         originalHeight > maxDimension;
      
      int targetWidth = originalWidth;
      int targetHeight = originalHeight;
      
      if (needsResize) {
        if (originalWidth > originalHeight) {
          targetWidth = maxDimension;
          targetHeight = (originalHeight * maxDimension / originalWidth).round();
        } else {
          targetHeight = maxDimension;
          targetWidth = (originalWidth * maxDimension / originalHeight).round();
        }
      }

      // Resize if needed
      img.Image processedImage = decodedImage;
      if (needsResize) {
        processedImage = img.copyResize(
          decodedImage,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear, // High quality resampling
        );
      }

      // Determine optimal quality
      final quality = _calculateOptimalQuality(
        originalSize: originalSize,
        targetSize: maxFileSize ?? maxFileSizeForUpload,
        minQuality: minQuality,
        isJpeg: true, // Assume JPEG for bytes
      );

      // Encode with quality
      final compressedBytes = Uint8List.fromList(
        img.encodeJpg(processedImage, quality: quality),
      );

      final compressedSize = compressedBytes.length;
      final compressionRatio = originalSize > 0 
          ? compressedSize / originalSize 
          : 1.0;

      // Additional compression if needed
      if (maxFileSize != null && compressedSize > maxFileSize && quality > 60) {
        return await _applyAdditionalCompression(
          compressedBytes: compressedBytes,
          targetSize: maxFileSize,
          currentQuality: quality,
          minQuality: minQuality,
          width: targetWidth,
          height: targetHeight,
          format: CompressFormat.jpeg,
        );
      }

      return CompressedImageResult(
        bytes: compressedBytes,
        originalSize: originalSize,
        compressedSize: compressedSize,
        compressionRatio: compressionRatio,
        width: targetWidth,
        height: targetHeight,
        format: CompressFormat.jpeg,
      );
    } catch (e) {
      throw Exception('Image bytes compression failed: $e');
    }
  }

  /// Creates a thumbnail version of an image
  Future<CompressedImageResult> createThumbnail({
    required String filePath,
    int maxDimension = maxDimensionForThumbnail,
    int quality = highQuality,
  }) async {
    return compressImageFile(
      filePath: filePath,
      targetMaxDimension: maxDimension,
      minQuality: quality,
      maxFileSize: 500 * 1024, // 500KB for thumbnails
    );
  }

  /// Applies additional compression pass if target size not met
  Future<CompressedImageResult> _applyAdditionalCompression({
    required Uint8List compressedBytes,
    required int targetSize,
    required int currentQuality,
    required int minQuality,
    required int width,
    required int height,
    required CompressFormat format,
  }) async {
    int quality = currentQuality;
    Uint8List result = compressedBytes;
    int attempts = 0;
    const maxAttempts = 5;

    while (result.length > targetSize && quality > minQuality && attempts < maxAttempts) {
      quality = (quality * 0.9).round().clamp(minQuality, 100);
      attempts++;

      // Decode and re-encode with lower quality
      final decoded = img.decodeImage(result);
      if (decoded == null) break;

      result = Uint8List.fromList(
        img.encodeJpg(decoded, quality: quality),
      );
    }

    return CompressedImageResult(
      bytes: result,
      originalSize: compressedBytes.length,
      compressedSize: result.length,
      compressionRatio: result.length / compressedBytes.length,
      width: width,
      height: height,
      format: format,
    );
  }

  /// Gets image information without full decode
  Future<_ImageInfo> _getImageInfo(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      
      if (decoded == null) {
        throw Exception('Failed to decode image for info');
      }

      return _ImageInfo(
        width: decoded.width,
        height: decoded.height,
        format: _detectFormat(filePath),
      );
    } catch (e) {
      throw Exception('Failed to get image info: $e');
    }
  }

  /// Determines optimal format based on image characteristics
  CompressFormat _determineOptimalFormat(String filePath, CompressFormat? detected) {
    final extension = filePath.toLowerCase();
    
    if (extension.endsWith('.png')) {
      // PNG for graphics/transparency, but convert large PNGs to JPEG
      return CompressFormat.jpeg; // Convert PNG to JPEG for better compression
    } else if (extension.endsWith('.jpg') || extension.endsWith('.jpeg')) {
      return CompressFormat.jpeg;
    } else if (extension.endsWith('.heic') || extension.endsWith('.heif')) {
      return CompressFormat.heic;
    } else {
      return CompressFormat.jpeg; // Default to JPEG
    }
  }

  /// Detects image format from file path
  CompressFormat _detectFormat(String filePath) {
    final extension = filePath.toLowerCase();
    if (extension.endsWith('.png')) return CompressFormat.png;
    if (extension.endsWith('.heic') || extension.endsWith('.heif')) {
      return CompressFormat.heic;
    }
    return CompressFormat.jpeg;
  }

  /// Calculates optimal quality based on original size and target
  int _calculateOptimalQuality({
    required int originalSize,
    required int targetSize,
    required int minQuality,
    required bool isJpeg,
  }) {
    // If already small, use high quality
    if (originalSize <= targetSize) {
      return highQuality;
    }

    // Calculate compression ratio needed
    final ratio = targetSize / originalSize;
    
    // Map ratio to quality (non-linear for better visual results)
    int quality;
    if (ratio >= 0.8) {
      quality = highQuality;
    } else if (ratio >= 0.6) {
      quality = mediumQuality;
    } else if (ratio >= 0.4) {
      quality = 75;
    } else {
      quality = 65;
    }

    // Ensure quality is within bounds
    return quality.clamp(minQuality, 100);
  }
}

/// Result of image compression operation
class CompressedImageResult {
  final Uint8List bytes;
  final int originalSize;
  final int compressedSize;
  final double compressionRatio;
  final int width;
  final int height;
  final CompressFormat format;

  CompressedImageResult({
    required this.bytes,
    required this.originalSize,
    required this.compressedSize,
    required this.compressionRatio,
    required this.width,
    required this.height,
    required this.format,
  });

  /// Size reduction percentage
  double get sizeReductionPercent => (1 - compressionRatio) * 100;

  /// Whether compression was effective
  bool get wasCompressed => compressionRatio < 0.95;

  @override
  String toString() {
    final originalMB = (originalSize / (1024 * 1024)).toStringAsFixed(2);
    final compressedMB = (compressedSize / (1024 * 1024)).toStringAsFixed(2);
    return 'CompressedImageResult: ${originalMB}MB → ${compressedMB}MB '
           '(${sizeReductionPercent.toStringAsFixed(1)}% reduction, '
           '$width x $height)';
  }
}

/// Internal image information
class _ImageInfo {
  final int width;
  final int height;
  final CompressFormat? format;

  _ImageInfo({
    required this.width,
    required this.height,
    this.format,
  });
}

