import 'package:flutter/material.dart';

import '../../app_firebase.dart';
import '../../services/user_service.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  static final List<_PlanOption> _plans = [
    const _PlanOption(
      name: 'Free',
      priceLabel: 'Free',
      subtitle: 'Get started',
      features: [
        '3 scans per month',
        'Core AI analysis',
        'Standard checklists',
      ],
      highlight: false,
      credits: 3,
      creditsTotal: 3,
    ),
    const _PlanOption(
      name: 'Pro',
      priceLabel: '\$9.99/mo',
      subtitle: 'Unlimited scanning',
      features: [
        'Unlimited scans included',
        'Advanced room-by-room plans',
        'Before/After generator priority',
        'Priority chat support',
      ],
      highlight: true,
      credits: 999,
      creditsTotal: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return _PlanCard(
            plan: plan,
            onSelect: () => _selectPlan(context, plan),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _plans.length,
      ),
    );
  }

  Future<void> _selectPlan(BuildContext context, _PlanOption plan) async {
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to manage your plan.')),
      );
      return;
    }

    await UserService.applyPlan(
      uid,
      planName: plan.name,
      scanCredits: plan.credits,
      creditsTotal: plan.creditsTotal,
      resetUsage: true,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${plan.name} plan activated.')),
    );
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
          ElevatedButton(
            onPressed: onSelect,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: plan.highlight ? Colors.black : Colors.white,
              foregroundColor: plan.highlight ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(plan.highlight ? 'Upgrade' : 'Stay on Free'),
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
  });

  final String name;
  final String priceLabel;
  final String subtitle;
  final List<String> features;
  final bool highlight;
  final int credits;
  final int? creditsTotal;
}
