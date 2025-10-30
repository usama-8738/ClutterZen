import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ResponseTimeBanner(),
          SizedBox(height: 12),
          _ContactField(hint: 'Name', keyboardType: TextInputType.name),
          SizedBox(height: 8),
          _ContactField(
              hint: 'Email', keyboardType: TextInputType.emailAddress),
          SizedBox(height: 8),
          _ContactField(
            hint: 'Message',
            keyboardType: TextInputType.multiline,
            maxLines: 6,
          ),
          SizedBox(height: 12),
          _SubmitButton(),
        ],
      ),
    );
  }
}

class _ResponseTimeBanner extends StatelessWidget {
  const _ResponseTimeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.email_outlined),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'We usually reply within 1-2 business days',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Color(0xFFF2F4F7),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ).copyWith(hintText: hint),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for reaching out!')),
        );
      },
      child: const Text('Send Message'),
    );
  }
}
