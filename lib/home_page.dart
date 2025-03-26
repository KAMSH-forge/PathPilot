import 'package:flutter/material.dart';
import 'googlemap.dart';
class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to the GoogleMapPage when the screen is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GoogleMapPage()),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black, // Black background
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Title Text
              const Text(
                'Welcome\n'
                'to\n'
                'PathPilot',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text
                ),
              ),
              const SizedBox(height: 20), // Add spacing
              // Subtext
              const Text(
                'Click anywhere to continue',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}