import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(title: const Text('Push notifications'), value: true, onChanged: (_) {}),
          SwitchListTile(title: const Text('Email updates'), value: false, onChanged: (_) {}),
        ],
      ),
    );
  }
}


