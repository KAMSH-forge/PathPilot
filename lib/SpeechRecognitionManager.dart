import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class SpeechRecognitionManager {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  Function(String)? _onCommandRecognized;

  // Initialize speech recognition
  Future<void> initializeSpeech() async {
    bool available = await _speech.initialize(
      onError: (error) => print('Speech initialization error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    if (!available) {
      print('Speech recognition is not available');
      return;
    }
  }

  // Start continuous listening
  void startContinuousListening({
    required Function(String) onCommandRecognized,
  }) async {
    _onCommandRecognized = onCommandRecognized;

    await initializeSpeech();

    setState(() {
      _isListening = true; // Indicate that listening has started
    });

    // Announce that the app is listening (only once at the beginning)
    _flutterTts.speak("Listening for commands...");

    while (_isListening) {
      try {
        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              String recognizedText = result.recognizedWords;
              print("Recognized Text: $recognizedText");
              _onCommandRecognized?.call(recognizedText); // Process the command
            }
          },
          listenFor: const Duration(seconds: 10), // Timeout after 10 seconds
          pauseFor: const Duration(seconds: 7), // Pause before restarting
          partialResults: false, // Only process final results
          cancelOnError: true, // Stop listening on error
        );

        // Wait for 7 seconds before restarting listening (silent restart)
        await Future.delayed(const Duration(seconds: 7));
      } catch (e) {
        print("Error during speech recognition: $e");

        // Reinitialize speech recognition after an error (silently)
        await initializeSpeech();
      }
    }

    setState(() {
      _isListening = false; // Update state when listening stops
    });

    // Notify the user that listening has stopped (only once at the end)
    _flutterTts.speak("Stopped listening.");
  }
  // Stop continuous listening
  void stopContinuousListening() {
    setState(() {
      _isListening = false; // Stop the listening loop
    });
    _speech.stop(); // Stop the speech recognition service
    _flutterTts.speak("Stopped listening."); // Notify the user via TTS
  }
  // Simulate setState functionality
  void setState(VoidCallback callback) {
    callback();
  }
}