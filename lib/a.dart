import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'camera_screen.dart'; // Import the CameraScreen module

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  _GoogleMapPageState createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  late GoogleMapController mapController;
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentLocation = const LatLng(11.085541, -7.719945); // Default location
  LatLng? _destination;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  bool _isMapOnTop = true; // Controls whether the map is on top or the camera is on top
  bool _isCameraVisible = false; // Controls whether the camera preview is visible
  bool _isLoading = false; // Controls loading state
  bool _isMapPrimary = true; // Controls whether the map or camera is the main view

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
                    child: _isMapPrimary ? const CameraScreen() : _buildMapThumbnail(),
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
                _isCameraVisible = !_isCameraVisible; // Toggle camera visibility
              });
            },
            tooltip: "Toggle Camera",
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _togglePrimaryView,
            tooltip: "Switch Main View",
            child: Icon(_isMapPrimary ? Icons.cameraswitch_outlined : Icons.map_outlined),
          ),
        ],
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
      initialCameraPosition: CameraPosition(
        target: _currentLocation,
        zoom: 14.0,
      ),
    );
  }

  // Build the Camera Preview Widget using the imported CameraScreen
  Widget _buildCameraWidget() {
    return const CameraScreen();
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
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      scrollGesturesEnabled: false,
      zoomGesturesEnabled: false,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: false,
    );
  }

  // Dummy methods for navigation and other functionalities
  void _getUserLocation() {
    // Fetch and update the user's current location
  }

  void _startNavigation() {
    // Start navigation logic
  }

  void _stopContinuousListening() {
    // Stop continuous listening logic
  }

  void _startContinuousListening() {
    // Start continuous listening logic
  }

  void _searchLocation() {
    // Search location logic
  }

  Widget _buildNavigationPanel() {
    return Container(
      height: 50,
      color: Colors.grey[200],
      child: const Center(child: Text("Navigation Panel")),
    );
  }

  // Toggle between Map Primary and Camera Primary views
  void _togglePrimaryView() {
    setState(() {
      _isMapPrimary = !_isMapPrimary;
      if (!_isMapPrimary) {
        _isCameraVisible = true; // Ensure PiP is visible when switching to camera primary
      }
    });
  }
}


Future<void> _getDestination() async {
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
        LatLng location = LatLng(lat, lng);

        setState(() {
          _destination = location;
          _updateMarkers();
          _getDirections(_currentLocation, _destination!);
        });
      }
    } else {
      print("Error: ${response.body}");
    }
  }


// camera original code 

  class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  // Camera controller to manage camera functionality
  CameraController? _controller;
  
  // Loading state flag
  bool _isLoading = true;
  
  // Error state flag
  bool _hasError = false;
  
  // Error message to display
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
    // Initialize camera when widget is created
    _initCamera();
  }

  @override
  void dispose() {
    // Clean up observers and controllers
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  // Handle app lifecycle changes (background/foreground)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    // When app goes to background
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } 
    // When app comes back to foreground
    else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _initCamera(); // Reinitialize camera
      }
    }
  }

  // Main camera initialization method
  Future<void> _initCamera() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // STEP 1: Check and request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        throw Exception('Camera permission denied');
      }

      // STEP 2: Get list of available cameras on device
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // STEP 3: Initialize camera controller with first available camera
      _controller = CameraController(
        cameras.first, // Use first camera (typically back camera)
        ResolutionPreset.medium, // Medium resolution for balance
        enableAudio: false, // Disable audio since we're just showing preview
      );

      // STEP 4: Initialize the camera (async operation)
      await _controller!.initialize();

      // STEP 5: Update UI when done
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Handle any errors that occur during initialization
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black, // Black background looks better for camera
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text("Initializing camera...", 
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    // Show error message if something went wrong
    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage', 
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initCamera, // Retry button
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Fallback if camera isn't initialized properly
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text('Camera not initialized', 
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    // Main camera preview view
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full screen camera preview using FittedBox
          Positioned.fill(
            child: FittedBox(
              // Cover the entire available space while maintaining aspect ratio
              fit: BoxFit.cover,
              child: SizedBox(
                // Calculate dimensions based on camera aspect ratio
                width: 1, // Base width
                height: 1 / _controller!.value.aspectRatio, // Proportional height
                child: CameraPreview(_controller!), // Actual camera preview
              ),
            ),
          ),
          
          // You can add camera controls here by uncommenting:
          /*
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add your camera controls here
                // Example: Capture button, flash toggle, etc.
              ],
            ),
          ),
          */
        ],
      ),
    );
  }
}