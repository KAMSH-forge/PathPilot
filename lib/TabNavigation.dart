
// import 'package:flutter/material.dart';

// class TabNavigation extends StatefulWidget {
//   const TabNavigation({super.key});

//   @override
//   _TabNavigationState createState() => _TabNavigationState();
// }

// class _TabNavigationState extends State<TabNavigation> {
//   int _currentIndex = 0; // Tracks the currently selected tab

//   // List of pages for each tab
//   final List<Widget> _pages = [
//     const HomePage(),
//     const GoogleMapPage(),
//     const CameraScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _pages[_currentIndex], // Display the selected page
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex, // Current tab index
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index; // Update the current tab index
//           });
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: "Home",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.map),
//             label: "Map",
//           ),          BottomNavigationBarItem(
//             icon: Icon(Icons.camera),
//             label: "Camera",
//           ),
//         ],
//       ),
//     );
//   }
// }