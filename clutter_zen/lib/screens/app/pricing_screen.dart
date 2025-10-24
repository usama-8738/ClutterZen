import '../../app_firebase.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';

class PricingScreen extends StatelessWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PlanCard(
            title: 'Free',
            price: '',
            subtitle: 'Get started',
            features: [
              '3 scans per month',
              'Basic AI analysis',
              'Standard tips',
            ],
            highlighted: false,
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: 'Pro',
            price: '9.99/mo',
            subtitle: 'Unlimited scanning',
            features: [
              'Unlimited scans',
              'Advanced AI plans',
              'Before/After generator',
              'Priority support',
            ],
            highlighted: true,
            onTap: () => _updateCredits(100),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCredits(int amount) async {
    final uid = AppFirebase.auth.currentUser?.uid;
    if (uid == null) return;
    await UserService.updateCredits(uid, amount);
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.features,
    required this.highlighted,
    this.onTap,
  });
  final String title;
  final String price;
  final String subtitle;
  final List<String> features;
  final bool highlighted;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final color =
        highlighted ? Theme.of(context).colorScheme.primary : Colors.grey[200]!;
    final cleaned = price.replaceAll('\u0000', '').trim();
    final displayPrice = cleaned.isEmpty ? 'Free' : '\$$cleaned';
    return Container(
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
        border: highlighted ? Border.all(color: color, width: 1.5) : null,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              if (highlighted) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Best Value',
                      style: TextStyle(color: Colors.white)),
                )
              ]
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600])),
          const SizedBox(height: 12),
          Text(displayPrice,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          for (final f in features)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(f)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: highlighted ? Colors.black : Colors.white,
              foregroundColor: highlighted ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(highlighted ? 'Upgrade' : 'Continue Free'),
          )
        ],
      ),
    );
  }
}
