import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'package:google_place/google_place.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng _currentLocation = const LatLng(45.521563, -122.677433); // Default location
  LatLng? _currentPosition;
  final String _apiKey = "AIzaSyC_p8YHhBBEjDMsniEZYd4vzF73QEaGY7o";

  late GooglePlace googlePlace;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(_apiKey);
    _getUserLocation();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

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
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: "You are here"),
          ),
        );
      });

      if (mounted && mapController != null) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 14));
      }
    } else {
      print('Failed to load location data: ${response.body}');
    }
  }

  Future<void> _getUserLocation() async {
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permission = await location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != loc.PermissionStatus.granted) return;
    }

    loc.LocationData userLocation = await location.getLocation();
    setState(() {
      _currentLocation = LatLng(userLocation.latitude!, userLocation.longitude!);
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      );
    });

    if (mounted && mapController != null) {
      mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 14));
    }
  }

Future<void> _searchLocation() async {
  String query = _searchController.text;
  if (query.isEmpty) return;


  final String url =
      "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
      "?input=$query&inputtype=textquery&fields=geometry&key=$_apiKey";

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    if (data["candidates"] != null &&
        data["candidates"].isNotEmpty &&
        data["candidates"][0]["geometry"] != null) {
      double lat = data["candidates"][0]["geometry"]["location"]["lat"];
      double lng = data["candidates"][0]["geometry"]["location"]["lng"];

      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: MarkerId(query),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: query),
          ),
        );
      });

      if (mounted && mapController != null) {
        mapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14));
      }
    }
  } else {
    print("Error: ${response.body}");
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // Go back to Home Page
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: "Search Location...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _searchLocation,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(target: _currentLocation, zoom: 14.0),
              markers: _markers,
            ),
          ),
        ],
      ),
    );
  }
}
