import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<void> main() async {
  // Replace with your actual API key
  const apiKey = 'AIzaSyAa7GXUzG6RdGlt8BwpAqUXYBxouCqzvIs';
  final endpoint =
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey';

  print('🚀 Connecting to Gemini WebSocket API...');
  final channel = WebSocketChannel.connect(Uri.parse(endpoint));
  // Debugging: Print connection state changes
  channel.ready
      .then((_) => print('🔗 WebSocket connected'))
      .catchError((e) => print('❌ Connection failed: $e'));
  // Create a broadcast stream that can be listened to multiple times

  final broadcastStream = channel.stream.asBroadcastStream();

  // Helper function to handle all possible data types
  String _decodeWebSocketData(dynamic data) {
    if (data is String) return data;
    if (data is Uint8List) return utf8.decode(data);
    if (data is List<int>) return utf8.decode(data);

    // Handle _Uint8ArrayView and other typed array views
    try {
      return utf8.decode(data as List<int>);
    } catch (e) {
      throw FormatException(
          'Unsupported WebSocket data type: ${data.runtimeType}');
    }
  }

  // Set up response handler
  // broadcastStream.listen(
  //   (data) {
  //     try {
  //       final responseString = _decodeWebSocketData(data);
  //       final response = json.decode(responseString);
  //       print(response);
  //       _handleResponse(response);
  //     } catch (e) {
  //       print('❌ Error processing response: $e');
  //     }
  //   },
  //   onError: (error) => print('❌ WebSocket error: $error'),
  //   onDone: () => print('🔌 Connection closed'),
  // );

  // Send setup message
  print('⚙️ Sending setup configuration...');
  channel.sink.add(json.encode({
    'setup': {
      'model': 'models/gemini-2.0-flash-exp',
      'generation_config': {
//         'system_instruction':   {
//             'role': 'system',
//             'parts': [
//               {
//                 'text': '''
// You are a helpful location navigation assistant. Follow these rules:
// 1. Never respond with markdown formatting
// 2. Always respond with valid JSON format
// 3. Your response must contain these 3 fields:
//    - "description": Brief description of the location (1-2 sentences)
//    - "directions": Clear directions to reach it (bullet points)
//    - "activities": List of 3-5 popular activities at this location

// Examples of good responses:
// {
//   "description": "Central Park is a large urban park in Manhattan known for its scenic landscapes and recreational facilities.",
//   "directions": [
//     "Take subway lines A, B, C, D, or 1 to 59th St-Columbus Circle station",
//     "Enter from any of the park's main entrances along 5th Ave or Central Park West"
//   ],
//   "activities": [
//     "Boat rental at The Loeb Boathouse",
//     "Visit the Central Park Zoo",
//     "See the Bethesda Terrace and Fountain",
//     "Walk or bike the 6-mile loop road"
//   ]
// }

// {
//   "description": "The Louvre Museum in Paris is the world's largest art museum and historic monument.",
//   "directions": [
//     "Take Metro line 1 to Palais-Royal-Musée du Louvre station",
//     "Follow signs to the Pyramid entrance"
//   ],
//   "activities": [
//     "See the Mona Lisa painting",
//     "View ancient Egyptian artifacts",
//     "Explore Napoleon III's apartments",
//     "Take a guided architecture tour"
//   ]
// }
// '''
//               }
//             ]
//           },
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

  // Wait for setup to complete using the broadcast stream
  await broadcastStream.firstWhere((data) {
    final responseString = _decodeWebSocketData(data);
    final response = json.decode(responseString);
    // return response['setupComplete'] == {};
    return true;
  });
  print('✅ Setup complete! Ready to chat');

  // Chat loop
  while (true) {
    stdout.write('\n💬 You: ');
    final input = stdin.readLineSync();
    if (input == null || input.toLowerCase() == 'exit') break;

    print('📤 Sending message... $input');
    channel.sink.add(json.encode({
      'client_content': {
        'turns': [
          // System prompt
        
          // User message
          {
            'role': 'user',
            'parts': [
              {'text': input}
            ]
          }
        ],
        'turn_complete': true
      }
    }));

    // Set up response handler

    bool turnComplete = false;
    String gresp = "";
    while (!turnComplete) {
      try {
        final response = await broadcastStream.firstWhere((data) {
          final decoded = json.decode(_decodeWebSocketData(data));
          return decoded['serverContent'] != null || decoded['error'] != null;
        }).timeout(Duration(seconds: 30));

        final decoded = json.decode(_decodeWebSocketData(response));

        gresp = "$gresp${_handleResponse(decoded)}";

        // Check if turn is complete
        if (decoded['serverContent']?['turnComplete'] == true) {
          turnComplete = true;
          print('\n🤖 Gemini: $gresp');
        }
      } catch (e) {
        print('\n❌ Error waiting for response: $e');
        turnComplete = true; // Move on to prevent infinite loop
      }
    }
  }
  // Clean up
  await channel.sink.close();
  print('👋 Goodbye!');
}

String _handleResponse(Map<String, dynamic> response) {
  // print('🔍 Handling response: ${response.keys.join(', ')}');

  if (response['setupComplete'] != null) {
    print('🎉 Setup completed successfully');
    return "";
  }

  if (response['serverContent'] != null) {
    final content = response['serverContent'];
    // print('📦 Server content: ${content.keys.join(', ')}');

    if (content['interrupted'] == true) {
      print('⏸️ Conversation interrupted');
      return "";
    }

    final modelTurn = content['modelTurn'];
    if (modelTurn != null) {
      // print('🔄 Model turn: ${modelTurn.keys.join(', ')}');
      final parts = modelTurn['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        for (final part in parts) {
          if (part['text'] != null) {
            // print('\n🤖 Gemini: ${part['text']}');
            return part['text'];
          } else if (part['inlineData'] != null) {
            print('🎧 Received audio data (${part['inlineData']['mimeType']})');
          }
        }
      }
    }

    if (content['turnComplete'] == true) {
      print('✅ Turn complete');
    }
  } else if (response['toolCall'] != null) {
    print('🛠️ Tool call requested: ${response['toolCall']}');
  } else {
    print('ℹ️ Unknown response type: $response');
  }

  return "";
}
