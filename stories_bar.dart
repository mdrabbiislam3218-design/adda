import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import 'avatar.dart';

const _blue = Color(0xFF1877F2);

/// ফেসবুকের মতো স্টোরি লাইন: প্রথমে "স্টোরি তৈরি", তারপর সবার ২৪ ঘণ্টার স্টোরি
class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  final String _me = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('stories')
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots();
  }

  Future<void> _create() async {
    try {
      final img = await pickImageBase64(maxWidth: 720, quality: 70);
      if (img == null) return;
      await FirebaseFirestore.instance.collection('stories').add({
        'uid': _me,
        'image': img,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) showMsg(context, 'স্টোরি দেওয়া হয়েছে।');
    } on FormatException catch (e) {
      if (mounted) showMsg(context, e.message);
    } catch (e) {
      if (mounted) showMsg(context, 'স্টোরি দেওয়া যায়নি: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 214,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          final seen = <String>{};
          final stories = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          for (final d in snap.data?.docs ?? const []) {
            final ts = d.data()['createdAt'] as Timestamp?;
            final fresh = ts == null ||
                DateTime.now().difference(ts.toDate()).inHours < 24;
            // প্রতিজন থেকে শুধু সর্বশেষ স্টোরি
            if (fresh && seen.add((d.data()['uid'] as String?) ?? '')) {
              stories.add(d);
            }
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            itemCount: stories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == 0) return _createCard();
              final d = stories[i - 1];
              final uid = (d.data()['uid'] as String?) ?? '';
              return UserBuilder(
                uid: uid,
                builder: (_, u) => _storyCard(d, u),
              );
            },
          );
        },
      ),
    );
  }

  Widget _createCard() {
    return GestureDetector(
      onTap: _create,
      child: Container(
        width: 108,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E6EB)),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: UserBuilder(
                        uid: _me,
                        builder: (_, u) {
                          final b = decodeImage(u.photo);
                          return b != null
                              ? Image.memory(b, fit: BoxFit.cover)
                              : Container(color: const Color(0xFFE4E6EB));
                        },
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: -18,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: _blue,
                        child: Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 22, bottom: 10),
              child: Text('স্টোরি তৈরি',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _storyCard(QueryDocumentSnapshot<Map<String, dynamic>> d, AppUser u) {
    final bytes = decodeImage((d.data()['image'] as String?) ?? '');
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => StoryViewer(doc: d, user: u)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 108,
          child: Stack(
            fit: StackFit.expand,
            children: [
              bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true)
                  : Container(color: Colors.grey.shade400),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black26, Colors.transparent, Colors.black54],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: _blue),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white),
                    child: Avatar(name: u.name, photo: u.photo, radius: 15),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  u.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// স্টোরি পুরো পর্দায় দেখা (ট্যাপ করলে বন্ধ)
class StoryViewer extends StatelessWidget {
  const StoryViewer({super.key, required this.doc, required this.user});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final bytes = decodeImage((data['image'] as String?) ?? '');
    final mine = data['uid'] == FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bytes != null) Image.memory(bytes, fit: BoxFit.contain),
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: ListTile(
                  leading: Avatar(name: user.name, photo: user.photo),
                  title: Text(user.name,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(timeAgo(data['createdAt'] as Timestamp?),
                      style: const TextStyle(color: Colors.white70)),
                  trailing: mine
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.white),
                          onPressed: () async {
                            await doc.reference.delete();
                            if (context.mounted) Navigator.pop(context);
                          },
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
