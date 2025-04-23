import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

// Main camera screen widget
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