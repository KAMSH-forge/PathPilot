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