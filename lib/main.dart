import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'googlemap.dart';
import 'camera_screen_gemini.dart';


void main() async {
//  await dotenv.load(fileName: '.env'); // Uncomment if you're using environment variables
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomePage(), // Use TabNavigation as the home widget
    );
  }
}

