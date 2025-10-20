import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _appleAvailable = false;

  @override
  void initState() {
    super.initState();
    SignInWithApple.isAvailable().then((v) { if (mounted) setState(() => _appleAvailable = v); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.auto_awesome, size: 72),
            const SizedBox(height: 16),
            Text('Welcome Back', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text("Let's get started by filling out the form below.", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: const Color(0xFFF2F4F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            _PasswordField(controller: _password),
            const SizedBox(height: 16),
            _shadow(
              dark: true,
              child: ElevatedButton(
                onPressed: _loading ? null : _signInEmail,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.of(context).pushNamed('/forgot-password'), child: const Text('Forgot Password?')),
            ),
            const SizedBox(height: 8),
            Row(children: const [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('OR')), Expanded(child: Divider())]),
            const SizedBox(height: 16),
            _shadow(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _signInGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 12),
            if (_appleAvailable)
              _shadow(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _signInApple,
                  icon: const Icon(Icons.apple),
                  label: const Text('Continue with Apple'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            const SizedBox(height: 12),
            _shadow(
              child: OutlinedButton.icon(
                onPressed: _loading ? null : () => Navigator.of(context).pushNamed('/phone'),
                icon: const Icon(Icons.phone_iphone),
                label: const Text('Continue with Phone'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Don't have an account? "),
              GestureDetector(onTap: () => Navigator.of(context).pushNamed('/create-account'), child: const Text('Sign Up here', style: TextStyle(fontWeight: FontWeight.bold))),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _signInEmail() async {
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: _email.text.trim(), password: _password.text);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        final cred = await FirebaseAuth.instance.signInWithPopup(provider);
        await UserService.ensureUserProfile(cred.user);
      } else {
        final client = GoogleSignIn();
        final account = await client.signIn();
        if (account == null) throw Exception('Sign-in canceled');
        final auth = await account.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        final cred = await FirebaseAuth.instance.signInWithCredential(credential);
        await UserService.ensureUserProfile(cred.user);
      }
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInApple() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], nonce: nonce);
      final oauth = OAuthProvider('apple.com').credential(idToken: credential.identityToken, rawNonce: rawNonce);
      final cred = await FirebaseAuth.instance.signInWithCredential(oauth);
      await UserService.ensureUserProfile(cred.user);
    } catch (e) {
      setState(() => _error = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}


class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller});
  final TextEditingController controller;
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        hintText: 'Password',
        filled: true,
        fillColor: const Color(0xFFF2F4F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
      ),
    );
  }
}

String _generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final rand = Random.secure();
  return List.generate(length, (_) => charset[rand.nextInt(charset.length)]).join();
}

String _sha256ofString(String input) => sha256.convert(utf8.encode(input)).toString();

Widget _shadow({required Widget child, bool dark = false}) => Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: (dark ? Colors.black : Colors.grey).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
      child: child,
    );


