import 'package:flutter/material.dart';

import 'screens/app/splash_screen.dart';
import 'screens/app/root_nav.dart';
import 'screens/app/categories_screen.dart';
import 'screens/app/photo_upload_screen.dart';
import 'screens/app/processing_screen.dart';
import 'screens/app/settings_screen.dart';
import 'screens/app/notification_settings_screen.dart';
import 'screens/app/contact_us_screen.dart';
import 'screens/app/pricing_screen.dart';
import 'screens/app/terms_services_screen.dart';
import 'screens/app/faqs_screen.dart';
import 'screens/app/history_screen.dart';
import 'screens/app/diagnostics_screen.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/auth/create_account_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/update_profile_screen.dart';
import 'screens/auth/update_password_screen.dart';
import 'screens/auth/phone_otp_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/splash': (_) => const SplashScreen(),
    '/home': (_) => const RootNav(),
    '/categories': (_) => const CategoriesScreen(),
    '/photo-upload': (_) => const CaptureScreen(),
    '/processing': (_) => const ProcessingScreen(),
    '/settings': (_) => const SettingsScreen(),
    '/notification-settings': (_) => const NotificationSettingsScreen(),
    '/contact-us': (_) => const ContactUsScreen(),
    '/pricing': (_) => const PricingScreen(),
    '/terms': (_) => const TermsServicesScreen(),
    '/faqs': (_) => const FaqsScreen(),
    '/history': (_) => const HistoryScreen(),
    '/diagnostics': (_) => const DiagnosticsScreen(),
    '/sign-in': (_) => const SignInScreen(),
    '/create-account': (_) => const CreateAccountScreen(),
    '/forgot-password': (_) => const ForgotPasswordScreen(),
    '/update-profile': (_) => const UpdateProfileScreen(),
    '/update-password': (_) => const UpdatePasswordScreen(),
    '/phone': (_) => const PhoneOtpScreen(),
  };

  static List<Map<String, String>> allScreens = [
    {'name': 'splash-screen', 'route': '/splash'},
    {'name': 'home-screen', 'route': '/home'},
    {'name': 'home-screen-2', 'route': '/home'},
    {'name': 'categories', 'route': '/categories'},
    {'name': 'capture-screen', 'route': '/photo-upload'},
    {'name': 'processing', 'route': '/processing'},
    // results screens are accessed via actual flow from Upload → Vision
    {'name': 'settings', 'route': '/settings'},
    {'name': 'settings-2', 'route': '/settings'},
    {'name': 'notification-settings', 'route': '/notification-settings'},
    {'name': 'contact-us', 'route': '/contact-us'},
    {'name': 'pricing', 'route': '/pricing'},
    {'name': 'pricing-2', 'route': '/pricing'},
    {'name': 'terms-services', 'route': '/terms'},
    {'name': 'terms-services-2', 'route': '/terms'},
    {'name': 'terms-services-3', 'route': '/terms'},
    {'name': 'faqs', 'route': '/faqs'},
    {'name': 'history', 'route': '/history'},
  ];
}


