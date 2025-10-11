import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Message'), maxLines: 5),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('Send')),
          ],
        ),
      ),
    );
  }
}


