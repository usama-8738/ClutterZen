import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Service for internationalization and localization
class I18nService {
  static Locale _currentLocale = const Locale('en', 'US');
  static final List<Locale> _supportedLocales = [
    const Locale('en', 'US'),
    const Locale('es', 'ES'),
    const Locale('fr', 'FR'),
    const Locale('de', 'DE'),
  ];

  /// Get current locale
  static Locale get currentLocale => _currentLocale;

  /// Get supported locales
  static List<Locale> get supportedLocales => _supportedLocales;

  /// Set locale
  static void setLocale(Locale locale) {
    if (_supportedLocales.contains(locale)) {
      _currentLocale = locale;
      Intl.defaultLocale = locale.toString();
      if (kDebugMode) {
        debugPrint('Locale changed to: ${locale.toString()}');
      }
    } else {
      if (kDebugMode) {
        debugPrint('Locale not supported: ${locale.toString()}');
      }
    }
  }

  /// Get localized string
  /// 
  /// For now, returns English strings. In production, this would
  /// load from translation files (ARB files, JSON, etc.)
  static String translate(String key, {Map<String, String>? params}) {
    // Basic translation map (English only for now)
    // In production, load from translation files based on currentLocale
    final translations = _getTranslations();
    
    String translation = translations[key] ?? key;
    
    // Replace parameters
    if (params != null) {
      params.forEach((paramKey, value) {
        translation = translation.replaceAll('{$paramKey}', value);
      });
    }
    
    return translation;
  }

  /// Get translation map (English only for now)
  static Map<String, String> _getTranslations() {
    return {
      'app_name': 'ClutterZen',
      'welcome': 'Welcome',
      'scan_room': 'Scan Room',
      'history': 'History',
      'settings': 'Settings',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'next': 'Next',
      'previous': 'Previous',
      'done': 'Done',
      'search': 'Search',
      'filter': 'Filter',
      'no_results': 'No results found',
      'offline': 'Offline',
      'online': 'Online',
      'sync': 'Sync',
      'subscription': 'Subscription',
      'free_plan': 'Free Plan',
      'pro_plan': 'Pro Plan',
      'upgrade': 'Upgrade',
      'downgrade': 'Downgrade',
      'manage_subscription': 'Manage Subscription',
      'contact_support': 'Contact Support',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'faqs': 'FAQs',
      'language': 'Language',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'credits': 'Credits',
      'scans_remaining': 'Scans Remaining',
      'unlimited': 'Unlimited',
    };
  }

  /// Check if locale is supported
  static bool isLocaleSupported(Locale locale) {
    return _supportedLocales.any((l) =>
        l.languageCode == locale.languageCode &&
        l.countryCode == locale.countryCode);
  }

  /// Get locale display name
  static String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return locale.toString();
    }
  }
}

