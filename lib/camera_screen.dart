import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _yoloController = YoloViewController();
  bool _cameraGranted = false;

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _cameraGranted = true);
      _yoloController.setThresholds(confidenceThreshold: 0.5);
    } else {
      setState(() => _cameraGranted = false);
    }
  }

  void _handleDetections(List<YOLOResult> results) {
    for (final result in results) {
      print('''Detected Object:
- Label: ${result.className}
- Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%
- Position: ${result}
''');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCameraPermission());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Model Detection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cameraGranted
          ? YoloView(
              controller: _yoloController,
              modelPath: 'assets/models/your_custom_model.tflite', // Your model path
              // labelsPath: 'assets/labels/your_labels.txt',        // Your labels path
              task: YOLOTask.detect,
            onResult: _handleDetections,
            )
          : const Center(child: Text('Camera permission required')),
    );
  }
}