import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:html/parser.dart' as html_parser;

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng _currentLocation =
      const LatLng(11.085541, -7.719945); // Default location (ABU Zaria)
  LatLng? _destination;
  final LatLngBounds abuZariaBounds = LatLngBounds(
    southwest: LatLng(11.0800, 7.6900), // Southwest corner
    northeast: LatLng(11.0900, 7.7100), // Northeast corner
  );
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  final String _apiKey = "AIzaSyC_p8YHhBBEjDMsniEZYd4vzF73QEaGY7o";
  bool _isNavigating = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _navigationSteps = [];
  int _currentStepIndex = 0;
  late FlutterTts _flutterTts;

  // Speech-to-Text Variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    _getUserLocation();
    _initSpeech();
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      print('Speech recognition is not available');
    }
  }

  void _startListening() async {
    if (_isListening) {
      setState(() {
        _isListening = false;
        _searchController.clear();
      });
      _speech.stop();
      return;
    }

    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _searchController.text = result.recognizedWords;
        });
        if (result.finalResult) {
          _processVoiceCommand(result.recognizedWords);
          _stopListening();
        }
      });
    }
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
    _speech.stop();
  }

  void _processVoiceCommand(String recognizedText) {
    if (recognizedText.toLowerCase().contains("path pilot")) {
      // Extract the command after "Pathpilot"
      String command =
          recognizedText.toLowerCase().replaceAll("path pilot", "").trim();
      if (command.contains("take me to")) {
        // Handle destination search command
        String destinationQuery = command.replaceAll("take me to", "").trim();
        if (destinationQuery.isNotEmpty) {
          _searchController.text = destinationQuery; // Update search bar
          _searchLocation(); // Search for the destination
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Please specify a destination.")),
          );
          _flutterTts.speak("Please specify a destination.");
        }
      } else if (command.contains("where am i") ||
          command.contains("tell me my location")) {
        // Handle current location command
        _getUserLocation();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Command not recognized. Try again.")),
        );
        _flutterTts.speak("Command not recognized. Try again.");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please start your command with 'path pilot'.")),
      );
      _flutterTts.speak("Please start your command with 'path pilot'.");
    }
  }

  Future<void> _getUserLocation() async {
    if (_isNavigating) {
      // Stop navigation if it's currently active
      setState(() {
        _isNavigating = false; // stop navigation
        _currentStepIndex = 0; // Reset step index
        _navigationSteps.clear(); // Clear navigation steps
        _polylines.clear(); // Clear polyline
      });
    }

    setState(() {
      _isLoading = true;
    });

    loc.Location _locationController = loc.Location();
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }
    loc.PermissionStatus permission = await _locationController.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _locationController.requestPermission();
      if (permission != loc.PermissionStatus.granted) return;
    }

    _locationController.onLocationChanged
        .listen((loc.LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentLocation =
              LatLng(currentLocation.latitude!,currentLocation.longitude!);
        });
      }
    });

    loc.LocationData userLocation = await _locationController.getLocation();

    setState(() {
      _currentLocation =
          LatLng(userLocation.latitude!, userLocation.longitude!);
      _destination = null;
      _updateMarkers();
      _polylines.clear();
      _isLoading = false;
    });

    if (mounted && mapController != null) {
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 14));
    }
    await _speakLocation(_currentLocation);
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentLocation,
          infoWindow: const InfoWindow(title: "You are here"),
        ),
      );
      if (_destination != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: _destination!,
            infoWindow: const InfoWindow(title: "Destination"),
          ),
        );
      }
    });
  }

  Future<void> _speakLocation(LatLng location) async {
    try {
      final String url =
          "https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$_apiKey";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["results"] != null && data["results"].isNotEmpty) {
          String address = data["results"][0]["formatted_address"];
          print("Current Location: $address");
          await _flutterTts.speak("You are currently at $address");
        }
      } else {
        print("Error fetching address: ${response.body}");
      }
    } catch (e) {
      print("Error with text-to-speech: $e");
    }
  }

  String _cleanHtmlTags(String htmlText) {
    final document = html_parser.parse(htmlText);
    return document.body?.text ?? htmlText;
  }

  Future<void> _getDirections(LatLng start, LatLng end) async {
    final String url = "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${start.latitude},${start.longitude}"
        "&destination=${end.latitude},${end.longitude}"
        "&mode=walking"
        "&key=$_apiKey";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'].isNotEmpty) {
        String polyline = data['routes'][0]['overview_polyline']['points'];
        List<LatLng> polylineCoordinates = decodePolyline(polyline)
            .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
            .toList();
        setState(() {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: Colors.blue,
              width: 5,
            ),
          );
        });
        // Extract navigation steps
        List<dynamic> steps = data['routes'][0]['legs'][0]['steps'];
        print(steps);
        setState(() {
          _navigationSteps = steps.map((step) {
            return {
              'instructions': _cleanHtmlTags(step['html_instructions']),
              'distance': step['distance']['text'],
              'duration': step['duration']['text'],
            };
          }).toList();
        });
        // Move the camera to show both locations
        if (mounted && mapController != null) {
          mapController.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                    _currentLocation.latitude < _destination!.latitude
                        ? _currentLocation.latitude
                        : _destination!.latitude,
                    _currentLocation.longitude < _destination!.longitude
                        ? _currentLocation.longitude
                        : _destination!.longitude),
                northeast: LatLng(
                    _currentLocation.latitude > _destination!.latitude
                        ? _currentLocation.latitude
                        : _destination!.latitude,
                    _currentLocation.longitude > _destination!.longitude
                        ? _currentLocation.longitude
                        : _destination!.longitude),
              ),
              50, // Padding
            ),
          );
        }
      _startNavigation();
      print("starting navigation within _getDirection");
      }
    } else {
      print("Error fetching directions: ${response.body}");
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
        LatLng searchedLocation = LatLng(lat, lng);

        setState(() {
          _destination = searchedLocation;
          _updateMarkers();
          _getDirections(_currentLocation, _destination!);
        });
      }
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> _startNavigation() async {
    if (_destination == null || _navigationSteps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a destination first.")),
      );
      return;
    }
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0; // Reset to the first step
    });
    // Simulate navigation based on navigation steps
    for (int i = 0; i < _navigationSteps.length; i++) {
      if (!_isNavigating) break; // Stop if navigation is canceled
      // Read out the current step's instruction using TTS
      String instruction = _navigationSteps[i]['instructions'];
      await _flutterTts.speak(instruction);

      // Estimate the duration of the speech
      int wordCount = instruction.split(' ').length;
      double speakingRate = 2.5; // Words per second
      int speechDuration = (wordCount / speakingRate).ceil(); // In seconds

      // Get the current step's polyline
      List<LatLng> stepPoints = decodePolyline(_navigationSteps[i]['polyline'])
          .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
          .toList();

      // Move the marker along the step's polyline
      for (int j = 0; j < stepPoints.length; j++) {
        if (!_isNavigating) break; // Stop if navigation is canceled

        // Calculate delay based on speech duration and number of points
        int delayPerPoint = (speechDuration * 1000 ~/ stepPoints.length);
        await Future.delayed(Duration(milliseconds: delayPerPoint));

        setState(() {
          _currentLocation = stepPoints[j];
          _updateMarkers();
        });

        if (mounted && mapController != null) {
          mapController.animateCamera(CameraUpdate.newLatLng(_currentLocation));
        }
      }

      // Update the current step index
      if (i < _navigationSteps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      }
    }

    setState(() {
      _isNavigating = false;
    });
  }

  Widget _buildNavigationPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isNavigating ? 200 : 0,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Navigation Instructions",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isNavigating = false;
                      });
                    },
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _navigationSteps.length,
                  itemBuilder: (context, index) {
                    final step = _navigationSteps[index];
                    final isCurrentStep = index == _currentStepIndex;
                    return ListTile(
                      title: Text(
                        step['instructions'],
                        style: TextStyle(
                          fontWeight: isCurrentStep
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle:
                          Text("${step['distance']} (${step['duration']})"),
                      tileColor: isCurrentStep ? Colors.blue.shade100 : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Go back to previous screen
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Navigation Panel at the Top
              _buildNavigationPanel(),
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
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.blue),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic_off : Icons.mic,
                              color: Colors.blue,
                            ),
                            onPressed: _startListening,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (value) {
                          _searchLocation();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : GoogleMap(
                        onMapCreated: (controller) {
                          mapController = controller;
                        },
                        polylines: _polylines,
                        markers: _markers,
                        initialCameraPosition: CameraPosition(
                          target: _currentLocation,
                          zoom: 14.0, // Adjust zoom level as needed
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _getUserLocation,
            tooltip: "Go to my location",
            enableFeedback: true,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _isNavigating ? null : _startNavigation,
            tooltip: "Start/Stop Navigation",
            enableFeedback: true,
            child: Icon(_isNavigating ? Icons.stop : Icons.navigation),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _startListening,
            tooltip: "Process Voice Command",
            enableFeedback: true,
            child: Icon(_isListening ? Icons.stop : Icons.mic),
          ),
        ],
      ),
    );
  }
}
