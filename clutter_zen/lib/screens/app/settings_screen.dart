import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(leading: Icon(Icons.person_outline), title: Text('Profile')),
          ListTile(leading: Icon(Icons.lock_outline), title: Text('Privacy')),
        ],
      ),
    );
  }
}


