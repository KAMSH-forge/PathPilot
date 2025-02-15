import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;


class VoiceToTextPage extends StatefulWidget {
  @override
  _VoiceToTextAppState createState() => _VoiceToTextAppState();
}

class _VoiceToTextAppState extends State<VoiceToTextPage> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "Press the button and start speaking...";

  @override
  void initState() {
  super.initState();
    _speech = stt.SpeechToText();
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _text = result.recognizedWords;
          });
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Speech to Text")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_text, style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  child: Icon(_isListening ? Icons.mic_off : Icons.mic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
