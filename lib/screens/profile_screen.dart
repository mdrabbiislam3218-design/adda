import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import '../widgets/avatar.dart';
import '../widgets/post_card.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';

/// প্রোফাইল পেজ: নিজের হলে এডিট ও লগ আউট, অন্যের হলে মেসেজ বাটন
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.uid, this.isTab = false});

  final String uid;

  /// নিচের ট্যাব হিসেবে দেখানো হলে true (তখন ব্যাক বাটন ও লগ আউট ভিন্নভাবে কাজ করে)
  final bool isTab;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userStream;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _postStream;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    _userStream = db.collection('users').doc(widget.uid).snapshots();
    _postStream =
        db.collection('posts').where('uid', isEqualTo: widget.uid).snapshots();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগ আউট করবেন?'),
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
    UserCache.clear();
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final isMe = widget.uid == me?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('প্রোফাইল'),
        automaticallyImplyLeading: !widget.isTab,
        actions: [
          if (isMe && widget.isTab)
            IconButton(
              tooltip: 'লগ আউট',
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userStream,
        builder: (context, userSnap) {
          if (userSnap.hasError) {
            return const Center(child: Text('প্রোফাইল লোড করা যায়নি।'));
          }
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = userSnap.data!.data();
          var user = AppUser.fromMap(widget.uid, data);
          if (data == null && isMe) {
            user = AppUser(uid: widget.uid, name: me?.displayName ?? 'আমি');
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _postStream,
            builder: (context, postSnap) {
              final docs = (postSnap.data?.docs ?? [])
                  .toList()
                ..sort((a, b) {
                  final ta = (a.data()['createdAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                      DateTime.now().millisecondsSinceEpoch;
                  final tb = (b.data()['createdAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                      DateTime.now().millisecondsSinceEpoch;
                  return tb.compareTo(ta);
                });

              return ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Avatar(name: user.name, photo: user.photo, radius: 56),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user.bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                      child: Text(user.bio, textAlign: TextAlign.center),
                    ),
                  if (isMe && me?.email != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        me!.email!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 14),
                  Center(
                    child: isMe
                        ? FilledButton.tonalIcon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => EditProfileScreen(user: user),
                              ),
                            ),
                            icon: const Icon(Icons.edit),
                            label: const Text('প্রোফাইল এডিট করুন'),
                          )
                        : FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(otherUid: widget.uid),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('মেসেজ পাঠান'),
                          ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Divider(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      'পোস্টসমূহ (${bn(docs.length)})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('এখনো কোনো পোস্ট নেই।')),
                    )
                  else
                    ...docs.map((d) => PostCard(doc: d)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
