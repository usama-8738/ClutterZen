import 'package:flutter/material.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      {'q': 'How do I scan a room?', 'a': 'Go to Capture and choose camera or gallery.'},
      {'q': 'Is my data private?', 'a': 'Yes, see Terms > Privacy tab.'},
      {'q': 'Can I generate after images?', 'a': 'Yes, with Replicate in Results.'},
      {'q': 'How many scans are free?', 'a': 'Free plan includes 3 scans per month.'},
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(hintText: 'Search FAQs', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in faqs)
                  Card(
                    child: ExpansionTile(title: Text(f['q']!), children: [Padding(padding: const EdgeInsets.all(12), child: Text(f['a']!))]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


