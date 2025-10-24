import 'package:flutter/material.dart';

import '../../app_firebase.dart';
import '../../env.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppFirebase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                  radius: 30, child: Text(_initials(user?.displayName))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user?.displayName ?? 'Guest',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(user?.email ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[600])),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          // Subscription card
          Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Free Plan',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text('Upgrade')),
              ]),
              const SizedBox(height: 8),
              Row(children: const [
                Icon(Icons.camera_alt_outlined, size: 18),
                SizedBox(width: 6),
                Text('2/3 scans used this month')
              ]),
              const SizedBox(height: 6),
              const LinearProgressIndicator(value: 0.66, minHeight: 6),
            ]),
          ),
          const SizedBox(height: 16),
          const Divider(height: 32),
          // API status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Integrations',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Google Vision API'),
                          _statusDot(Env.visionApiKey.isNotEmpty)
                        ]),
                    const SizedBox(height: 6),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Replicate API'),
                          _statusDot(Env.replicateToken.isNotEmpty)
                        ]),
                  ]),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 32),
          // Settings list
          ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              trailing: const Text('English')),
          ListTile(
              leading: const Icon(Icons.notifications_none),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  Navigator.of(context).pushNamed('/notification-settings')),
          ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Scan History'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).pushNamed('/history')),
          ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & FAQ'),
              onTap: () => Navigator.of(context).pushNamed('/faqs')),
          ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Diagnostics'),
              onTap: () => Navigator.of(context).pushNamed('/diagnostics')),
          ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Terms & Privacy'),
              onTap: () => Navigator.of(context).pushNamed('/terms')),
          ListTile(
              leading: const Icon(Icons.star_border),
              title: const Text('Rate App')),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await AppFirebase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/splash', (_) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}

String _initials(String? name) {
  if (name == null || name.trim().isEmpty) return 'CZ';
  final parts = name.trim().split(' ');
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

Widget _statusDot(bool ok) {
  return Row(children: [
    Icon(ok ? Icons.check_circle : Icons.error_outline,
        color: ok ? Colors.green : Colors.red, size: 18),
    const SizedBox(width: 6),
    Text(ok ? 'Configured' : 'Missing',
        style: TextStyle(color: ok ? Colors.green : Colors.red)),
  ]);
}
