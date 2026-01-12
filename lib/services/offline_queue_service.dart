import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../app_firebase.dart';
import '../models/vision_models.dart';
import 'connectivity_service.dart';

/// Service for managing offline operations queue
/// 
/// Queues operations when offline and syncs when connection is restored
class OfflineQueueService {
  static const String _queueKey = 'offline_queue';
  static const String _pendingAnalysesKey = 'pending_analyses';

  /// Add an analysis to the offline queue
  static Future<void> queueAnalysis({
    required String imageUrl,
    required VisionAnalysis analysis,
    String? organizedImageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_pendingAnalysesKey) ?? [];
      
      final analysisData = {
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
        'timestamp': DateTime.now().toIso8601String(),
      };

      queue.add(jsonEncode(analysisData));
      await prefs.setStringList(_pendingAnalysesKey, queue);

      if (kDebugMode) {
        debugPrint('Queued analysis for offline sync. Queue size: ${queue.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error queueing analysis: $e');
      }
    }
  }

  /// Get pending analyses from queue
  static Future<List<Map<String, dynamic>>> getPendingAnalyses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_pendingAnalysesKey) ?? [];
      
      return queue.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending analyses: $e');
      }
      return [];
    }
  }

  /// Clear pending analyses after successful sync
  static Future<void> clearPendingAnalyses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingAnalysesKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing pending analyses: $e');
      }
    }
  }

  /// Sync pending analyses to Firestore when online
  static Future<void> syncPendingAnalyses() async {
    if (!connectivityService.isConnected) {
      if (kDebugMode) {
        debugPrint('Not connected, skipping sync');
      }
      return;
    }

    try {
      final pending = await getPendingAnalyses();
      if (pending.isEmpty) return;

      final uid = AppFirebase.auth.currentUser?.uid;
      if (uid == null) {
        if (kDebugMode) {
          debugPrint('User not authenticated, cannot sync');
        }
        return;
      }

      if (kDebugMode) {
        debugPrint('Syncing ${pending.length} pending analyses...');
      }

      for (final item in pending) {
        try {
          final imageUrl = item['imageUrl'] as String;
          final analysisData = item['analysis'] as Map<String, dynamic>;
          final organizedImageUrl = item['organizedImageUrl'] as String?;

          // Reconstruct VisionAnalysis
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

          final analysis = VisionAnalysis(objects: objects, labels: labels);

          // Save to Firestore
          await AppFirebase.firestore.collection('analyses').add({
            'uid': uid,
            'imageUrl': imageUrl,
            'organizedImageUrl': organizedImageUrl,
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
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error syncing individual analysis: $e');
          }
          // Continue with next item
        }
      }

      // Clear queue after successful sync
      await clearPendingAnalyses();

      if (kDebugMode) {
        debugPrint('Successfully synced ${pending.length} analyses');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error syncing pending analyses: $e');
      }
    }
  }

  /// Add a generic operation to the queue
  static Future<void> queueOperation({
    required String operationType,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];
      
      final operation = {
        'type': operationType,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };

      queue.add(jsonEncode(operation));
      await prefs.setStringList(_queueKey, queue);

      if (kDebugMode) {
        debugPrint('Queued operation: $operationType. Queue size: ${queue.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error queueing operation: $e');
      }
    }
  }

  /// Get pending operations
  static Future<List<Map<String, dynamic>>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_queueKey) ?? [];
      
      return queue.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting pending operations: $e');
      }
      return [];
    }
  }

  /// Clear pending operations
  static Future<void> clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing pending operations: $e');
      }
    }
  }
}

