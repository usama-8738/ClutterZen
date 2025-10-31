import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuthException, PhoneAuthCredential, PhoneAuthProvider, UserCredential;
import 'package:flutter/material.dart';
import '../../app_firebase.dart';
import '../../services/user_service.dart';

class PhoneOtpScreen extends StatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _code = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _sending = false;
  bool _verifying = false;
  String? _msg;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with Phone')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_msg != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_msg!, style: const TextStyle(color: Colors.red))),
          TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  hintText: '+1 555 123 4567',
                  labelText: 'Phone Number',
                  filled: true,
                  fillColor: Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: ElevatedButton(
                    onPressed: _sending ? null : _sendCode,
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Send Code'))),
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: (_resendToken == null || _sending) ? null : _resend,
                child: const Text('Resend')),
          ]),
          const SizedBox(height: 16),
          TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: '123456',
                  labelText: 'Verification Code',
                  filled: true,
                  fillColor: Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(12))))),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify & Sign In')),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    setState(() {
      _sending = true;
      _msg = null;
    });
    try {
      await AppFirebase.auth.verifyPhoneNumber(
        phoneNumber: _phone.text.trim(),
        verificationCompleted: (cred) async {
          try {
            await _signInWithCredential(cred);
            if (mounted) {
              setState(() => _msg = 'Signed in automatically.');
            }
          } catch (e) {
            if (mounted) setState(() => _msg = 'Failed: $e');
          }
        },
        verificationFailed: (e) => setState(() => _msg = e.message),
        codeSent: (verificationId, resendToken) => setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _msg = 'Code sent.';
        }),
        codeAutoRetrievalTimeout: (verificationId) =>
            setState(() => _verificationId = verificationId),
      );
    } catch (e) {
      setState(() => _msg = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verify() async {
    if (_verificationId == null) {
      setState(() => _msg = 'Request a code first.');
      return;
    }
    setState(() {
      _verifying = true;
      _msg = null;
    });
    try {
      final cred = PhoneAuthProvider.credential(
          verificationId: _verificationId!, smsCode: _code.text.trim());
      await _signInWithCredential(cred);
      if (mounted) {
        setState(() => _msg = 'Signed in successfully.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _msg = e.message ?? 'Failed: ${e.code}');
    } catch (e) {
      setState(() => _msg = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendToken == null) return;
    setState(() {
      _sending = true;
      _msg = null;
    });
    try {
      await AppFirebase.auth.verifyPhoneNumber(
        phoneNumber: _phone.text.trim(),
        forceResendingToken: _resendToken,
        verificationCompleted: (cred) async {
          try {
            await _signInWithCredential(cred);
            if (mounted) {
              setState(() => _msg = 'Signed in automatically.');
            }
          } catch (e) {
            if (mounted) setState(() => _msg = 'Failed: $e');
          }
        },
        verificationFailed: (e) => setState(() => _msg = e.message),
        codeSent: (verificationId, resendToken) => setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _msg = 'Code re-sent.';
        }),
        codeAutoRetrievalTimeout: (verificationId) =>
            setState(() => _verificationId = verificationId),
      );
    } catch (e) {
      setState(() => _msg = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final UserCredential userCredential =
          await AppFirebase.auth.signInWithCredential(credential);
      await UserService.ensureUserProfile(userCredential.user);
    } on FirebaseAuthException {
      rethrow;
    }
  }
}
