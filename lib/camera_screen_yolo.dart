import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';

late List<CameraDescription> camerass;

class YoloVideo extends StatefulWidget {
  const YoloVideo({Key? key}) : super(key: key);

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  late CameraController controller;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  double confidenceThreshold = 0.5;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    camerass = await availableCameras();
    vision = FlutterVision();
    controller = CameraController(camerass[0], ResolutionPreset.high);
    await controller.initialize();
    await loadYoloModel();
    setState(() {
      isLoaded = true;
      isDetecting = false;
      yoloResults = [];
    });
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/yolov8n.tflite',
      modelVersion: "yolov8",
      numThreads: 1,
      useGpu: true,
    );
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> yoloOnFrame(CameraImage image) async {
    final result = await vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: 0.4,
      confThreshold: confidenceThreshold,
      classThreshold: 0.5,
    );
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
      });
      printDetectionResults(result);
    }
  }

  void printDetectionResults(List<Map<String, dynamic>> results) {
    for (var result in results) {
      print("Detected: ${result['tag']}, Confidence: ${(result['box'][4] * 100).toStringAsFixed(1)}%");
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty || cameraImage == null) return [];

    double factorX = screen.width / cameraImage!.width;
    double factorY = screen.height / cameraImage!.height;

    return yoloResults.map((result) {
      double x = result["box"][0] * factorX;
      double y = result["box"][1] * factorY;
      double w = (result["box"][2] - result["box"][0]) * factorX;
      double h = (result["box"][3] - result["box"][1]) * factorY;

      return Positioned(
        left: x,
        top: y,
        width: w,
        height: h,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Align(
            alignment: Alignment.topLeft,
            child: Container(
              color: Colors.greenAccent,
              padding: const EdgeInsets.all(2.0),
              child: Text(
                "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(1)}%",
                style: const TextStyle(color: Colors.black, fontSize: 12.0),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });

    if (controller.value.isStreamingImages) return;

    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        await yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    await controller.stopImageStream();
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (!isLoaded) {
      return const Scaffold(
        body: Center(child: Text("Model not loaded, waiting...")),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
          ...displayBoxesAroundRecognizedObjects(size),
          Positioned(
            bottom: 75,
            width: size.width,
            child: Center(
              child: Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 5, color: Colors.white),
                ),
                child: IconButton(
                  icon: Icon(
                    isDetecting ? Icons.stop : Icons.play_arrow,
                    color: isDetecting ? Colors.red : Colors.white,
                    size: 50,
                  ),
                  onPressed: () => isDetecting ? stopDetection() : startDetection(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.black.withOpacity(0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: yoloResults.map((result) {
                  return Text(
                    "${result['tag']}: ${(result['box'][4] * 100).toStringAsFixed(1)}%",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
