import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Ensures Flutter is ready before Firebase initializes
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connects your app to your Firebase project using the
  // generated firebase_options.dart file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DookiFinder',
      home: Scaffold(
        appBar: AppBar(title: const Text('DookiFinder')),
        body: const Center(child: Text('Welcome to DookiFinder')),
      ),
    );
  }
}