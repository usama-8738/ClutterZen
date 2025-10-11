import 'package:flutter/material.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      {'q': 'How do I scan a room?', 'a': 'Go to Upload and choose camera or gallery.'},
      {'q': 'Is my data private?', 'a': 'Yes, see our privacy policy.'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final f in faqs)
            ExpansionTile(title: Text(f['q']!), children: [Padding(padding: const EdgeInsets.all(12), child: Text(f['a']!))]),
        ],
      ),
    );
  }
}


