import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';

/// নতুন পোস্ট লেখার পেজ (লেখা + ঐচ্ছিক ছবি)
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _text = TextEditingController();
  String? _image;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final img = await pickImageBase64(maxWidth: 800, quality: 55);
      if (img != null && mounted) setState(() => _image = img);
    } on FormatException catch (e) {
      if (mounted) showMsg(context, e.message);
    } catch (_) {
      if (mounted) showMsg(context, 'ছবি নেওয়া যায়নি।');
    }
  }

  Future<void> _post() async {
    final text = _text.text.trim();
    if (text.isEmpty && _image == null) {
      showMsg(context, 'কিছু লিখুন বা একটি ছবি দিন।');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _busy = true);
    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid,
        'text': text,
        'image': _image ?? '',
        'likes': <String>[],
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showMsg(context, 'পোস্ট করা যায়নি। ইন্টারনেট চেক করে আবার চেষ্টা করুন।');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = decodeImage(_image ?? '');
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন পোস্ট'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton(
              onPressed: _busy ? null : _post,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('পোস্ট'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 5,
            maxLines: null,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'আপনি কী ভাবছেন?',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 18),
          ),
          if (image != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _image = null),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pick,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(image == null ? 'ছবি যোগ করুন' : 'ছবি বদলান'),
          ),
        ],
      ),
    );
  }
}
