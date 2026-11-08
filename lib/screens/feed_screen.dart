import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/avatar.dart';
import '../widgets/post_card.dart';
import 'create_post_screen.dart';

/// সবার পোস্টের ফিড
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'আড্ডা',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1877F2),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('পোস্ট লোড করা যায়নি।\n${snap.error}'),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: docs.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return const _Composer();
              return PostCard(doc: docs[i - 1]);
            },
          );
        },
      ),
    );
  }
}

/// ফিডের ওপরের "আপনি কী ভাবছেন?" বক্স
class _Composer extends StatelessWidget {
  const _Composer();

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            UserBuilder(
              uid: me,
              builder: (_, u) => Avatar(name: u.name, photo: u.photo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _open(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text('আপনি কী ভাবছেন?'),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.photo_library_outlined, color: Colors.green),
              onPressed: () => _open(context),
            ),
          ],
        ),
      ),
    );
  }
}
