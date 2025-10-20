import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/user_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          TextField(controller: _name, decoration: const InputDecoration(hintText: 'Full Name', filled: true, fillColor: Color(0xFFF2F4F7), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 12),
          TextField(controller: _email, decoration: const InputDecoration(hintText: 'Email', filled: true, fillColor: Color(0xFFF2F4F7), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 12),
          TextField(controller: _password, obscureText: true, decoration: const InputDecoration(hintText: 'Password', filled: true, fillColor: Color(0xFFF2F4F7), border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _create,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create Account'),
          ),
          const SizedBox(height: 16),
          Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR')), Expanded(child: Divider())]),
          const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: _loading ? null : _google, icon: const Icon(Icons.g_mobiledata), label: const Text('Sign up with Google')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _loading ? null : _apple, icon: const Icon(Icons.apple), label: const Text('Sign up with Apple')),
        ],
      ),
    );
  }

  Future<void> _create() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
      await cred.user?.updateDisplayName(_name.text.trim());
      // Create user profile doc
      if (cred.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'displayName': _name.text.trim(),
          'email': _email.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'scanCredits': 3,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      await UserService.ensureUserProfile(cred.user);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apple() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Apple sign-up is the same as sign-in flow; Apple returns identity token with email/fullName on first consent
      // In a production app, handle scopes and missing data appropriately.
      // Here we reuse the popup flow via OAuth provider on supported platforms.
      final oauth = OAuthProvider('apple.com');
      final cred = await FirebaseAuth.instance.signInWithPopup(oauth);
      await UserService.ensureUserProfile(cred.user);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}


