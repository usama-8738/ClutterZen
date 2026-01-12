import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Service for managing Stripe Connect accounts
/// 
/// This service handles:
/// - Creating connected accounts
/// - OAuth flow for customer-provided accounts
/// - Account status management
/// - Processing payments on behalf of connected accounts
/// 
/// Note: Customer-provided account OAuth flow will be implemented later
class StripeConnectService {
  /// Get the Stripe secret key (platform key)
  static String? get _secretKey {
    final key = dotenv.env['STRIPE_SECRET_KEY']?.trim();
    if (key != null && key.isNotEmpty) return key;
    return const String.fromEnvironment('STRIPE_SECRET_KEY', defaultValue: '');
  }

  /// Get the Stripe Connect client ID (for OAuth)
  static String? get _clientId {
    final key = dotenv.env['STRIPE_CONNECT_CLIENT_ID']?.trim();
    if (key != null && key.isNotEmpty) return key;
    return const String.fromEnvironment(
      'STRIPE_CONNECT_CLIENT_ID',
      defaultValue: '',
    );
  }

  /// Check if Stripe Connect is configured
  static bool get isConfigured => 
      _secretKey != null && 
      _secretKey!.isNotEmpty &&
      _clientId != null &&
      _clientId!.isNotEmpty;

  /// Create a connected account (Standard account)
  /// 
  /// This creates a new Stripe account that will be connected via OAuth
  /// The account holder will complete onboarding via Stripe Dashboard
  /// 
  /// [email] - Email for the connected account
  /// [type] - Account type: 'standard' or 'express' (default: 'standard')
  /// [country] - Country code (e.g., 'US')
  /// 
  /// Returns the connected account ID
  static Future<String> createConnectedAccount({
    required String email,
    String type = 'standard',
    String? country,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Stripe Connect not configured. Please add STRIPE_SECRET_KEY and '
        'STRIPE_CONNECT_CLIENT_ID to .env file.',
      );
    }

    try {
      final body = <String, String>{
        'type': type,
        'email': email,
        if (country != null) 'country': country,
      };

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/accounts'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to create connected account: '
          '${error['error']?['message'] ?? response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['id'] as String;
    } catch (e) {
      throw Exception('Error creating connected account: $e');
    }
  }

  /// Get connected account details
  /// 
  /// [accountId] - Stripe Connect account ID
  /// 
  /// Returns account information
  static Future<Map<String, dynamic>> getConnectedAccount(
    String accountId,
  ) async {
    if (!isConfigured) {
      throw Exception('Stripe Connect not configured');
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/accounts/$accountId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to get connected account: '
          '${error['error']?['message'] ?? response.body}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error getting connected account: $e');
    }
  }

  /// Create account link for onboarding
  /// 
  /// This generates a URL that the account holder visits to complete onboarding
  /// 
  /// [accountId] - Stripe Connect account ID
  /// [returnUrl] - URL to redirect to after onboarding
  /// [refreshUrl] - URL to redirect to if link expires
  /// 
  /// Returns the account link URL
  /// 
  /// Note: For production, use StripeOAuthHandler.createAccountLinkViaFunction()
  /// to keep secret keys server-side
  static Future<String> createAccountLink({
    required String accountId,
    required String returnUrl,
    required String refreshUrl,
  }) async {
    if (!isConfigured) {
      throw Exception('Stripe Connect not configured');
    }

    try {
      final body = <String, String>{
        'account': accountId,
        'return_url': returnUrl,
        'refresh_url': refreshUrl,
        'type': 'account_onboarding',
      };

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/account_links'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to create account link: '
          '${error['error']?['message'] ?? response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['url'] as String;
    } catch (e) {
      throw Exception('Error creating account link: $e');
    }
  }

  /// Initiate OAuth flow for customer-provided account
  /// 
  /// This redirects the user to Stripe's OAuth page where they can
  /// authorize your platform to access their existing Stripe account
  /// 
  /// [returnUrl] - URL to redirect to after OAuth completion
  /// [state] - Optional state parameter for security
  /// 
  /// Returns the OAuth authorization URL
  /// 
  /// Note: This will be fully implemented when customer-provided accounts are added
  static Future<String> initiateOAuthFlow({
    required String returnUrl,
    String? state,
  }) async {
    if (!isConfigured || _clientId == null) {
      throw Exception(
        'Stripe Connect OAuth not configured. Please add STRIPE_CONNECT_CLIENT_ID '
        'to .env file.',
      );
    }

    // Generate state if not provided
    final oauthState = state ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Build OAuth URL
    final params = <String, String>{
      'client_id': _clientId!,
      'response_type': 'code',
      'scope': 'read_write',
      'redirect_uri': returnUrl,
      'state': oauthState,
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://connect.stripe.com/oauth/authorize?$queryString';
  }

  /// Exchange OAuth authorization code for account ID
  /// 
  /// After user authorizes, Stripe redirects with an authorization code.
  /// This method exchanges that code for the connected account ID.
  /// 
  /// [code] - Authorization code from OAuth redirect
  /// 
  /// Returns the connected account ID
  /// 
  /// Note: This will be fully implemented when customer-provided accounts are added
  static Future<String> exchangeOAuthCode(String code) async {
    if (!isConfigured) {
      throw Exception('Stripe Connect not configured');
    }

    try {
      final body = <String, String>{
        'code': code,
        'grant_type': 'authorization_code',
      };

      final response = await http.post(
        Uri.parse('https://connect.stripe.com/oauth/token'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to exchange OAuth code: '
          '${error['error']?['message'] ?? response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['stripe_user_id'] as String;
    } catch (e) {
      throw Exception('Error exchanging OAuth code: $e');
    }
  }

  /// Create payment intent on behalf of a connected account
  /// 
  /// This processes a payment where funds go to the connected account
  /// (minus platform fees)
  /// 
  /// [accountId] - Connected account ID
  /// [amount] - Amount in dollars
  /// [currency] - Currency code (default: 'usd')
  /// [applicationFeeAmount] - Platform fee in dollars (optional)
  /// 
  /// Returns the payment intent client secret
  static Future<String> createPaymentIntentForAccount({
    required String accountId,
    required double amount,
    String currency = 'usd',
    double? applicationFeeAmount,
  }) async {
    if (!isConfigured) {
      throw Exception('Stripe Connect not configured');
    }

    try {
      final amountInCents = (amount * 100).toInt();
      final feeInCents = applicationFeeAmount != null
          ? (applicationFeeAmount * 100).toInt()
          : null;

      final body = <String, String>{
        'amount': amountInCents.toString(),
        'currency': currency,
        'payment_method_types[]': 'card',
        'automatic_payment_methods[enabled]': 'true',
        if (feeInCents != null) 'application_fee_amount': feeInCents.toString(),
      };

      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Stripe-Account': accountId, // Process on behalf of connected account
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(
          'Failed to create payment intent: '
          '${error['error']?['message'] ?? response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['client_secret'] as String;
    } catch (e) {
      throw Exception('Error creating payment intent for account: $e');
    }
  }

  /// Launch OAuth flow in browser
  /// 
  /// Opens the OAuth URL in the user's browser
  /// 
  /// [returnUrl] - URL to return to after OAuth
  /// [state] - Optional state parameter
  static Future<void> launchOAuthFlow({
    required String returnUrl,
    String? state,
  }) async {
    try {
      final oauthUrl = await initiateOAuthFlow(
        returnUrl: returnUrl,
        state: state,
      );

      final uri = Uri.parse(oauthUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch OAuth URL');
      }
    } catch (e) {
      throw Exception('Error launching OAuth flow: $e');
    }
  }

  /// Check if an account is ready to accept payments
  /// 
  /// [accountId] - Connected account ID
  /// 
  /// Returns true if account can accept payments
  static Future<bool> isAccountReady(String accountId) async {
    try {
      final account = await getConnectedAccount(accountId);
      final chargesEnabled = account['charges_enabled'] as bool? ?? false;
      final payoutsEnabled = account['payouts_enabled'] as bool? ?? false;
      final detailsSubmitted = account['details_submitted'] as bool? ?? false;
      
      return chargesEnabled && payoutsEnabled && detailsSubmitted;
    } catch (_) {
      return false;
    }
  }
}

