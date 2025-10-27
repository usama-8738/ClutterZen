import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  const AuthService(this._auth);

  final FirebaseAuth _auth;
  static Future<void>? _googleInitFuture;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(
      String email, String password) async {
    return _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      return _auth.signInWithPopup(provider);
    }

    await _ensureGoogleInitialized();
    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: const ['email']);
      final GoogleSignInAuthentication tokens = account.authentication;
      final String? idToken = tokens.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'Missing ID token from Google sign-in.',
        );
      }
      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );
      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      final code = e.code;
      if (code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'canceled',
          message: 'Sign-in aborted by user.',
        );
      }
      throw FirebaseAuthException(
        code: code.name,
        message: e.description ?? 'Google sign-in failed: ${code.name}',
      );
    }
  }

  Future<UserCredential> signInWithApple() async {
    if (kIsWeb) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-web',
        message: 'Sign in with Apple is not supported on the web.',
      );
    }

    final available = await SignInWithApple.isAvailable();
    if (!available) {
      throw FirebaseAuthException(
        code: 'apple-sign-in-unavailable',
        message: 'Sign in with Apple is not available on this device.',
      );
    }

    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName
      ],
      nonce: nonce,
    );

    if (credential.identityToken == null) {
      throw FirebaseAuthException(
        code: 'missing-identity-token',
        message: 'Apple did not return an identity token.',
      );
    }

    final oauth = OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      rawNonce: rawNonce,
    );
    return _auth.signInWithCredential(oauth);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleInitFuture != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Ignore Google sign-out errors; Firebase sign-out already completed.
      }
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    return List.generate(length, (_) => charset[rand.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= GoogleSignIn.instance.initialize();
  }
}
