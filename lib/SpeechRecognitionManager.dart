import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';
import 'package:real_volume/real_volume.dart';

class SpeechRecognitionManager {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  Function(String)? _onCommandRecognized;
  double _originalVolume = 0.5; // Default initial volume

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

  void startContinuousListening({
    required Function(String) onCommandRecognized,
  }) async {
    _onCommandRecognized = onCommandRecognized;
    await initializeSpeech();

    setState(() => _isListening = true);
    _flutterTts.speak("Listening for commands...");

    while (_isListening) {
      try {
        // Store original volume and mute
        setState(() async => _originalVolume =
            await RealVolume.getCurrentVol(StreamType.RING) ?? 0.5);
        print(_originalVolume);
        await RealVolume.setVolume(0.0, showUI: false, streamType: StreamType.RING);

        await _speech.listen(
          onResult: (result) {
            if (result.finalResult) {
              String recognizedText = result.recognizedWords;
              print("Recognized Text: $recognizedText");
              _onCommandRecognized?.call(recognizedText);
            }
          },
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 10),
          partialResults: false,
          cancelOnError: true,
        );
      } catch (e) {
        print("Error during speech recognition: $e");
        await initializeSpeech();
      } finally {
        // Restore original volume regardless of success/error
        // await RealVolume.setVolume(_originalVolume,
        //     streamType: StreamType.RING);
      }
      ;

      await Future.delayed(const Duration(seconds: 10));
      await RealVolume.setVolume(_originalVolume, streamType: StreamType.RING);
    }

    setState(() => _isListening = false);
    _flutterTts.speak("Stopped listening.");
  }

  void stopContinuousListening() {
    setState(() => _isListening = false);
    _speech.stop();
    _flutterTts.speak("Stopped listening.");
  }

  void setState(VoidCallback callback) => callback();
}
