import 'package:flutter/material.dart';
import 'googlemap.dart'; // Your Google Map screen
import 'camera_screen_gemini.dart'; // Your Camera screen
import 'package:flutter/material.dart';
import 'camera_screen_yolo.dart';
// import 'camera_screen.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and App Name
              Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        AssetImage('assets/logo.png'), // Replace with your logo
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'PathPilot',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Move about with confidence\nusing an AI-powered navigation system',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              // Feature Tiles
              const SizedBox(height: 20),
              FeatureTile(
                icon: Icons.mic,
                title: "Voice Control",
                subtitle: "Voice-assisted controls",
                onTap: () {
                  // Navigate to Voice Control feature
                  Navigator.pushNamed(context, '/voiceControl');
                },
              ),
              const SizedBox(height: 10),
              FeatureTile(
                icon: Icons.camera_alt,
                title: "Camera",
                subtitle: "Gemini Vision",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CameraScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              FeatureTile(
                icon: Icons.camera_alt,
                title: "Camera",
                subtitle: "Yolo",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  const CameraScreenYolo()),
                  );
                },
              ),
              const SizedBox(height: 10),
              FeatureTile(
                icon: Icons.map,
                title: "Map",
                subtitle: "Real time Navigation",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const GoogleMapPage()),
                  );
                },
              ),
              // Get Started Button
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  // Navigate to the main app screen
                  Navigator.pushNamed(context, '/mainApp');
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  foregroundColor: Colors.white, // Text color set to white
                ),
                child: const Text("Get Started →"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Widget for Feature Tiles
class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade900,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
