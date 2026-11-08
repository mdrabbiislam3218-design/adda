import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';

/// মেসেঞ্জার: আমার সব কথোপকথনের তালিকা
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final String _me = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('chats')
        .where('members', arrayContains: _me)
        .snapshots();
  }

  int _millis(Timestamp? t) =>
      t?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('মেসেজ')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('মেসেজ লোড করা যায়নি।'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs
              .where((d) => ((d.data()['lastMessage'] as String?) ?? '').isNotEmpty)
              .toList()
            ..sort((a, b) => _millis(b.data()['lastTime'] as Timestamp?)
                .compareTo(_millis(a.data()['lastTime'] as Timestamp?)));
          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'এখনো কোনো মেসেজ নেই।\n"মানুষ" ট্যাব থেকে কাউকে খুঁজে মেসেজ পাঠান।',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final members = List<String>.from((data['members'] as List?) ?? const []);
              final other = members.firstWhere((m) => m != _me, orElse: () => _me);
              return UserBuilder(
                uid: other,
                builder: (context, user) => ListTile(
                  leading: Avatar(name: user.name, photo: user.photo, radius: 26),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    (data['lastMessage'] as String?) ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    timeAgo(data['lastTime'] as Timestamp?),
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(otherUid: other),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
