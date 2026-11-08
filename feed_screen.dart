import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/avatar.dart';
import '../widgets/post_card.dart';
import '../widgets/friends_section.dart';
import '../widgets/stories_bar.dart';
import 'create_post_screen.dart';
import 'people_screen.dart';

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
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'আড্ডা',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1877F2),
          ),
        ),
        actions: [
          _roundIcon(Icons.add, () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreatePostScreen()))),
          _roundIcon(Icons.search, () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PeopleScreen()))),
          const SizedBox(width: 8),
        ],
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
            padding: EdgeInsets.zero,
            itemCount: docs.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) {
                return const Column(
                  children: [
                    _Composer(),
                    SizedBox(height: 8),
                    StoriesBar(),
                    SizedBox(height: 8),
                    FriendsSection(),
                  ],
                );
              }
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
    return Container(
      color: Colors.white,
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

Widget _roundIcon(IconData icon, VoidCallback onTap) {
  return Padding(
    padding: const EdgeInsets.only(left: 8),
    child: InkResponse(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFFE4E6EB)),
        child: Icon(icon, color: Colors.black87),
      ),
    ),
  );
}
