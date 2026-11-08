import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import '../widgets/avatar.dart';

/// দুজনের মধ্যে সরাসরি মেসেজের পেজ
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.otherUid});

  final String otherUid;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();
  late final String _me;
  late final String _chatId;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  @override
  void initState() {
    super.initState();
    _me = FirebaseAuth.instance.currentUser?.uid ?? '';
    // দুজনের uid সাজিয়ে জুড়ে দিলে একই দুজনের জন্য সবসময় একই chatId হয়
    final ids = [_me, widget.otherUid]..sort();
    _chatId = ids.join('_');
    _stream = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
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

    final db = FirebaseFirestore.instance;
    final chatRef = db.collection('chats').doc(_chatId);
    final batch = db.batch();
    batch.set(
      chatRef,
      {
        'members': [_me, widget.otherUid],
        'lastMessage': text,
        'lastTime': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(chatRef.collection('messages').doc(), {
      'from': _me,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    try {
      await batch.commit();
    } catch (_) {
      if (mounted) showMsg(context, 'মেসেজ পাঠানো যায়নি।');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: UserBuilder(
          uid: widget.otherUid,
          builder: (context, user) => Row(
            children: [
              Avatar(name: user.name, photo: user.photo, radius: 17),
              const SizedBox(width: 10),
              Expanded(
                child: Text(user.name, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('মেসেজ লোড করা যায়নি।'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('একটা "হাই" বলে শুরু করুন!'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final mine = m['from'] == _me;
                    final text = (m['text'] as String?) ?? '';
                    final time = clockTime(m['createdAt'] as Timestamp?);
                    final fg = mine ? cs.onPrimary : cs.onSurface;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: mine ? cs.primary : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(text, style: TextStyle(color: fg, fontSize: 16)),
                            if (time.isNotEmpty)
                              Text(time, style: TextStyle(color: fg, fontSize: 10)),
                          ],
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
                        hintText: 'মেসেজ লিখুন…',
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
