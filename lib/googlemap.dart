import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart' as loc;
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'SpeechRecognitionManager.dart';
import 'camera_screen_gemini.dart';
import 'voice_command_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  // final String _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  // final String _googleAiStudioApiKey = dotenv.env['GOOGLE_AI_STUDIO_API_KEY'] ?? '';
  final GlobalKey<CameraScreenState> _cameraKey =
      GlobalKey<CameraScreenState>();
  late SharedPreferences _prefs;
  late GoogleMapController mapController;
  // final TextEditingController _searchController = TextEditingController();
  LatLng _currentLocation =
      const LatLng(11.085541, -7.719945); // Default location (ABU Zaria)
  LatLng? _destination;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  final String _apiKey = "AIzaSyC_p8YHhBBEjDMsniEZYd4vzF73QEaGY7o";
  bool _isNavigating = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _navigationSteps = [];
  int _currentStepIndex = 0;
  late FlutterTts _flutterTts;
  late BitmapDescriptor _customMarkerIcon;
  double _currentHeading = 0.0; // Stores the current compass heading
  bool _isCameraVisible = true; // Controls camera visibility
  final stt.SpeechToText _speech =
      stt.SpeechToText(); // Speech-to-Text Variables
  bool _isListening = false;
  bool _isMapPrimary = true;
  bool _isMapOnTop =
      true; // Controls whether the map is on top or the camera is on top
  late VoiceCommandHandler _voiceCommandHandler;
  late SpeechRecognitionManager _speechRecognitionManager;
  String aiResponse = "";

  // late CameraScreen _cameraScreen;
  BluetoothConnection? _connection;
  bool isConnected = false;
  String statusMessage = 'Ready to connect';
  final String deviceAddress = '98:D3:31:F7:0C:94';
  final TextEditingController _textController = TextEditingController();
  final List<String> _receivedMessages = [];

  // Initialized as soon as map page loads
  @override
  void initState() {
    super.initState();
    _initializeSpeechRecognition();
    _initializeTts();
    _initSpeech();
    _connectToDevice();
    _loadSharedPrefAndSpeakIntro();
    _startContinuousListening();
    _loadCustomMarkerIcon();

    //  _cameraScreen = CameraScreen(key: _cameraKey);
    // Initialize the VoiceCommandHandler
    _voiceCommandHandler = VoiceCommandHandler(
      showFeedback: _showFeedback,
      getDestination: _getDestinationFromSearch,
      getUserLocation: () => _getUserLocation(),
      stopNavigation: _stopNavigation,
      togglePrimaryView: _togglePrimaryView,
      captureAndSendImage: _captureAndSendImage,
      getAiResponse: _getAiResponse,
      toggleCameraVisibility: (visible) {
        setState(() {
          _isCameraVisible = visible;
        });
      },
    );
    // Convert raw magnetometer data to heading (compass direction)
    magnetometerEvents.listen((MagnetometerEvent event) {
      double heading = _calculateHeading(event);
      setState(() {
        _currentHeading = heading;
      });
    });
  }

  double _calculateHeading(MagnetometerEvent event) {
    double x = event.x;
    double y = event.y;
    // Calculate the heading in degrees (0 = North, 90 = East, etc.)
    double heading = (atan2(y, x) * (180 / pi)) + 180;
    return heading;
  }

  void _initializeTts() {
    _flutterTts = FlutterTts();
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  @override
  void dispose() {
    // Stop continuous listening if active
    _stopContinuousListening();
    // Cancel any ongoing speech recognition tasks
    _speech.cancel();
    // Release TTS resources
    _flutterTts.stop();
    // Call the parent class's dispose method
    super.dispose();
  }

  Future<void> _initSpeech() async {
    bool available = await _speech.initialize();
    if (!available) {
      print('Speech recognition is not available');
    }
  }

  Future<void> _connectToDevice({int maxAttempts = 3}) async {
    int attempt = 0;
    bool connected = false;

    while (attempt < maxAttempts && !connected) {
      attempt++;
      try {
        setState(() {
          statusMessage = '🔍 Attempt $attempt: Searching for devices...';
        });

        List<BluetoothDevice> devices =
            await FlutterBluetoothSerial.instance.getBondedDevices();

        BluetoothDevice? device;
        try {
          device = devices.firstWhere((d) => d.address == deviceAddress);
        } catch (_) {
          device = null;
        }

        if (device == null) {
          setState(() {
            statusMessage = '❗ Device not found (Attempt $attempt)';
          });
          continue;
        }

        setState(() {
          statusMessage =
              '🔌 Attempt $attempt: Connecting to ${device!.name}...';
        });

        _connection = await BluetoothConnection.toAddress(device.address);
        connected = true;

        setState(() {
          isConnected = true;
          statusMessage = '✅ Connected to ${device!.name}';
        });

        _flutterTts.speak("Hardware device connected successfully");
        _sendBluetoothMessage("LRLRLRLRLRLRLRLRRLRLRLRLRLR");
        _connection!.input?.listen((Uint8List data) {
          final received = String.fromCharCodes(data);
          print('📥 Received data: $received');
          setState(() {
            _receivedMessages.add(received);
          });
        }).onDone(() {
          print('🔌 Disconnected by remote device');
          setState(() {
            isConnected = false;
            statusMessage = '🔌 Disconnected';
          });
        });
      } catch (error) {
        print('❌ Attempt $attempt failed: $error');
        if (attempt >= maxAttempts) {
          setState(() {
            statusMessage = '❌ Connection failed after $attempt attempts';
          });
        } else {
          await Future.delayed(
              Duration(seconds: 2)); // Optional delay before retry
        }
      }
    }
  }

  void _disconnect() {
    if (isConnected && _connection != null) {
      _connection!.dispose();
      _connection!.finish();
      setState(() {
        isConnected = false;
        statusMessage = '🔌 Disconnected manually';
      });
    }
  }

  void _sendMessage() {
    if (_connection != null && _textController.text.isNotEmpty) {
      final text = _textController.text + "\r\n";
      _connection!.output.add(Uint8List.fromList(text.codeUnits));
      _connection!.output.allSent;
      print('📤 Sent: $text');

      setState(() {
        _textController.clear();
        _receivedMessages.add('You: $text');
      });
    }
  }

  void _sendBluetoothMessage(String message) {
    if (_connection != null && isConnected && message.isNotEmpty) {
      final formatted =
          message + "\r\n"; // Append newline if required by device
      _connection!.output.add(Uint8List.fromList(formatted.codeUnits));
      _connection!.output.allSent;

      print('📤 Sent: $formatted');

      setState(() {
        _receivedMessages.add('You: $formatted');
      });
    } else {
      print('⚠️ Cannot send: Not connected or message is empty.');
    }
  }

  String _decodeWebSocketData(dynamic data) {
    try {
      if (data is String) return data;
      if (data is Uint8List || data is List<int>) return utf8.decode(data);
    } catch (e) {
      throw FormatException(
          'Unsupported WebSocket data type: ${data.runtimeType}');
    }
    return '';
  }

  void _captureAndSendImage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        aiResponse = "";
      });
      if (_cameraKey.currentState != null) {
        _cameraKey.currentState?.captureAndSendImage();
        // print(_cameraKey.currentState?.broadcastStream);
        _cameraKey.currentState?.broadcastStream.listen(
          (data) {
            try {
              final responseString = _decodeWebSocketData(data);
              final response = json.decode(responseString);
              // print(response);
              print(
                  "stream received  (main page) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> (main page)");
              final serverContent = response['serverContent'];
              if (serverContent['turnComplete'] == null) {
                // print(aiResponse);
                setState(() {
                  aiResponse = "$aiResponse${_handleResponse(response)}";
                });
              } else {
                print(
                    "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
                // print(aiResponse);

                final final_response = json.decode(aiResponse);
                final text = final_response['text'];
                final response_type = final_response['response_type'];
                print(text);
                _showFeedback(text);
                print(response_type);

                setState(() {
                  aiResponse = "";
                });
              }
            } catch (e) {
              print('❌ Error processing response: $e');
            }
          },
          onError: (error) => print('❌ WebSocket error: $error'),
          onDone: () => print('🔌 Connection closed'),
        );
      } else {
        print("Camera widget state is not yet initialized.");
      }
    });
  }

  String _handleResponse(Map<String, dynamic> response) {
    if (response['serverContent'] != null) {
      final content = response['serverContent'];
      final modelTurn = content['modelTurn'];
      if (modelTurn != null) {
        final parts = modelTurn['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          for (final part in parts) {
            if (part['text'] != null) {
              return part['text'];
            }
          }
        }
      }
    }
    return "No response from AI.";
  }

  void _getAiResponse() {
    _cameraKey.currentState?.getAiResponse();
    // _cameraKey.currentState?.
  }

  void _initializeSpeechRecognition() {
    _speechRecognitionManager = SpeechRecognitionManager();
  }

  // Helper for showing feedback via SnackBar and TTS
  void _showFeedback(String message) {
    // ScaffoldMessenger.of(context).hideCurrentSnackBar();
    // ScaffoldMessenger.of(context)
    //     .showSnackBar(SnackBar(content: Text(message)));
    _flutterTts.speak(message);
  }

  Future<void> _loadSharedPrefAndSpeakIntro() async {
    _prefs = await SharedPreferences.getInstance();
    bool isFirstTime = _prefs.getBool('isFirstTime') ?? true;
    if (isFirstTime) {
      await _flutterTts.speak(
        "Welcome to Path Pilot! To use the app, say 'Pilot' followed by a command. "
        "For example, say 'Path Pilot, take me to [destination]' to navigate, or say "
        "'Pilot, where am I?' to get your current location. Listening now...",
      );
      // Update SharedPreferences to mark that the intro has been spoken
      await _prefs.setBool('isFirstTime', false);
    }
  }

  void _startContinuousListening() {
    setState(() {
      _isListening = true;
    });
    _speechRecognitionManager.startContinuousListening(
      onCommandRecognized: _processVoiceCommand,
    );
  }

  void _stopContinuousListening() {
    setState(() {
      _isListening = false;
    });
    _speechRecognitionManager.stopContinuousListening();
  }

  Future<void> _loadCustomMarkerIcon() async {
    _customMarkerIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/images/navIcon2.png',
    );
  }

  void _processVoiceCommand(String recognizedText) {
    _voiceCommandHandler.processVoiceCommand(recognizedText);
    // _voiceCommandHandler.processVoiceCommandWithAI(recognizedText);
    // _voiceCommandHandler.processVoiceCommandWithAIStream(recognizedText);
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false; // Stop navigation
      _currentStepIndex = 0; // Reset step index
      _navigationSteps.clear(); // Clear navigation steps
      _polylines.clear(); // Clear polylines
      _destination = null; // Clear destination
      _updateMarkers(); // Clear destination marker
    });
    if (mounted && mapController != null) {
      mapController
          .animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 16));
    }
    // Optionally, announce that navigation has stopped
    _flutterTts.speak("Navigation stopped.");
  }

  Future<void> _getUserLocation() async {
    if (_isNavigating) {
      _stopNavigation();
    }
    setState(() {
      _isLoading = true;
    });
    loc.Location locationController = loc.Location();
    bool serviceEnabled = await locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await locationController.requestService();
      if (!serviceEnabled) return;
    }
    loc.PermissionStatus permission = await locationController.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await locationController.requestPermission();
      if (permission != loc.PermissionStatus.granted) return;
    }

    locationController.onLocationChanged
        .listen((loc.LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentLocation =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _updateMarkers();
          if (mounted && mapController != null) {
            mapController
                .animateCamera(CameraUpdate.newLatLng(_currentLocation));
          }
        });
      }
    });

    loc.LocationData userLocation = await locationController.getLocation();

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
          .animateCamera(CameraUpdate.newLatLngZoom(_currentLocation, 18.5));
    }

    LocationPermission perm;
    perm = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    double lat = position.latitude;

    double long = position.longitude;

    LatLng location = LatLng(lat, long);
    await _speakLocation(location);
  }

  void _updateMarkers() async {
    // Load the custom marker icon
    setState(() {
      _markers.clear();
      // _markers.add(
      //   Marker(
      //     markerId: const MarkerId('currentLocation'),
      //     position: _currentLocation,
      //     infoWindow: const InfoWindow(title: "You are here"),
      //     // icon: _customMarkerIcon,
      //     rotation: _currentHeading,
      //   ),
      // );

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
      final String url = "https://maps.googleapis.com/maps/api/geocode/json"
          "?latlng=${location.latitude},${location.longitude}"
          "&key=$_apiKey";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["results"] != null && data["results"].isNotEmpty) {
          // 1. Pull out the formatted address
          // String address = data["results"][0]["formatted_address"];
          // print(data);
          // //);
          // // 2. Remove all numbers via regex
          // address = address.replaceAll(RegExp(r'\d+'), '');

          // // 3. Optionally collapse extra spaces left behind
          // address = address.replaceAll(RegExp(r'\s{2,}'), ' ').trim();

          // print("Current Location (cleaned): $address");

          final addressComponents = data['results'][0]['address_components'];
          print(addressComponents);

          String locality = '';
          String administrativeAreaLevel2 = '';
          String administrativeAreaLevel1 = '';
          String country = '';

          for (var component in addressComponents) {
            final types = List<String>.from(component['types']);
            final longName = component['long_name'];

            if (types.contains('locality')) {
              locality = longName;
            } else if (types.contains('administrative_area_level_2')) {
              administrativeAreaLevel2 = longName;
            } else if (types.contains('administrative_area_level_1')) {
              administrativeAreaLevel1 = longName;
            } else if (types.contains('country')) {
              country = longName;
            }
          }

          // Build readable location string
          List<String> locationParts = [];

          if (locality.isNotEmpty) locationParts.add(locality);
          if (administrativeAreaLevel2.isNotEmpty)
            locationParts.add(administrativeAreaLevel2);
          if (administrativeAreaLevel1.isNotEmpty)
            locationParts.add(administrativeAreaLevel1);
          if (country.isNotEmpty) locationParts.add(country);

          String finalLocation = locationParts.join(', ');

          print("Current Location: $finalLocation");

          await _flutterTts.speak("You are currently at $finalLocation");
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
        }); // Extract navigation steps
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

  Future<void> _getDestinationFromSearch(String destinationQuery) async {
    if (destinationQuery.isEmpty) {
      _showFeedback("Please enter a destination to search.");
      return;
    }
    setState(() => _isLoading = true); // Show loading indicator
    // Use the Google Places API to find the destination
    final String url =
        "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
        "?input=$destinationQuery&inputtype=textquery&fields=geometry&key=$_apiKey";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["candidates"] != null &&
          data["candidates"].isNotEmpty &&
          data["candidates"][0]["geometry"] != null) {
        double lat = data["candidates"][0]["geometry"]["location"]["lat"];
        double lng = data["candidates"][0]["geometry"]["location"]["lng"];
        LatLng location = LatLng(lat, lng);

        setState(() {
          _destination = location;
          _updateMarkers(); // Update markers
          _getDirections(_currentLocation, _destination!); // Get directions
          // _isLoading = false; // Hide loading indicator
        });
      } else {
        _showFeedback(
            "Could not find location: '$destinationQuery'. Please try a different search term.");
      }
    } else {
      print(
          "Error searching for destination: ${response.statusCode} ${response.body}");
      _showFeedback("An error occurred while searching for the destination.");
    }

    // setState(() => _isLoading = false); // Ensure loading indicator is hidden
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

  // Toggle between Map Primary and Camera Primary views
  void _togglePrimaryView() {
    setState(() {
      _isMapPrimary = !_isMapPrimary;
      if (!_isMapPrimary) {
        _isCameraVisible =
            true; // Ensure PiP is visible when switching to camera primary
      }
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

  // Build the Google Map Widget
  Widget _buildMapWidget() {
    return GoogleMap(
      onMapCreated: (controller) {
        mapController = controller;
      },
      polylines: _polylines,
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      initialCameraPosition: CameraPosition(
          target: _currentLocation, zoom: 14.0, tilt: _isNavigating ? 45 : 0),
    );
  }

  // Build the Camera Preview Widget using the imported CameraScreen
  Widget _buildCameraWidget() {
    return CameraScreen(key: _cameraKey);
  }

  // Build a Thumbnail Version of the Map for PiP
  Widget _buildMapThumbnail() {
    return GoogleMap(
      onMapCreated: (controller) {},
      polylines: _polylines,
      markers: _markers,
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: 9.0, // Smaller zoom level for thumbnail
      ),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Go back to previous screen
        ),
      ),
      body: Stack(
        children: [
          // Main View (Map or Camera)
          _isMapPrimary ? _buildMapWidget() : _buildCameraWidget(),
          // Picture-in-Picture (PiP) View
          if (_isCameraVisible)
            Positioned(
              right: 16,
              bottom: 100, // Position above the floating action buttons
              child: SizedBox(
                width: 150,
                height: 200,
                child: Card(
                  elevation: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _isMapPrimary
                        ? CameraScreen(key: _cameraKey)
                        : _buildMapThumbnail(),
                  ),
                ),
              ),
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
            onPressed: _isListening
                ? _stopContinuousListening
                : _startContinuousListening,
            tooltip: "Process Voice Command",
            enableFeedback: true,
            child: Icon(_isListening ? Icons.stop : Icons.mic),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                _isCameraVisible =
                    !_isCameraVisible; // Toggle camera visibility
              });
            },
            tooltip: "Toggle Camera",
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _togglePrimaryView,
            tooltip: "Switch Main View",
            child: Icon(_isMapPrimary
                ? Icons.cameraswitch_outlined
                : Icons.map_outlined),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _captureAndSendImage,
            tooltip: "Switch Main View",
            child: Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
