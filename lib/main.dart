import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home_page.dart';
import 'voice_to_text_page.dart';
import 'flutter_map_page.dart';
import 'googlemap.dart';
import 'Osm_map.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';
void main() {
  GoogleMapsFlutterPlatform.instance = GoogleMapsFlutterWeb();
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
        path: '/voice',
        builder: (context, state) => VoiceToTextPage(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => FlutterMapPage(),
      ),
      GoRoute(
        path: '/osmap',
        builder: (context, state) => OsmMapPage(),
      ),
          GoRoute(
      path: '/google-map',
      builder: (context, state) => GoogleMapPage(),
    ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router, // Use GoRouter for navigation
    );
  }
}
