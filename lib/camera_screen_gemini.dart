import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

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

    final broadcastStream = _channel!.stream.asBroadcastStream();

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

    broadcastStream.listen(
      (data) {
        try {
          final responseString = _decodeWebSocketData(data);
          final response = json.decode(responseString);
          print("stream received >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
          print(response);
          setState(() {
            aiResponse = "$aiResponse${_handleResponse(response)}";
          });
        } catch (e) {
          print('❌ Error processing response: $e');
        }
      },
      onError: (error) => print('❌ WebSocket error: $error'),
      onDone: () => print('🔌 Connection closed'),
    );

    print('⚙️ Sending setup configuration...');
    _channel!.sink.add(json.encode({
      'setup': {
        'model': 'models/gemini-2.0-flash-exp',
        'generation_config': {
          'response_modalities': ['text'],
          'temperature': 0.9,
          'max_output_tokens': 2048
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

      for (int i = 0; i < 10; i++) {
        final image = await _cameraController.takePicture();
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          _latestImageBase64 = base64Image;
          aiResponse = "";
          _turnCount += 1;
        });

        if (_turnCount == 10) {
          setState(() {
            _turnCount = 0;
            _turnComplete = true;
          });
        }

        _sendVoiceCommand("Where am I?");
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

  String getAiResponse() {
    return aiResponse;
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
      floatingActionButton: FloatingActionButton(
        onPressed: captureAndSendImage,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.send),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}
