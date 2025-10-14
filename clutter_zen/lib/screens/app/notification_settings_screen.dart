import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.notifications_active_outlined), const SizedBox(width: 8), Expanded(child: Text('Stay updated with decluttering tips and scan results', style: Theme.of(context).textTheme.bodyMedium))]),
          ),
          const SizedBox(height: 12),
          Card(child: SwitchListTile(title: const Text('Push Notifications'), subtitle: const Text('Receive updates on your device'), value: true, onChanged: (_) {})),
          const SizedBox(height: 8),
          Card(child: SwitchListTile(title: const Text('Email Updates'), subtitle: const Text('Get summaries via email'), value: false, onChanged: (_) {})),
          const SizedBox(height: 8),
          Card(child: SwitchListTile(title: const Text('Tips & Tricks'), subtitle: const Text('Weekly organization tips'), value: true, onChanged: (_) {})),
        ],
      ),
    );
  }
}


