/// Model representing a subscription plan
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price; // Monthly price in USD
  final String priceId; // Stripe Price ID
  final List<String> features;
  final int scanCredits; // null means unlimited
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.priceId,
    required this.features,
    required this.scanCredits,
    this.isPopular = false,
  });

  /// Predefined plans
  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      description: 'Get started with basic features',
      price: 0.0,
      priceId: '', // No Stripe price ID for free plan
      features: [
        '3 scans per month',
        'Core AI analysis',
        'Standard checklists',
        'Basic product recommendations',
      ],
      scanCredits: 3,
      isPopular: false,
    ),
    SubscriptionPlan(
      id: 'pro',
      name: 'Pro',
      description: 'Unlimited scanning and advanced features',
      price: 9.99,
      priceId: 'price_pro_monthly', // Replace with your actual Stripe Price ID
      features: [
        'Unlimited scans',
        'Advanced room-by-room plans',
        'Before/After generator priority',
        'Priority chat support',
        'Advanced product recommendations',
        'Professional service matching',
      ],
      scanCredits: -1, // -1 means unlimited
      isPopular: true,
    ),
  ];

  /// Get plan by ID
  static SubscriptionPlan? getById(String id) {
    try {
      return plans.firstWhere((plan) => plan.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Check if plan has unlimited credits
  bool get isUnlimited => scanCredits < 0;

  /// Format price as string
  String get formattedPrice {
    if (price == 0) return 'Free';
    return '\$${price.toStringAsFixed(2)}/mo';
  }
}

