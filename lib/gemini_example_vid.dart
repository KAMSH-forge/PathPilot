// import 'dart:convert';
// import 'dart:io';
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
// import 'package:video_player/video_player.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// Future<void> main() async {
//   // Prompt user for video file path
//   stdout.write('🎥 Enter the path to the video file: ');
//   final videoPath = stdin.readLineSync();
//   if (videoPath == null || videoPath.isEmpty) {
//     print('❌ No video path provided. Exiting...');
//     return;
//   }

//   // Initialize video player
//   final videoPlayerController = VideoPlayerController.file(File(videoPath));
//   try {
//     await videoPlayerController.initialize();
//     print('🎬 Video initialized: ${videoPlayerController.value.duration}');
//   } catch (e) {
//     print('❌ Failed to initialize video: $e');
//     return;
//   }

//   // WebSocket setup
//   const apiKey = 'AIzaSyAa7GXUzG6RdGlt8BwpAqUXYBxouCqzvIs';
//   final endpoint =
//       'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey';

//   print('🚀 Connecting to Gemini WebSocket API...');
//   final channel = WebSocketChannel.connect(Uri.parse(endpoint));

//   channel.ready.then((_) => print('🔗 WebSocket connected'))
//       .catchError((e) => print('❌ Connection failed: $e'));

//   final broadcastStream = channel.stream.asBroadcastStream();

//   String _decodeWebSocketData(dynamic data) {
//     if (data is String) return data;
//     if (data is Uint8List) return utf8.decode(data);
//     if (data is List<int>) return utf8.decode(data);
//     return utf8.decode((data as dynamic).cast<int>());
//   }

//   // Setup for video analysis
//   print('⚙️ Configuring for video analysis...');
//   channel.sink.add(json.encode({
//     'setup': {
//       'model':'models/gemini-2.0-flash-exp',
//       'generation_config': {
//         'response_modalities': [''],
//         'temperature': 0.4,
//         'max_output_tokens': 2048
//       },
//       'system_instruction': {
//         'parts': [{
//           'text': '''
// You are a real-time video analysis assistant. Your task is to:
// 1. Analyze video frames as they arrive
// 2. Provide concise, factual descriptions
// 3. Focus on key objects, actions, and changes
// 4. Output plain text only (no markdown or formatting)
// 5. Respond immediately to each frame

// Example responses:
// - "Person sitting at a desk typing on a laptop"
// - "Outdoor scene with trees and blue sky"
// - "Whiteboard with mathematical equations"
// - "Empty room with a chair and table"
// '''
//         }]
//       },
//       'safety_settings': [
//         {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
//         {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
//         {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
//         {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'}
//       ]
//     }
//   }));

//   // Wait for setup completion
//   try {
//     await broadcastStream.firstWhere((data) {
//       final response = json.decode(_decodeWebSocketData(data));
//       return response['setupComplete'] != null;
//     }).timeout(Duration(seconds: 10));
//     print('✅ Setup complete! Ready to process video');
//   } catch (e) {
//     print('❌ Setup failed: $e');
//     await channel.sink.close();
//     await videoPlayerController.dispose();
//     return;
//   }

//   // Extract frames using FFmpeg
//   final ffmpeg = FlutterFFmpeg();
//   int frameCount = 0;

// Future<void> extractFrame(String videoPath, int timestamp) async {
//   final outputPath = 'frame_$frameCount.jpg';
//   final command =
//       '-i $videoPath -ss $timestamp -vframes 1 $outputPath';
//   final result = await ffmpeg.execute(command);

//   if (result == 0) {
//     print('\n📸 Captured frame $frameCount at timestamp $timestamp');

//     // Read the extracted frame
//     final file = File(outputPath);
//     final bytes = await file.readAsBytes();
//     final base64Image = base64Encode(bytes);

//     // Send frame to Gemini
//     channel.sink.add(json.encode({
//       'realtime_input': {
//         'media_chunks': [{
//           'mime_type': 'image/jpeg',
//           'data': base64Image
//         }]
//       }
//     }));

//     // Wait for response
//     try {
//       final response = await broadcastStream.firstWhere((data) {
//         final decoded = json.decode(_decodeWebSocketData(data));
//         return decoded['serverContent'] != null;
//       }).timeout(Duration(seconds: 5));

//       final content = json.decode(_decodeWebSocketData(response))['serverContent'];
//       if (content['modelTurn'] != null) {
//         final text = content['modelTurn']['parts'][0]['text'];
//         print('🔍 Analysis: $text');
//       }
//     } catch (e) {
//       print('❌ No response for frame $frameCount: $e');
//     }

//     // Clean up frame file
//     await file.delete();
//   } else {
//     print('❌ Error extracting frame $frameCount: $result');
//   }
// }
//   // Start capturing and analyzing frames
//   print('\n🎥 Starting video analysis (press Enter to stop)...');
//   final stopSignal = stdin.asBroadcastStream();

//   final timer = Timer.periodic(Duration(seconds: 1), (timer) async {
//     frameCount++;
//     final timestamp = frameCount * 1; // Capture every second
//     await extractFrame(videoPath!, timestamp);
//   });

//   // Wait for user to press Enter to stop
//   await stopSignal.firstWhere((data) => data == '\n');
//   timer.cancel();

//   // Clean up
//   await channel.sink.close();
//   await videoPlayerController.dispose();
//   print('\n👋 Video processing stopped');
// }