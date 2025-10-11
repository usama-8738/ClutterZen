import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(10, (i) => 'Analysis #${i + 1}');
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.history),
          title: Text(items[i]),
          subtitle: const Text('Clutter score: 6.5'),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}


