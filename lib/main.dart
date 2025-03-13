import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home_page.dart';
import 'googlemap.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
void main() async {
  // await dotenv.load();
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  // Define the router
  final GoRouter _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Homepage(),
      ),
      GoRoute(
      path: '/google-map',
      builder: (context, state) => GoogleMapPage(),
    ),
    ],
  );
  MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router, // Use GoRouter for navigation
    );
  }
}
