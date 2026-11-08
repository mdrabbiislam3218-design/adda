import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// একজন ব্যবহারকারীর তথ্য
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    this.bio = '',
    this.photo = '',
  });

  final String uid;
  final String name;
  final String bio;

  /// প্রোফাইল ছবি (base64), না থাকলে খালি
  final String photo;

  factory AppUser.fromMap(String uid, Map<String, dynamic>? data) {
    final d = data ?? <String, dynamic>{};
    final name = ((d['name'] as String?) ?? '').trim();
    return AppUser(
      uid: uid,
      name: name.isEmpty ? 'অজানা ব্যবহারকারী' : name,
      bio: (d['bio'] as String?) ?? '',
      photo: (d['photo'] as String?) ?? '',
    );
  }
}

/// বারবার একই ব্যবহারকারীর তথ্য লোড না করার জন্য ছোট ক্যাশ
class UserCache {
  static final Map<String, Future<AppUser>> _cache = {};

  static Future<AppUser> get(String uid) {
    final existing = _cache[uid];
    if (existing != null) return existing;
    final future = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get()
        .then((doc) => AppUser.fromMap(uid, doc.data()));
    _cache[uid] = future;
    future.catchError((Object _) {
      _cache.remove(uid);
      return AppUser.fromMap(uid, null);
    });
    return future;
  }

  static void invalidate(String uid) => _cache.remove(uid);
  static void clear() => _cache.clear();
}

/// base64 ছবি ডিকোড করে মনে রাখে, যাতে স্ক্রল করলে বারবার ডিকোড করতে না হয়
final Map<String, Uint8List> _imageCache = {};

Uint8List? decodeImage(String b64) {
  if (b64.isEmpty) return null;
  final cached = _imageCache[b64];
  if (cached != null) return cached;
  try {
    final bytes = base64Decode(b64);
    if (_imageCache.length > 60) _imageCache.clear();
    _imageCache[b64] = bytes;
    return bytes;
  } catch (_) {
    return null;
  }
}

/// গ্যালারি থেকে ছবি বেছে ছোট করে base64 বানায়।
/// ছবি বড় হলে FormatException ছোঁড়ে (Firestore-এর ডকুমেন্ট ১ MB এর বেশি হতে পারে না)।
Future<String?> pickImageBase64({
  required double maxWidth,
  required int quality,
  int maxChars = 700000,
}) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: maxWidth,
    imageQuality: quality,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final encoded = base64Encode(bytes);
  if (encoded.length > maxChars) {
    throw const FormatException('ছবিটি অনেক বড়। একটু ছোট ছবি বেছে নিন।');
  }
  return encoded;
}

/// সংখ্যা বাংলায়
String bn(Object value) {
  const digits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  return value.toString().split('').map((c) {
    final i = int.tryParse(c);
    return i == null ? c : digits[i];
  }).join();
}

String timeAgo(Timestamp? ts) {
  if (ts == null) return 'এইমাত্র';
  final date = ts.toDate();
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'এইমাত্র';
  if (diff.inMinutes < 60) return '${bn(diff.inMinutes)} মিনিট আগে';
  if (diff.inHours < 24) return '${bn(diff.inHours)} ঘণ্টা আগে';
  if (diff.inDays < 30) return '${bn(diff.inDays)} দিন আগে';
  return '${bn(date.day)}/${bn(date.month)}/${bn(date.year)}';
}

String clockTime(Timestamp? ts) {
  if (ts == null) return '';
  final d = ts.toDate();
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final suffix = d.hour < 12 ? 'AM' : 'PM';
  return '${bn(h)}:${bn(m)} $suffix';
}

String authErrorBn(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'এই ইমেইল দিয়ে আগেই অ্যাকাউন্ট খোলা হয়েছে।';
    case 'invalid-email':
      return 'ইমেইল ঠিকভাবে লিখুন।';
    case 'weak-password':
      return 'পাসওয়ার্ড অন্তত ৬ অক্ষরের দিন।';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'ইমেইল বা পাসওয়ার্ড ভুল।';
    case 'user-disabled':
      return 'এই অ্যাকাউন্টটি বন্ধ করা হয়েছে।';
    case 'too-many-requests':
      return 'অনেকবার চেষ্টা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন।';
    case 'network-request-failed':
      return 'ইন্টারনেট সংযোগ নেই।';
    case 'operation-not-allowed':
      return 'Firebase-এ Email/Password সাইন-ইন চালু করা হয়নি।';
    default:
      return 'কিছু একটা সমস্যা হয়েছে ($code)।';
  }
}

void showMsg(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
