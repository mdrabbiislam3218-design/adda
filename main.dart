import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// এই ফাইলটি `flutterfire configure` কমান্ড চালালে নিজে নিজে তৈরি হবে।
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AddaApp());
}

class AddaApp extends StatelessWidget {
  const AddaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'আড্ডা',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1877F2)),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      // লগইন করা থাকলে হোম, না থাকলে লগইন পেজ
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasData) return const HomeScreen();
          return const AuthScreen();
        },
      ),
    );
  }
}
