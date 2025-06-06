import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;
  String? _serverUrl;

  // Stream for listening to incoming messages
  Stream<Map<String, dynamic>> get messageStream => 
      _messageController?.stream ?? const Stream.empty();

  bool get isConnected => _isConnected;

  /// Connect to the WebSocket server
  Future<bool> connect(String serverUrl) async {
    try {
      // Disconnect any existing connection first
      await disconnect();

      _serverUrl = serverUrl;
      _messageController = StreamController<Map<String, dynamic>>.broadcast();

      print('Attempting to connect to: $serverUrl');

      // Validate URL format
      final uri = Uri.parse(serverUrl);
      if (!uri.scheme.startsWith('ws')) {
        throw Exception('Invalid WebSocket URL scheme. Use ws:// or wss://');
      }

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(uri);

      // Listen to incoming messages
      _channel!.stream.listen(
        (data) {
          try {
            print('🔔 Raw WebSocket data received: $data'); // Debug log
            final Map<String, dynamic> message = jsonDecode(data);
            print('🔔 Parsed WebSocket message: $message'); // Debug log

            // Special logging for chord_detected messages
            if (message['type'] == 'chord_detected') {
              print('🎵 CHORD DETECTED MESSAGE: ${message['chord']} (confidence: ${message['confidence']})');
            }

            _messageController?.add(message);
            print('🔔 Message added to stream controller'); // Debug log
          } catch (e) {
            print('❌ Error parsing WebSocket message: $e');
            print('❌ Raw data: $data');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
        },
      );

      _isConnected = true;
      print('Successfully connected to WebSocket server: $serverUrl');
      return true;
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Send a message to the server
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final String jsonMessage = jsonEncode(message);
        _channel!.sink.add(jsonMessage);
        print('Sent message: $jsonMessage');
      } catch (e) {
        print('Error sending message: $e');
      }
    } else {
      print('Cannot send message: WebSocket not connected');
    }
  }

  /// Send audio data for transcription
  void sendAudioData(List<int> audioData, {double? confidenceThreshold}) {
    final message = {
      'type': 'audio_data',
      'data': audioData,
      'confidence_threshold': confidenceThreshold ?? 0.7,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    sendMessage(message);
  }

  /// Send session start signal
  void startSession(String sessionId) {
    final message = {
      'type': 'session_start',
      'session_id': sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    sendMessage(message);
  }

  /// Send session end signal
  void endSession(String sessionId) {
    final message = {
      'type': 'session_end',
      'session_id': sessionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    sendMessage(message);
  }

  /// Reconnect to the server
  Future<bool> reconnect() async {
    if (_serverUrl != null) {
      await disconnect();
      await Future.delayed(const Duration(seconds: 1));
      return await connect(_serverUrl!);
    }
    return false;
  }

  /// Disconnect from the server
  Future<void> disconnect() async {
    try {
      await _channel?.sink.close(status.goingAway);
      await _messageController?.close();
      _isConnected = false;
      _channel = null;
      _messageController = null;
      print('Disconnected from WebSocket server');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
  }
}
