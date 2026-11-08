import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'chats_screen.dart';
import 'feed_screen.dart';
import 'people_screen.dart';
import 'profile_screen.dart';

/// লগইনের পর মূল পেজ: নিচে চারটি ট্যাব
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const FeedScreen(),
          const PeopleScreen(),
          const ChatsScreen(),
          ProfileScreen(uid: me, isTab: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'হোম',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'মানুষ',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'মেসেজ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'আমি',
          ),
        ],
      ),
    );
  }
}
