import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
class VoiceCommandHandler {
  final Function(String) showFeedback;
  final Function getDestination; // Updated to match _getDestination
  final Function getUserLocation; // Updated to match _getUserLocation
  final Function stopNavigation;
  final Function togglePrimaryView;
  final Function toggleCameraVisibility;

  VoiceCommandHandler({
    required this.showFeedback,
    required this.getDestination,
    required this.getUserLocation,
    required this.stopNavigation,
    required this.togglePrimaryView,
    required this.toggleCameraVisibility,
  });

  void processVoiceCommand(String recognizedText) {
    String text = _normalizeInput(recognizedText);
    // Check if the command starts with "pilot"
    if (!_isValidCommand(text)) {
      showFeedback("Please start your command with 'Path Pilot'.");
      return;
    }
    // Extract the actual command after "pilot"
    String command = _extractCommand(text);
    // Handle the command
    if (_handleTakeMeTo(command)) {
      return;
    } else if (_handleWhereAmI(command)) {
      return;
    } else if (_handleStopNavigation(command)) {
      return;
    } else if (_handleShowCamera(command)) {
      return;
    } else if (_handleHideCamera(command)) {
      return;
    } else if (_handleSwitchView(command)) {
      return;
    } else {
      // Fallback to AI processing for unrecognized commands
      // processVoiceCommandWithAI(command);
    }
  }



  Future<void> processVoiceCommandWithAI(String recognizedText) async {
    final String apiKey = 'AIzaSyAa7GXUzG6RdGlt8BwpAqUXYBxouCqzvIs';
    if (apiKey.isEmpty) {
      showFeedback("Google AI API key not found.");
      return;
    }

    final String apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey";

    // Prepare the prompt for the AI model
    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text":
                  "Interpret the following voice command and extract the user's intent: $recognizedText"
            }
          ]
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final String aiResponse =
            responseData["candidates"][0]["content"]["parts"][0]["text"];

        // Process the AI response
        _handleAIResponse(aiResponse);
      } else {
        print("Error calling Google AI Studio: ${response.statusCode} ${response.body}");
        showFeedback("An error occurred while processing your command.");
      }
    } catch (e) {
      print("Exception during AI processing: $e");
      showFeedback("An error occurred while processing your command.");
    }
  }
Future<void> processVoiceCommandWithAIStream(String recognizedText) async {
  final String apiKey = 'AIzaSyAa7GXUzG6RdGlt8BwpAqUXYBxouCqzvIs';
  if (apiKey.isEmpty) {
   showFeedback("Google AI API key not found.");
   return;
  }

  final String apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent?key=$apiKey";

  // Prepare the prompt for the AI model
  final Map<String, dynamic> requestBody = {
   "contents": [
    {
     "parts": [
      {
       "text":
           "Interpret the following voice command and respond incrementally: $recognizedText"
      }
     ]
    }
   ]
  };

  try {
   final request = http.Request('POST', Uri.parse(apiUrl));
   request.headers['Content-Type'] = 'application/json';
   request.body = jsonEncode(requestBody);
   final streamedResponse = await http.Client().send(request);
   if (streamedResponse.statusCode == 200) {
    streamedResponse.stream.transform(utf8.decoder).listen(
     (chunk) {
      // Each 'chunk' is a part of the streamed response
      try {
       final Map<String, dynamic> responseData = json.decode(chunk);
       if (responseData.containsKey("candidates") &&
           responseData["candidates"].isNotEmpty &&
           responseData["candidates"][0].containsKey("content") &&
           responseData["candidates"][0]["content"].containsKey("parts") &&
           responseData["candidates"][0]["content"]["parts"].isNotEmpty &&
           responseData["candidates"][0]["content"]["parts"][0].containsKey("text")) {
        final String aiResponseChunk = responseData["candidates"][0]["content"]["parts"][0]["text"];
        _handleAIStreamResponse(aiResponseChunk);
       } else if (responseData.containsKey("error")) {
        final String errorMessage = responseData["error"]["message"];
        showFeedback("AI Error: $errorMessage");
        print("AI Stream Error: $errorMessage");
       }
      } catch (e) {
       print("Error decoding JSON chunk: $e, chunk: $chunk");
       showFeedback("Error processing AI response.");
      }
     },
     onDone: () {
      print("AI stream completed.");
      showFeedback("AI response complete.");
     },
     onError: (error) {
      print("Error during AI stream: $error");
      showFeedback("An error occurred during AI processing.");
     },
    );
   } else {
    print("Error calling Google AI Studio (Stream): ${streamedResponse.statusCode} ${await streamedResponse.stream.bytesToString()}");
    showFeedback("An error occurred while processing your command.");
   }
  } catch (e) {
   print("Exception during AI stream processing: $e");
   showFeedback("An error occurred while processing your command.");
  }
 }

 

 void _handleAIStreamResponse(String chunk) {
  showFeedback("AI Streaming: $chunk"); // Update feedback with each chunk
  print("AI Chunk: $chunk");
  // You might want to build a more sophisticated UI to display
  // the streaming response progressively.
 }

 void _handleAIResponse(String response) {
  showFeedback("AI Response: $response");
  print(response);
}

  // Normalize input
  String _normalizeInput(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
  }

  // Validate the command
  bool _isValidCommand(String text) {
    return text.contains("pilot");
  }

  // Extract the command after "pilot"
  String _extractCommand(String text) {
    return text.replaceAll("pilot", "").trim();
  }

  // Handle "take me to" or "navigate to" commands
  bool _handleTakeMeTo(String command) {
    if (command.startsWith("take me to") || command.startsWith("navigate to")) {
      String destinationQuery = command
          .replaceAll("take me to", "")
          .replaceAll("navigate to", "")
          .trim();
      if (destinationQuery.isNotEmpty) {
        getDestination(destinationQuery); // Call the callback
        showFeedback("Taking you to $destinationQuery.");
        return true;
      } else {
        showFeedback("Please specify a destination after 'take me to'.");
        return true;
      }
    }
    return false;
  }

  // Handle "where am i" or similar commands
  bool _handleWhereAmI(String command) {
    if (command == "where am i" ||
        command == "tell me my location" ||
        command == "current location") {
      getUserLocation(); // Call the callback
      showFeedback("Getting your current location.");
      return true;
    }
    return false;
  }

  // Handle "stop navigation" or similar commands
  bool _handleStopNavigation(String command) {
    if (command == "stop navigation" || command == "cancel navigation") {
      stopNavigation();
      showFeedback("Navigation stopped.");
      return true;
    }
    return false;
  }

  // Handle "show camera" command
  bool _handleShowCamera(String command) {
    if (command == "show camera") {
      toggleCameraVisibility(true);
      showFeedback("Showing camera.");
      return true;
    }
    return false;
  }

  // Handle "hide camera" command
  bool _handleHideCamera(String command) {
    if (command == "hide camera") {
      toggleCameraVisibility(false);
      showFeedback("Hiding camera.");
      return true;
    }
    return false;
  }

  // Handle "switch view" or "toggle view" commands
  bool _handleSwitchView(String command) {
    if (command == "switch view" || command == "toggle view") {
      togglePrimaryView();
      showFeedback("Switching view.");
      return true;
    }
    return false;
  }
}