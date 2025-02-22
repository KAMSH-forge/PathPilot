import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  late GoogleMapController mapController;
  LatLng? _currentPosition;
  final LatLng _defaultLocation = const LatLng(45.521563, -122.677433); // Fallback location

  final String _apiKey = "AIzaSyC_p8YHhBBEjDMsniEZYd4vzF73QEaGY7o"; // Replace with your actual API Key

  @override
  void initState() {
    super.initState();
    _fetchLocationFromAPI();
  }

  /// Fetch the user's location using Google Maps Geolocation API
  Future<void> _fetchLocationFromAPI() async {
    final response = await http.post(
      Uri.parse('https://www.googleapis.com/geolocation/v1/geolocate?key=$_apiKey'),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      double lat = data['location']['lat'];
      double lon = data['location']['lng'];

      setState(() {
        _currentPosition = LatLng(lat, lon);
      });

      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
        } else {
      print('Failed to load location data: ${response.body}');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
    });

    if (_currentPosition != null) {
      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps with API Key'),
          elevation: 2,
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _currentPosition ?? _defaultLocation, // Use API location or fallback
            zoom: 14.0,
          ),
          myLocationEnabled: true, // Show user's location on the map
        ),
      ),
    );
  }
}
