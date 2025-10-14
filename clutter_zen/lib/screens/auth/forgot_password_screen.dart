import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _email = TextEditingController();
  String? _msg;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Enter your email and we\'ll send a reset link.'),
          const SizedBox(height: 12),
          TextField(controller: _email, decoration: const InputDecoration(hintText: 'Email', filled: true, fillColor: Color(0xFFF2F4F7), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 16),
          if (_msg != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_msg!)),
          ElevatedButton(onPressed: _loading ? null : _send, child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send Reset Link')),
        ],
      ),
    );
  }

  Future<void> _send() async {
    setState(() { _loading = true; _msg = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email.text.trim());
      setState(() { _msg = 'Reset email sent.'; });
    } catch (e) {
      setState(() { _msg = 'Failed: $e'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }
}


