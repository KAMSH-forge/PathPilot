import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:location/location.dart' as loc;
import 'package:http/http.dart' as http;
import 'package:google_place/google_place.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});
  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng _currentLocation =
      const LatLng(45.521563, -122.677433); // Default location
  LatLng? _currentPosition;
  final String _apiKey = "AIzaSyC_p8YHhBBEjDMsniEZYd4vzF73QEaGY7o";

  late GooglePlace googlePlace;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    googlePlace = GooglePlace(_apiKey);
    _getUserLocation();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      print('speech recognition is not available');
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
          });

          if (result.finalResult) {
            _searchLocation();
            _stopListening();
          }
        });
      }
    }
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    _speech.stop();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _fetchLocationFromAPI() async {
    final response = await http.post(
      Uri.parse(
          'https://www.googleapis.com/geolocation/v1/geolocate?key=$_apiKey'),
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
        mapController
            .animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 14));
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
      _currentLocation =
          LatLng(userLocation.latitude!, userLocation.longitude!);
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
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 14));
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
        _markers.clear(); // Clear previous markers

        // Add marker for searched location
        _markers.add(
          Marker(
            markerId: MarkerId(query),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: query),
          ),
        );

        // Add marker for current location
        _markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: _currentLocation,
            infoWindow: const InfoWindow(title: "You are here"),
          ),
        );
      });

      if (mounted && mapController != null) {
        // Move the camera to show both markers
        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                  lat < _currentLocation.latitude ? lat : _currentLocation.latitude,
                  lng < _currentLocation.longitude ? lng : _currentLocation.longitude),
              northeast: LatLng(
                  lat > _currentLocation.latitude ? lat : _currentLocation.latitude,
                  lng > _currentLocation.longitude ? lng : _currentLocation.longitude),
            ),
            50, // Padding
          ),
        );
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
                    decoration: InputDecoration(
                        hintText: "Search Location...",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, color: Colors.blue),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (value) {
                      _searchLocation();
                    },
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ]),
                ),
                // IconButton(
                //   onPressed: _searchLocation,
                //   icon: const Icon(Icons.search),
                // ),
                IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.blue),
                    onPressed: _startListening)
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition:
                  CameraPosition(target: _currentLocation, zoom: 14.0),
              markers: _markers,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getUserLocation,
        tooltip: "Go to my location",
        enableFeedback: true,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
