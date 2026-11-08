import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';

/// লগইন ও নতুন অ্যাকাউন্ট খোলার পেজ
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLogin = true;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);

    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    final email = _email.text.trim();

    try {
      if (_isLogin) {
        final cred = await auth.signInWithEmailAndPassword(
          email: email,
          password: _password.text,
        );
        // কোনো কারণে প্রোফাইল তৈরি না হয়ে থাকলে এখন বানিয়ে নেওয়া হবে
        final user = cred.user;
        if (user != null) {
          final ref = db.collection('users').doc(user.uid);
          final snap = await ref.get();
          if (!snap.exists) {
            final name = user.displayName ?? email.split('@').first;
            await ref.set({
              'name': name,
              'nameLower': name.toLowerCase(),
              'email': email,
              'bio': '',
              'photo': '',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } else {
        final name = _name.text.trim();
        final cred = await auth.createUserWithEmailAndPassword(
          email: email,
          password: _password.text,
        );
        final user = cred.user!;
        await db.collection('users').doc(user.uid).set({
          'name': name,
          'nameLower': name.toLowerCase(),
          'email': email,
          'bio': '',
          'photo': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        await user.updateDisplayName(name);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showMsg(context, authErrorBn(e.code));
    } catch (_) {
      if (mounted) {
        showMsg(context, 'কিছু একটা সমস্যা হয়েছে। ইন্টারনেট চেক করে আবার চেষ্টা করুন।');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      showMsg(context, 'আগে ইমেইল লিখুন, তারপর এখানে চাপুন।');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        showMsg(context, 'পাসওয়ার্ড রিসেটের লিংক ইমেইলে পাঠানো হয়েছে।');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showMsg(context, authErrorBn(e.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'আড্ডা',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1877F2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'বন্ধুদের সাথে কথা বলুন, ছবি ও কথা শেয়ার করুন',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'আপনার নাম',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'নাম লিখুন'
                            : null,
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'ইমেইল',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'সঠিক ইমেইল লিখুন'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        labelText: 'পাসওয়ার্ড',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'পাসওয়ার্ড অন্তত ৬ অক্ষরের হতে হবে'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isLogin ? 'লগইন' : 'অ্যাকাউন্ট খুলুন'),
                    ),
                    if (_isLogin)
                      TextButton(
                        onPressed: _busy ? null : _resetPassword,
                        child: const Text('পাসওয়ার্ড ভুলে গেছেন?'),
                      ),
                    const Divider(height: 28),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? 'নতুন? অ্যাকাউন্ট খুলুন'
                            : 'আগে থেকেই অ্যাকাউন্ট আছে? লগইন করুন',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
