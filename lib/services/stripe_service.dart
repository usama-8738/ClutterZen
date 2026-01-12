import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

/// Service for handling Stripe payment processing
/// 
/// This service handles:
/// - Payment intent creation
/// - Payment sheet initialization and display
/// - Subscription creation and management
/// - Error handling
class StripeService {
  static bool _initialized = false;
  static String? _publishableKey;
  static String? _secretKey;

  /// Initialize Stripe with publishable key from environment
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Get publishable key from dotenv or environment
      _publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']?.trim();
      _secretKey = dotenv.env['STRIPE_SECRET_KEY']?.trim();

      // Fallback to environment variables if dotenv doesn't have them
      if (_publishableKey == null || _publishableKey!.isEmpty) {
        _publishableKey = const String.fromEnvironment(
          'STRIPE_PUBLISHABLE_KEY',
          defaultValue: '',
        );
      }

      if (_secretKey == null || _secretKey!.isEmpty) {
        _secretKey = const String.fromEnvironment(
          'STRIPE_SECRET_KEY',
          defaultValue: '',
        );
      }

      if (_publishableKey == null || _publishableKey!.isEmpty) {
        if (kDebugMode) {
          debugPrint('Warning: STRIPE_PUBLISHABLE_KEY not found. Stripe payments will not work.');
        }
        _initialized = false;
        return;
      }

      // Initialize Stripe
      Stripe.publishableKey = _publishableKey!;
      Stripe.merchantIdentifier = 'merchant.com.clutterzen';
      
      await Stripe.instance.applySettings();
      _initialized = true;

      if (kDebugMode) {
        debugPrint('Stripe initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing Stripe: $e');
      }
      _initialized = false;
    }
  }

  /// Check if Stripe is properly initialized
  static bool get isInitialized => _initialized;

  /// Get the publishable key (for display purposes only)
  static String? get publishableKey => _publishableKey;

  /// Create a payment intent for a one-time payment
  /// 
  /// [amount] - Amount in dollars (e.g., 9.99 for $9.99)
  /// [currency] - Currency code (default: 'usd')
  /// [customerId] - Optional Stripe customer ID for returning customers
  /// 
  /// Returns the payment intent client secret
  static Future<String> createPaymentIntent({
    required double amount,
    String currency = 'usd',
    String? customerId,
  }) async {
    if (!_initialized || _secretKey == null || _secretKey!.isEmpty) {
      throw Exception('Stripe not initialized. Please add your Stripe API keys to .env file.');
    }

    try {
      final amountInCents = (amount * 100).toInt();
      
      final body = <String, String>{
        'amount': amountInCents.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
        'automatic_payment_methods[enabled]': 'true',
      };

      if (customerId != null) {
        body['customer'] = customerId;
      }

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception('Failed to create payment intent: ${error['error']?['message'] ?? response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['client_secret'] as String;
    } catch (e) {
      throw Exception('Error creating payment intent: $e');
    }
  }

  /// Create a subscription for recurring payments
  /// 
  /// [priceId] - Stripe Price ID for the subscription plan
  /// [customerId] - Optional Stripe customer ID
  /// 
  /// Returns the subscription client secret for confirmation
  static Future<String> createSubscription({
    required String priceId,
    String? customerId,
  }) async {
    if (!_initialized || _secretKey == null || _secretKey!.isEmpty) {
      throw Exception('Stripe not initialized. Please add your Stripe API keys to .env file.');
    }

    try {
      // First, create or get customer
      String finalCustomerId = customerId ?? await _createCustomer();

      // Create subscription
      final body = <String, String>{
        'customer': finalCustomerId,
        'items[0][price]': priceId,
        'payment_behavior': 'default_incomplete',
        'payment_settings[payment_method_types][]': 'card',
        'expand[]': 'latest_invoice.payment_intent',
      };

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/subscriptions'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception('Failed to create subscription: ${error['error']?['message'] ?? response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final invoice = data['latest_invoice'] as Map<String, dynamic>?;
      final paymentIntent = invoice?['payment_intent'] as Map<String, dynamic>?;
      
      final clientSecret = paymentIntent?['client_secret'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('No payment intent in subscription response');
      }
      return clientSecret;
    } catch (e) {
      throw Exception('Error creating subscription: $e');
    }
  }

  /// Create a Stripe customer
  /// 
  /// [email] - Customer email address
  /// [name] - Customer name
  /// 
  /// Returns the customer ID
  static Future<String> _createCustomer({String? email, String? name}) async {
    if (!_initialized || _secretKey == null || _secretKey!.isEmpty) {
      throw Exception('Stripe not initialized');
    }

    try {
      final body = <String, String>{};
      if (email != null) body['email'] = email;
      if (name != null) body['name'] = name;

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception('Failed to create customer: ${error['error']?['message'] ?? response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['id'] as String;
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  /// Initialize and display payment sheet for one-time payment
  /// 
  /// [amount] - Amount in dollars
  /// [currency] - Currency code
  /// [customerId] - Optional customer ID
  static Future<void> presentPaymentSheet({
    required double amount,
    String currency = 'usd',
    String? customerId,
  }) async {
    if (!_initialized) {
      await initialize();
      if (!_initialized) {
        throw Exception('Stripe not initialized. Please add your Stripe API keys to .env file.');
      }
    }

    try {
      // Create payment intent
      final clientSecret = await createPaymentIntent(
        amount: amount,
        currency: currency,
        customerId: customerId,
      );

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'ClutterZen',
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      throw Exception('Stripe error: ${e.error.message}');
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  /// Initialize and display payment sheet for subscription
  /// 
  /// [priceId] - Stripe Price ID for the subscription
  /// [customerId] - Optional customer ID
  static Future<void> presentSubscriptionSheet({
    required String priceId,
    String? customerId,
  }) async {
    if (!_initialized) {
      await initialize();
      if (!_initialized) {
        throw Exception('Stripe not initialized. Please add your Stripe API keys to .env file.');
      }
    }

    try {
      // Create subscription
      final clientSecret = await createSubscription(
        priceId: priceId,
        customerId: customerId,
      );

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'ClutterZen',
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
    } on StripeException catch (e) {
      throw Exception('Stripe error: ${e.error.message}');
    } catch (e) {
      throw Exception('Subscription failed: $e');
    }
  }

  /// Cancel a subscription
  /// 
  /// [subscriptionId] - Stripe subscription ID
  static Future<void> cancelSubscription(String subscriptionId) async {
    if (!_initialized || _secretKey == null || _secretKey!.isEmpty) {
      throw Exception('Stripe not initialized');
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'cancel_at_period_end': 'true'},
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception('Failed to cancel subscription: ${error['error']?['message'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Error canceling subscription: $e');
    }
  }

  /// Get subscription status
  /// 
  /// [subscriptionId] - Stripe subscription ID
  static Future<Map<String, dynamic>> getSubscription(String subscriptionId) async {
    if (!_initialized || _secretKey == null || _secretKey!.isEmpty) {
      throw Exception('Stripe not initialized');
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception('Failed to get subscription: ${error['error']?['message'] ?? response.body}');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error getting subscription: $e');
    }
  }
}

