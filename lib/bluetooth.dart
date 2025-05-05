import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothSetupPage extends StatefulWidget {
  const BluetoothSetupPage({Key? key}) : super(key: key);

  @override
  _BluetoothSetupPageState createState() => _BluetoothSetupPageState();
}

class _BluetoothSetupPageState extends State<BluetoothSetupPage> {
  BluetoothConnection? _connection;
  bool isConnected = false;
  String statusMessage = 'Ready to connect';
  final String deviceAddress = '98:D3:31:F7:0C:94';
  final TextEditingController _textController = TextEditingController();
  final List<String> _receivedMessages = [];

  Future<void> _connectToDevice() async {
    try {
      setState(() {
        statusMessage = '🔍 Searching for devices...';
      });

      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();

      BluetoothDevice? device;
      try {
        device = devices.firstWhere((d) => d.address == deviceAddress);
      } catch (_) {
        device = null;
      }

      if (device == null) {
        setState(() {
          statusMessage = '❗ Device not found';
        });
        return;
      }

      setState(() {
        statusMessage = '🔌 Connecting to ${device!.name}...';
      });

      _connection = await BluetoothConnection.toAddress(device.address);
      setState(() {
        isConnected = true;
        statusMessage = '✅ Connected to ${device!.name}';
      });

      _connection!.input?.listen((Uint8List data) {
        final received = String.fromCharCodes(data);
        print('📥 Received data: $received');

        setState(() {
          _receivedMessages.add(received);
        });
      }).onDone(() {
        print('🔌 Disconnected by remote device');
        setState(() {
          isConnected = false;
          statusMessage = '🔌 Disconnected';
        });
      });
    } catch (error) {
      print('❌ Connection error: $error');
      setState(() {
        statusMessage = '❌ Connection failed: $error';
      });
    }
  }

  void _disconnect() {
    if (isConnected && _connection != null) {
      _connection!.dispose();
      _connection!.finish();
      setState(() {
        isConnected = false;
        statusMessage = '🔌 Disconnected manually';
      });
    }
  }

  void _sendMessage() {
    if (_connection != null && _textController.text.isNotEmpty) {
      final text = _textController.text + "\r\n";
      _connection!.output.add(Uint8List.fromList(text.codeUnits));
      _connection!.output.allSent;
      print('📤 Sent: $text');

      setState(() {
        _textController.clear();
        _receivedMessages.add('You: $text');
      });
    }
  }

  @override
  void dispose() {
    if (isConnected) {
      _disconnect();
    }
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bluetooth Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              statusMessage,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? null : _connectToDevice,
                    icon: const Icon(Icons.bluetooth),
                    label: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnected ? _disconnect : null,
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Enter message',
                border: OutlineInputBorder(),
              ),
              enabled: isConnected,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isConnected ? _sendMessage : null,
              icon: const Icon(Icons.send),
              label: const Text('Send'),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Received Messages:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _receivedMessages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_receivedMessages[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
