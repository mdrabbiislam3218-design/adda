import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import '../widgets/avatar.dart';

/// একটি পোস্টের মন্তব্যসমূহ
class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final _text = TextEditingController();
  final String _me = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final DocumentReference<Map<String, dynamic>> _postRef;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    _stream = _postRef
        .collection('comments')
        .orderBy('createdAt')
        .limit(200)
        .snapshots();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _me.isEmpty) return;
    _text.clear();
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_postRef.collection('comments').doc(), {
      'uid': _me,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_postRef, {'commentCount': FieldValue.increment(1)});
    try {
      await batch.commit();
    } catch (_) {
      if (mounted) showMsg(context, 'মন্তব্য পাঠানো যায়নি।');
    }
  }

  Future<void> _deleteComment(DocumentReference<Map<String, dynamic>> ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('মন্তব্য মুছবেন?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(ref);
    batch.update(_postRef, {'commentCount': FieldValue.increment(-1)});
    try {
      await batch.commit();
    } catch (_) {
      if (mounted) showMsg(context, 'মুছে ফেলা যায়নি।');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('মন্তব্য')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('মন্তব্য লোড করা যায়নি।'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('এখনো কোনো মন্তব্য নেই। প্রথম মন্তব্যটি আপনিই করুন!'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = d.data();
                    final uid = (data['uid'] as String?) ?? '';
                    final text = (data['text'] as String?) ?? '';
                    final time = data['createdAt'] as Timestamp?;
                    return GestureDetector(
                      onLongPress: uid == _me ? () => _deleteComment(d.reference) : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: UserBuilder(
                          uid: uid,
                          builder: (context, user) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Avatar(name: user.name, photo: user.photo, radius: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(text),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 12, top: 2),
                                      child: Text(
                                        timeAgo(time),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'মন্তব্য লিখুন…',
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _send,
                    icon: Icon(Icons.send, color: cs.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
