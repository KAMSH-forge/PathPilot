import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:ultralytics_yolo/yolo_task.dart';

class CameraScreenYolo extends StatefulWidget {
  const CameraScreenYolo({Key? key}) : super(key: key);
  @override
  _CameraScreenYoloState createState() => _CameraScreenYoloState();
}

class _CameraScreenYoloState extends State<CameraScreenYolo> {
  final controller = YoloViewController();
  double _confidence = 0.5;

  @override
  void initState() {
    super.initState();
    // Set initial detection parameters
    controller.setThresholds(
      confidenceThreshold: _confidence,
      iouThreshold: 0.45,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('YOLO Object Detection')),
      body: Column(
        children: [
          // Slider for confidence threshold
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text('Confidence: ${_confidence.toStringAsFixed(2)}'),
                Expanded(
                  child: Slider(
                    value: _confidence,
                    min: 0.1,
                    max: 0.9,
                    onChanged: (value) {
                      setState(() {
                        _confidence = value;
                      });
                      controller.setConfidenceThreshold(value);
                    },
                  ),
                ),
              ],
            ),
          ),

          // YOLO Camera View
          Expanded(
            child: YoloView(
              controller: controller,
              task: YOLOTask.detect,
              modelPath: 'assets/yolov8n.tflite', // Ensure this model is correctly bundled
              onResult: (results) {
                print('Detected ${results.length} objects');
              },
            ),
          ),
        ],
      ),
    );
  }
}
