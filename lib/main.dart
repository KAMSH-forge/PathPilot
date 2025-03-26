import 'package:flutter/material.dart';
import 'home_page.dart';
import 'googlemap.dart';

void main() async {
  // await dotenv.load(); // Uncomment if you're using environment variables
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TabNavigation(), // Use TabNavigation as the home widget
    );
  }
}

class TabNavigation extends StatefulWidget {
  const TabNavigation({super.key});

  @override
  _TabNavigationState createState() => _TabNavigationState();
}

class _TabNavigationState extends State<TabNavigation> {
  int _currentIndex = 0; // Tracks the currently selected tab

  // List of pages for each tab
  final List<Widget> _pages = [
    const Homepage(),
    const GoogleMapPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // Current tab index
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the current tab index
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: "Map",
          ),
        ],
      ),
    );
  }
}