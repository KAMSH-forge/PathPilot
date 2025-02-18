import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Homepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Page")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.go('/voice'); // Navigate to Voice-to-Text Page
              },
              child: Text("Go to Voice-to-Text"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/map'); // Navigate to Map Page
              },
              child: Text("Go to flutter Map Page"),
          ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/google-map'); // Navigate to Map Page
              },
              child: Text("Go to Osm Map Page"),
            ),
            SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}
