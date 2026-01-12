import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Service for Firebase Analytics tracking
class AnalyticsService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// Initialize analytics service
  static Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      
      if (kDebugMode) {
        debugPrint('Analytics service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize analytics: $e');
      }
    }
  }

  /// Get analytics instance
  static FirebaseAnalytics? get analytics => _analytics;

  /// Get analytics observer for navigation tracking
  static FirebaseAnalyticsObserver? get observer => _observer;

  /// Log a screen view
  static Future<void> logScreenView(String screenName) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: screenName);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error logging screen view: $e');
      }
    }
  }

  /// Log an event
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error logging event: $e');
      }
    }
  }

  /// Log image analysis
  static Future<void> logImageAnalysis({
    required int objectCount,
    required String category,
  }) async {
    await logEvent(
      name: 'image_analyzed',
      parameters: {
        'object_count': objectCount,
        'category': category,
      },
    );
  }

  /// Log subscription event
  static Future<void> logSubscription({
    required String planName,
    required double price,
  }) async {
    await logEvent(
      name: 'subscription_purchased',
      parameters: {
        'plan_name': planName,
        'price': price,
        'currency': 'USD',
      },
    );
  }

  /// Log professional service booking
  static Future<void> logServiceBooking({
    required String professionalId,
    required double amount,
    required int hours,
  }) async {
    await logEvent(
      name: 'service_booked',
      parameters: {
        'professional_id': professionalId,
        'amount': amount,
        'hours': hours,
        'currency': 'USD',
      },
    );
  }

  /// Log contact form submission
  static Future<void> logContactSubmission() async {
    await logEvent(name: 'contact_form_submitted');
  }

  /// Set user property
  static Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (_analytics == null) return;
    try {
      await _analytics!.setUserProperty(name: name, value: value);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting user property: $e');
      }
    }
  }

  /// Set user ID
  static Future<void> setUserId(String? userId) async {
    if (_analytics == null) return;
    try {
      await _analytics!.setUserId(id: userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting user ID: $e');
      }
    }
  }
}

