import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/comments_screen.dart';
import '../screens/profile_screen.dart';
import '../utils.dart';
import 'avatar.dart';

/// একটি পোস্ট: লেখক, লেখা, ছবি, লাইক ও মন্তব্য
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.doc});

  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  void _toggleLike(bool liked, String me) {
    if (me.isEmpty) return;
    doc.reference.update({
      'likes': liked
          ? FieldValue.arrayRemove([me])
          : FieldValue.arrayUnion([me]),
    }).catchError((_) {});
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('পোস্ট মুছবেন?'),
        content: const Text('মুছে ফেললে আর ফিরে পাওয়া যাবে না।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('হ্যাঁ, মুছুন'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = doc.data();
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    final authorUid = (data['uid'] as String?) ?? '';
    final text = (data['text'] as String?) ?? '';
    final image = decodeImage((data['image'] as String?) ?? '');
    final likes = List<String>.from((data['likes'] as List?) ?? const []);
    final commentCount = (data['commentCount'] as num?)?.toInt() ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    final liked = likes.contains(me);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserBuilder(
            uid: authorUid,
            builder: (context, user) => ListTile(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(uid: authorUid),
                ),
              ),
              leading: Avatar(name: user.name, photo: user.photo),
              title: Text(
                user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(timeAgo(createdAt)),
              trailing: authorUid == me
                  ? PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'delete') _confirmDelete(context);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('পোস্ট মুছুন'),
                        ),
                      ],
                    )
                  : null,
            ),
          ),
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(text, style: const TextStyle(fontSize: 16)),
            ),
          if (image != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: Image.memory(
                image,
                width: double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          if (likes.isNotEmpty || commentCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  if (likes.isNotEmpty) ...[
                    Icon(Icons.thumb_up, size: 16, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(bn(likes.length)),
                  ],
                  const Spacer(),
                  if (commentCount > 0) Text('${bn(commentCount)} টি মন্তব্য'),
                ],
              ),
            ),
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _toggleLike(liked, me),
                  icon: Icon(
                    liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: liked ? cs.primary : null,
                  ),
                  label: Text(
                    'লাইক',
                    style: TextStyle(color: liked ? cs.primary : null),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CommentsScreen(postId: doc.id),
                    ),
                  ),
                  icon: const Icon(Icons.mode_comment_outlined),
                  label: const Text('মন্তব্য'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
