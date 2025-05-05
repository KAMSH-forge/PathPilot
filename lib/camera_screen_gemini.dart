import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);
  // const CameraScreen({super.key});

  @override
  CameraScreenState createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  WebSocketChannel? _channel;
  String? _latestImageBase64;
  bool _isLoading = false;
  bool _turnComplete = false;
  int _turnCount = 0;
  String aiResponse = "";
  // Expose the broadcast stream
  late Stream<dynamic> broadcastStream;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _connectToGemini();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _connectToGemini() async {
    final apiKey = 'AIzaSyAa7GXUzG6RdGlt8BwpAqUXYBxouCqzvIs';
    final endpoint =
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey';

    print('🚀 Connecting to Gemini WebSocket API...');
    _channel = WebSocketChannel.connect(Uri.parse(endpoint));

    _channel!.ready
        .then((_) => print('🔗 WebSocket connected'))
        .catchError((e) => print('❌ Connection failed: $e'));

    broadcastStream = _channel!.stream.asBroadcastStream();

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

    // broadcastStream.listen(
    //   (data) {
    //     try {
    //       final responseString = _decodeWebSocketData(data);
    //       final response = json.decode(responseString);
    //       print("stream received >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    //       print(response);
    //       setState(() {
    //         aiResponse = "$aiResponse${_handleResponse(response)}";
    //       });
    //     } catch (e) {
    //       print('❌ Error processing response: $e');
    //     }
    //   },
    //   onError: (error) => print('❌ WebSocket error: $error'),
    //   onDone: () => print('🔌 Connection closed'),
    // );

    print('⚙️ Sending setup configuration...');
    _channel!.sink.add(json.encode({
      'setup': {
        'model': 'models/gemini-2.0-flash-exp',
        'generation_config': {
          'response_modalities': ['text'],
          'temperature': 0.9,
          'max_output_tokens': 2048
        },
        'system_instruction': {
          'parts': [
            {
              'text': 'You are Path Pilot, a specialized navigation assistant for visually impaired users. '
                  'Your primary mission is to provide real-time environmental awareness and safe navigation guidance. '
                  'You must process visual input frames continuously and respond ONLY when there\'s something important to report.\n\n'
                  'CORE RESPONSIBILITIES:\n'
                  '1. Obstacle Detection:\n'
                  '   - Identify all objects in the user\'s path (vehicles, furniture, pedestrians, etc.)\n'
                  '   - Classify as moving or static with velocity estimation when possible\n'
                  '   - Calculate precise distance in steps (1 step ≈ 0.75 meters)\n\n'
                  '2. Hazard Identification:\n'
                  '   - Detect terrain hazards: potholes, open drains, construction zones, slippery surfaces\n'
                  '   - Recognize dangerous animals/objects: snakes, scorpions, broken glass, weapons\n'
                  '   - Identify potential threats: suspicious persons, unsafe areas\n\n'
                  '3. Navigation Guidance:\n'
                  '   - Provide clear avoidance instructions (direction and steps needed)\n'
                  '   - Suggest alternative routes when necessary\n'
                  '   - Confirm safe paths when environment is clear\n\n'
                  '4. QUESTION ANSWERING MODE (When prompted):\n'
                  '   - Respond to specific user queries about surroundings\n'
                  '   - Provide detailed scene descriptions when asked\n\n'
                  'USER COMMAND HANDLING:\n'
                  'When user asks questions like:\n'
                  '- "Describe current screen"\n'
                  '- "What am I looking at?"\n'
                  '- "Can you tell me what I\'m seeing?"\n'
                  '- "Describe the scene ahead"\n'
                  '- "What\'s around me?"\n\n'
                  'STRICT RESPONSE PROTOCOLS:\n'
                  '1. FORMAT REQUIREMENTS:\n'
                  '   - Respond ONLY in valid JSON format as shown in examples\n'
                  '   - NEVER use markdown, code blocks, or any decorative formatting\n'
                  '   - ALWAYS include these exact fields: text, location, response_type\n\n'
                  '2. RESPONSE TYPES:\n'
                  '   - "obstacle": For physical objects in path\n'
                  '   - "alert": For immediate dangers requiring urgent action\n'
                  '   - "okay": Only when path is completely clear\n\n'
                  '3. LANGUAGE GUIDELINES:\n'
                  '   - Be specific about directions (left/right/center)\n'
                  '   - Use consistent distance units (always in steps)\n'
                  '   - For alerts, begin with "Danger:" or "Warning:"\n'
                  '   - Keep instructions actionable and brief\n\n'
                  '4. Include relevant details about:\n'
                  '   - Major objects and their positions\n'
                  '   - Environmental context\n'
                  '   - Notable colors/textures when relevant\n'
                  '   - Any potential hazards mentioned\n\n'
                  'PROHIBITED ACTIONS:\n'
                  '   - Never add commentary outside the JSON structure\n'
                  '   - Don\'t provide unsolicited information\n'
                  '   - Avoid repeating the same alert unnecessarily\n\n'
                  'MANDATORY RESPONSE EXAMPLES:\n'
                  'For obstacles:\n'
                  '{"text": "Bicycle approaching 8 steps to your right. Move left immediately.", "location": "right", "response_type": "obstacle"}\n\n'
                  'For immediate dangers:\n'
                  '{"text": "Danger: Broken glass 2 steps ahead in center. Stop and find alternate path.", "location": "center", "response_type": "alert"}\n\n'
                  'For user questions:\n'
                  '{"text": "You\'re looking at a busy city street. There are 5 pedestrians walking towards you about 15 steps ahead, two parked cars on your right side, and a cafe with outdoor seating to your left.", "response_type": "question_answer"}\n\n'
                  '{"text": "Current view shows a park environment. There\'s a large oak tree 10 steps ahead slightly to the right, a clear walking path in the center, and benches on both sides. No immediate obstacles detected.", "response_type": "question_answer"}\n\n'
                  '{"text": "You appear to be indoors in what looks like a living room. There\'s a sofa 3 steps to your left, a coffee table directly ahead, and a television mounted on the far wall. The floor appears clear for movement.", "response_type": "question_answer"}\n\n'
                  '{"text": "Warning: While describing the beach scene ahead, I also detect broken glass 5 steps to your right. Main scene: ocean waves, few people in distance, clear walking path ahead except for the hazard mentioned.", "response_type": "question_answer"}\n\n'
                  'For clear paths:\n'
                  '{"text": "Path is clear for next 20 steps. Continue straight.", "location": "center", "response_type": "okay"}\n\n'
                  'For suspicious activity:\n'
                  '{"text": "Warning: Suspicious person 15 steps ahead holding unknown object. Recommended alternate route.", "location": "center", "response_type": "alert"}'
            }
          ]
        },
        'tools': [],
        'safety_settings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE'
          }
        ]
      }
    }));

    await broadcastStream.first;
    print('✅ Setup complete! Ready to chat');
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

  Future<void> captureAndSendImage() async {
    if (!_cameraController.value.isInitialized ||
        _cameraController.value.isTakingPicture) return;

    try {
      setState(() => _isLoading = true);

      for (int i = 0; i < 2; i++) {
        final image = await _cameraController.takePicture();
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _latestImageBase64 = base64Image;
          aiResponse = "";
          _turnCount += 1;
        });

        if (_turnCount == 2) {
          setState(() {
            _turnCount = 0;
            _turnComplete = true;
          });
        }

        _sendVoiceCommand("Describe my current scene in one sentence?");
        await Future.delayed(const Duration(milliseconds: 300)); // small delay
      }
    } catch (e) {
      print('❌ Error capturing image: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sendVoiceCommand(String recognizedText) {
    if (_latestImageBase64 == null || _channel == null) return;

    print('📤 Sending message: $recognizedText');
    print("$_turnComplete, $_turnCount");
    _channel!.sink.add(json.encode({
      'client_content': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': recognizedText},
              {
                'inlineData': {
                  'mimeType': 'image/jpeg',
                  'data': _latestImageBase64!
                }
              }
            ]
          }
        ],
        'turn_complete': _turnComplete
      }
    }));

    if (_turnComplete) {
      setState(() {
        _turnComplete = false;
      });
    }
  }

  getAiResponse() {
    return {"response": aiResponse, "responseComplete": _turnComplete};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cameraController.value.isInitialized
          ? Stack(
              children: [
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _cameraController.value.previewSize!.height,
                      height: _cameraController.value.previewSize!.width,
                      child: CameraPreview(_cameraController),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.black.withOpacity(0.7),
                    child: Text(
                      aiResponse,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: captureAndSendImage,
      //   child: _isLoading
      //       ? const CircularProgressIndicator(color: Colors.white)
      //       : const Icon(Icons.send),
      // ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}
