import 'package:flutter/foundation.dart';

/// Model representing a Stripe Connect account
@immutable
class StripeConnectedAccount {
  const StripeConnectedAccount({
    required this.accountId,
    required this.userId,
    required this.email,
    required this.type,
    required this.status,
    this.businessName,
    this.country,
    this.chargesEnabled = false,
    this.payoutsEnabled = false,
    this.detailsSubmitted = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Stripe Connect account ID (starts with 'acct_')
  final String accountId;
  
  /// User ID in our system (Firebase UID)
  final String userId;
  
  /// Account email
  final String email;
  
  /// Account type: 'standard' or 'express'
  final String type;
  
  /// Account status: 'pending', 'restricted', 'enabled', 'disabled'
  final String status;
  
  /// Business name (if applicable)
  final String? businessName;
  
  /// Country code (e.g., 'US')
  final String? country;
  
  /// Whether charges are enabled for this account
  final bool chargesEnabled;
  
  /// Whether payouts are enabled for this account
  final bool payoutsEnabled;
  
  /// Whether account details have been submitted
  final bool detailsSubmitted;
  
  /// When the account was created
  final DateTime? createdAt;
  
  /// When the account was last updated
  final DateTime? updatedAt;

  /// Check if account is fully active
  bool get isActive => 
      status == 'enabled' && 
      chargesEnabled && 
      payoutsEnabled && 
      detailsSubmitted;

  /// Check if account is pending setup
  bool get isPending => status == 'pending' || !detailsSubmitted;

  /// Create from Firestore document
  factory StripeConnectedAccount.fromFirestore(
    Map<String, dynamic> data,
    String accountId,
  ) {
    return StripeConnectedAccount(
      accountId: accountId,
      userId: data['userId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      type: data['type'] as String? ?? 'standard',
      status: data['status'] as String? ?? 'pending',
      businessName: data['businessName'] as String?,
      country: data['country'] as String?,
      chargesEnabled: data['chargesEnabled'] as bool? ?? false,
      payoutsEnabled: data['payoutsEnabled'] as bool? ?? false,
      detailsSubmitted: data['detailsSubmitted'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as dynamic).toDate() as DateTime?
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as dynamic).toDate() as DateTime?
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'type': type,
      'status': status,
      if (businessName != null) 'businessName': businessName,
      if (country != null) 'country': country,
      'chargesEnabled': chargesEnabled,
      'payoutsEnabled': payoutsEnabled,
      'detailsSubmitted': detailsSubmitted,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }
}

/// OAuth state for Stripe Connect onboarding
@immutable
class StripeConnectOAuthState {
  const StripeConnectOAuthState({
    required this.state,
    required this.userId,
    this.returnUrl,
    this.refreshUrl,
  });

  /// OAuth state token (for security)
  final String state;
  
  /// User ID initiating the OAuth flow
  final String userId;
  
  /// URL to return to after OAuth completion
  final String? returnUrl;
  
  /// URL to refresh the account link if expired
  final String? refreshUrl;
}

