import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../env.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fbInitialized = Firebase.apps.isNotEmpty;
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Firebase initialized', fbInitialized),
          _tile('Signed in', user != null, trailing: user?.uid ?? '—'),
          _tile('VISION_API_KEY set', Env.visionApiKey.isNotEmpty),
          _tile('REPLICATE_API_TOKEN set', Env.replicateToken.isNotEmpty),
          const SizedBox(height: 12),
          const Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('- Enable Developer Mode on Windows to allow plugin symlinks.'),
          const Text('- Run flutter clean && flutter pub get after moving directories.'),
        ],
      ),
    );
  }

  Widget _tile(String label, bool ok, {String? trailing}) {
    return ListTile(
      title: Text(label),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailing != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text(trailing, style: const TextStyle(color: Colors.grey))),
        Icon(ok ? Icons.check_circle : Icons.error_outline, color: ok ? Colors.green : Colors.red),
      ]),
    );
  }
}


