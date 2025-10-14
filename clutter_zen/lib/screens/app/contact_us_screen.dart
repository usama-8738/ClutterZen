import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [const Icon(Icons.email_outlined), const SizedBox(width: 8), Expanded(child: Text('We usually reply within 1–2 business days', style: Theme.of(context).textTheme.bodyMedium))]),
          ),
          const SizedBox(height: 12),
          TextField(decoration: const InputDecoration(hintText: 'Name', filled: true, fillColor: Color(0xFFF2F4F7), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(hintText: 'Email', filled: true, fillColor: Color(0xFFF2F4F7), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(hintText: 'Message', filled: true, fillColor: Color(0xFFF2F4F7), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12)))), maxLines: 6),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () {}, child: const Text('Send Message')),
        ],
      ),
    );
  }
}


