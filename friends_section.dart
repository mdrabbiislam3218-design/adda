import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils.dart';
import 'avatar.dart';

const _blue = Color(0xFF1877F2);

/// "বন্ধুর অনুরোধ" ও "আপনি যাদের চিনতে পারেন" — Add friend / Remove সহ
class FriendsSection extends StatefulWidget {
  const FriendsSection({super.key});

  @override
  State<FriendsSection> createState() => _FriendsSectionState();
}

class _FriendsSectionState extends State<FriendsSection> {
  final _me = FirebaseAuth.instance.currentUser?.uid ?? '';
  final _db = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _incoming;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _outgoing;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _users;
  final Set<String> _hidden = {};

  @override
  void initState() {
    super.initState();
    final reqs = _db.collection('friendRequests');
    _incoming = reqs.where('to', isEqualTo: _me).snapshots();
    _outgoing = reqs.where('from', isEqualTo: _me).snapshots();
    _users = _db.collection('users').limit(30).snapshots();
  }

  Future<void> _run(Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      if (mounted) showMsg(context, 'সমস্যা হয়েছে: $e');
    }
  }

  void _add(String uid) => _run(() => _db
      .collection('friendRequests')
      .doc('${_me}_$uid')
      .set({
        'from': _me,
        'to': uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _incoming,
      builder: (context, inc) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _outgoing,
        builder: (context, out) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _users,
          builder: (context, usr) {
            if (!inc.hasData || !out.hasData || !usr.hasData) {
              return const SizedBox.shrink();
            }
            final incoming = inc.data!.docs
                .where((d) => d.data()['status'] == 'pending')
                .toList();
            final skip = <String>{_me};
            for (final d in inc.data!.docs) {
              skip.add((d.data()['from'] as String?) ?? '');
            }
            final sent = <String, DocumentReference<Map<String, dynamic>>>{};
            for (final d in out.data!.docs) {
              final to = (d.data()['to'] as String?) ?? '';
              if (d.data()['status'] == 'accepted') {
                skip.add(to);
              } else {
                sent[to] = d.reference;
              }
            }
            final people = usr.data!.docs
                .where((d) => !skip.contains(d.id) && !_hidden.contains(d.id))
                .toList();

            return Column(
              children: [
                if (incoming.isNotEmpty)
                  _section(
                    Icons.person_add_alt_1_outlined,
                    'বন্ধুর অনুরোধ',
                    [
                      for (final d in incoming)
                        UserBuilder(
                          uid: d.data()['from'] as String,
                          builder: (_, u) => _PersonCard(
                            user: u,
                            primary: 'নিশ্চিত করুন',
                            onPrimary: () =>
                                _run(() => d.reference.update({'status': 'accepted'})),
                            secondary: 'মুছুন',
                            onSecondary: () => _run(d.reference.delete),
                          ),
                        ),
                    ],
                  ),
                if (people.isNotEmpty)
                  _section(
                    Icons.people_outline,
                    'আপনি যাদের চিনতে পারেন',
                    [
                      for (final d in people)
                        _PersonCard(
                          user: AppUser.fromMap(d.id, d.data()),
                          primary: sent.containsKey(d.id)
                              ? 'অনুরোধ বাতিল'
                              : 'বন্ধু হোন',
                          primaryFilled: !sent.containsKey(d.id),
                          onPrimary: () => sent.containsKey(d.id)
                              ? _run(sent[d.id]!.delete)
                              : _add(d.id),
                          secondary: 'সরান',
                          onSecondary: () => setState(() => _hidden.add(d.id)),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _section(IconData icon, String title, List<Widget> cards) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 262,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => cards[i],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.user,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    this.primaryFilled = true,
  });

  final AppUser user;
  final String primary;
  final String secondary;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final bool primaryFilled;

  @override
  Widget build(BuildContext context) {
    final bytes = decodeImage(user.photo);
    final initial = user.name.trim().isEmpty
        ? '?'
        : String.fromCharCode(user.name.trim().runes.first);
    return Container(
      width: 164,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E6EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 130,
            width: double.infinity,
            child: bytes != null
                ? Image.memory(bytes, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFFD8E6FD),
                    alignment: Alignment.center,
                    child: Text(initial,
                        style: const TextStyle(
                            fontSize: 48,
                            color: _blue,
                            fontWeight: FontWeight.bold)),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Text(user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor:
                          primaryFilled ? _blue : const Color(0xFFE4E6EB),
                      foregroundColor: primaryFilled ? Colors.white : Colors.black,
                    ),
                    onPressed: onPrimary,
                    child: Text(primary, style: const TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFFE4E6EB),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: onSecondary,
                    child: Text(secondary, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
