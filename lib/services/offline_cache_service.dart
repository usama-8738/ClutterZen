import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vision_models.dart';

/// Service for caching analysis results offline
class OfflineCacheService {
  static const String _cachePrefix = 'analysis_cache_';
  static const int _maxCacheSize = 50; // Maximum number of cached analyses

  /// Cache an analysis result
  static Future<void> cacheAnalysis({
    required String imageUrl,
    required VisionAnalysis analysis,
    String? organizedImageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix${_hashUrl(imageUrl)}';
      
      final cacheData = {
        'imageUrl': imageUrl,
        'analysis': {
          'objects': analysis.objects.map((o) => {
            'name': o.name,
            'confidence': o.confidence,
            'box': {
              'left': o.box.left,
              'top': o.box.top,
              'width': o.box.width,
              'height': o.box.height,
            },
          }).toList(),
          'labels': analysis.labels,
        },
        'organizedImageUrl': organizedImageUrl,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      
      // Clean up old cache entries if needed
      await _cleanupCache(prefs);

      if (kDebugMode) {
        debugPrint('Cached analysis for: $imageUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error caching analysis: $e');
      }
    }
  }

  /// Get cached analysis if available
  static Future<CachedAnalysis?> getCachedAnalysis(String imageUrl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix${_hashUrl(imageUrl)}';
      final cached = prefs.getString(cacheKey);
      
      if (cached == null) return null;

      final data = jsonDecode(cached) as Map<String, dynamic>;
      
      // Reconstruct VisionAnalysis
      final analysisData = data['analysis'] as Map<String, dynamic>;
      final objects = (analysisData['objects'] as List<dynamic>).map((o) {
        final obj = o as Map<String, dynamic>;
        final box = obj['box'] as Map<String, dynamic>;
        return DetectedObject(
          name: obj['name'] as String,
          confidence: (obj['confidence'] as num).toDouble(),
          box: BoundingBoxNormalized(
            left: (box['left'] as num).toDouble(),
            top: (box['top'] as num).toDouble(),
            width: (box['width'] as num).toDouble(),
            height: (box['height'] as num).toDouble(),
          ),
        );
      }).toList();

      final labels = (analysisData['labels'] as List<dynamic>)
          .map((l) => l as String)
          .toList();

      return CachedAnalysis(
        analysis: VisionAnalysis(objects: objects, labels: labels),
        organizedImageUrl: data['organizedImageUrl'] as String?,
        cachedAt: DateTime.parse(data['cachedAt'] as String),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting cached analysis: $e');
      }
      return null;
    }
  }

  /// Clear all cached analyses
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      if (kDebugMode) {
        debugPrint('Cleared analysis cache');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing cache: $e');
      }
    }
  }

  /// Clean up old cache entries
  static Future<void> _cleanupCache(SharedPreferences prefs) async {
    try {
      final keys = prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
      
      if (keys.length <= _maxCacheSize) return;

      // Sort by cached timestamp and remove oldest
      final entries = <MapEntry<String, DateTime>>[];
      for (final key in keys) {
        final cached = prefs.getString(key);
        if (cached != null) {
          try {
            final data = jsonDecode(cached) as Map<String, dynamic>;
            final cachedAt = DateTime.parse(data['cachedAt'] as String);
            entries.add(MapEntry(key, cachedAt));
          } catch (_) {
            // Invalid entry, remove it
            await prefs.remove(key);
          }
        }
      }

      // Sort by date (oldest first)
      entries.sort((a, b) => a.value.compareTo(b.value));

      // Remove oldest entries
      final toRemove = entries.length - _maxCacheSize;
      for (int i = 0; i < toRemove; i++) {
        await prefs.remove(entries[i].key);
      }

      if (kDebugMode) {
        debugPrint('Cleaned up $toRemove old cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cleaning up cache: $e');
      }
    }
  }

  /// Generate hash for URL (simple implementation)
  static String _hashUrl(String url) {
    return url.hashCode.toString();
  }
}

/// Cached analysis result
class CachedAnalysis {
  const CachedAnalysis({
    required this.analysis,
    this.organizedImageUrl,
    required this.cachedAt,
  });

  final VisionAnalysis analysis;
  final String? organizedImageUrl;
  final DateTime cachedAt;

  /// Check if cache is still valid (e.g., less than 7 days old)
  bool get isValid {
    final age = DateTime.now().difference(cachedAt);
    return age.inDays < 7;
  }
}

