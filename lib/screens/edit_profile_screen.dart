import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import '../widgets/avatar.dart';

/// নাম, পরিচিতি ও প্রোফাইল ছবি বদলানোর পেজ
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late String _photo;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _bio = TextEditingController(text: widget.user.bio);
    _photo = widget.user.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      // প্রোফাইল ছবি ছোট (৩০০ পিক্সেল) রাখা হয়, যাতে দ্রুত লোড হয়
      final img = await pickImageBase64(maxWidth: 300, quality: 60, maxChars: 200000);
      if (img != null && mounted) setState(() => _photo = img);
    } on FormatException catch (e) {
      if (mounted) showMsg(context, e.message);
    } catch (_) {
      if (mounted) showMsg(context, 'ছবি নেওয়া যায়নি।');
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      showMsg(context, 'নাম লিখুন।');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'name': name,
          'nameLower': name.toLowerCase(),
          'bio': _bio.text.trim(),
          'photo': _photo,
        },
        SetOptions(merge: true),
      );
      await user.updateDisplayName(name);
      UserCache.invalidate(user.uid);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showMsg(context, 'সেভ করা যায়নি। ইন্টারনেট চেক করে আবার চেষ্টা করুন।');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল এডিট'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('সেভ'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _busy ? null : _pickPhoto,
              child: Stack(
                children: [
                  Avatar(name: _name.text, photo: _photo, radius: 60),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primary,
                      child: Icon(Icons.camera_alt, size: 18, color: cs.onPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('ছবি বদলাতে ছবির ওপর চাপ দিন')),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'নাম',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bio,
            maxLength: 150,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'নিজের সম্পর্কে কিছু লিখুন',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
