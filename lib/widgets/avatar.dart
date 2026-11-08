import 'package:flutter/material.dart';

import '../utils.dart';

/// প্রোফাইল ছবি। ছবি না থাকলে নামের প্রথম অক্ষর দেখায়।
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.name,
    required this.photo,
    this.radius = 20,
  });

  final String name;
  final String photo;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bytes = decodeImage(photo);
    if (bytes != null) {
      return CircleAvatar(radius: radius, backgroundImage: MemoryImage(bytes));
    }
    final trimmed = name.trim();
    final initial =
        trimmed.isEmpty ? '?' : String.fromCharCode(trimmed.runes.first);
    return CircleAvatar(
      radius: radius,
      backgroundColor: cs.primaryContainer,
      child: Text(
        initial,
        style: TextStyle(fontSize: radius * 0.9, color: cs.onPrimaryContainer),
      ),
    );
  }
}

/// uid দিয়ে ব্যবহারকারীর তথ্য এনে builder-কে দেয়।
class UserBuilder extends StatelessWidget {
  const UserBuilder({super.key, required this.uid, required this.builder});

  final String uid;
  final Widget Function(BuildContext context, AppUser user) builder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser>(
      future: UserCache.get(uid),
      builder: (context, snap) {
        final user = snap.data ?? AppUser(uid: uid, name: '…');
        return builder(context, user);
      },
    );
  }
}
