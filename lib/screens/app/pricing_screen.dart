import 'package:flutter/material.dart';

import '../../app_firebase.dart';
import '../../models/subscription_plan.dart';
import '../../services/user_service.dart';
import '../payment/checkout_screen.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  String? _currentPlanId;

  @override
  void initState() {
    super.initState();
    _loadCurrentPlan();
  }

  Future<void> _loadCurrentPlan() async {
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await AppFirebase.firestore
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      setState(() {
        _currentPlanId = data?['plan'] as String? ?? 'free';
      });
    } catch (e) {
      setState(() {
        _currentPlanId = 'free';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final subscriptionPlan = SubscriptionPlan.plans[index];
          final isCurrentPlan = subscriptionPlan.id == _currentPlanId;
          
          // Convert to legacy format for _PlanCard
          final plan = _PlanOption(
            name: subscriptionPlan.name,
            priceLabel: subscriptionPlan.formattedPrice,
            subtitle: subscriptionPlan.description,
            features: subscriptionPlan.features,
            highlight: subscriptionPlan.isPopular,
            credits: subscriptionPlan.scanCredits,
            creditsTotal: subscriptionPlan.isUnlimited ? null : subscriptionPlan.scanCredits,
            isCurrentPlan: isCurrentPlan,
          );
          
          return _PlanCard(
            plan: plan,
            onSelect: () => _selectPlan(context, subscriptionPlan),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: SubscriptionPlan.plans.length,
      ),
    );
  }

  Future<void> _selectPlan(BuildContext context, SubscriptionPlan plan) async {
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to manage your plan.')),
      );
      return;
    }

    // If it's the current plan, do nothing
    if (plan.id == _currentPlanId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You are already on the ${plan.name} plan.')),
      );
      return;
    }

    // Navigate to checkout screen for paid plans
    if (plan.price > 0) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(plan: plan),
        ),
      );

      if (result == true) {
        await _loadCurrentPlan();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${plan.name} plan activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Free plan - apply directly
      await UserService.applyPlan(
        uid,
        planName: plan.name,
        scanCredits: plan.scanCredits,
        creditsTotal: plan.isUnlimited ? null : plan.scanCredits,
        resetUsage: true,
      );

      await _loadCurrentPlan();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${plan.name} plan activated.')),
      );
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, this.onSelect});

  final _PlanOption plan;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlightColor =
        plan.highlight ? colorScheme.primary : Colors.grey.shade200;

    return Container(
      decoration: BoxDecoration(
        color: plan.highlight
            ? highlightColor.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: plan.highlight ? Border.all(color: highlightColor, width: 1.5) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                plan.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (plan.highlight) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: highlightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Best Value',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            plan.subtitle,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Text(
            plan.priceLabel,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: plan.highlight ? highlightColor : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          if (plan.isCurrentPlan)
            OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Current Plan'),
            )
          else
            ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: plan.highlight ? Colors.black : Colors.white,
                foregroundColor: plan.highlight ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(plan.highlight ? 'Upgrade' : plan.name == 'Free' ? 'Select Free' : 'Upgrade'),
            ),
        ],
      ),
    );
  }
}

class _PlanOption {
  const _PlanOption({
    required this.name,
    required this.priceLabel,
    required this.subtitle,
    required this.features,
    required this.highlight,
    required this.credits,
    required this.creditsTotal,
    this.isCurrentPlan = false,
  });

  final String name;
  final String priceLabel;
  final String subtitle;
  final List<String> features;
  final bool highlight;
  final int credits;
  final int? creditsTotal;
  final bool isCurrentPlan;
}
