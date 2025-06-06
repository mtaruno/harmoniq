import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;
  String _serverUrl = 'ws://localhost:8000/ws';

  Stream<Map<String, dynamic>> get messageStream => 
      _messageController?.stream ?? const Stream.empty();

  bool get isConnected => _isConnected;

  Future<bool> connect() async {
    try {
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      
      // Listen to messages
      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _messageController?.add(data);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          _messageController?.addError(error);
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          _messageController?.close();
        },
      );

      _isConnected = true;
      return true;
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _isConnected = false;
      return false;
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    }
  }

  void startSession({double confidenceThreshold = 0.7}) {
    sendMessage({
      'type': 'start_session',
      'confidence_threshold': confidenceThreshold,
    });
  }

  void stopSession() {
    sendMessage({
      'type': 'stop_session',
    });
  }

  void updateConfidenceThreshold(double threshold) {
    sendMessage({
      'type': 'update_threshold',
      'confidence_threshold': threshold,
    });
  }

  void disconnect() {
    _isConnected = false;
    _channel?.sink.close(status.goingAway);
    _messageController?.close();
    _channel = null;
    _messageController = null;
  }

  void dispose() {
    disconnect();
  }
}

// Message types that can be received from the backend
class WebSocketMessage {
  static const String chordDetected = 'chord_detected';
  static const String keyDetected = 'key_detected';
  static const String sessionStarted = 'session_started';
  static const String sessionEnded = 'session_ended';
  static const String sessionSummary = 'session_summary';
  static const String error = 'error';
  static const String status = 'status';
}

// Data classes for different message types
class ChordDetectedMessage {
  final String chord;
  final double confidence;
  final double volume;
  final int timestampMs;
  final String? roman;

  ChordDetectedMessage({
    required this.chord,
    required this.confidence,
    required this.volume,
    required this.timestampMs,
    this.roman,
  });

  factory ChordDetectedMessage.fromMap(Map<String, dynamic> map) {
    return ChordDetectedMessage(
      chord: map['chord'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
      volume: map['volume']?.toDouble() ?? 0.0,
      timestampMs: map['timestamp_ms']?.toInt() ?? 0,
      roman: map['roman'],
    );
  }
}

class KeyDetectedMessage {
  final String key;
  final double confidence;

  KeyDetectedMessage({
    required this.key,
    required this.confidence,
  });

  factory KeyDetectedMessage.fromMap(Map<String, dynamic> map) {
    return KeyDetectedMessage(
      key: map['key'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
    );
  }
}

class SessionSummaryMessage {
  final int sessionId;
  final double duration;
  final int chordCount;
  final int uniqueChords;
  final String? detectedKey;
  final List<Map<String, dynamic>> chordHistory;
  final Map<String, dynamic> analysis;

  SessionSummaryMessage({
    required this.sessionId,
    required this.duration,
    required this.chordCount,
    required this.uniqueChords,
    this.detectedKey,
    required this.chordHistory,
    required this.analysis,
  });

  factory SessionSummaryMessage.fromMap(Map<String, dynamic> map) {
    return SessionSummaryMessage(
      sessionId: map['session_id']?.toInt() ?? 0,
      duration: map['duration']?.toDouble() ?? 0.0,
      chordCount: map['chord_count']?.toInt() ?? 0,
      uniqueChords: map['unique_chords']?.toInt() ?? 0,
      detectedKey: map['detected_key'],
      chordHistory: List<Map<String, dynamic>>.from(map['chord_history'] ?? []),
      analysis: Map<String, dynamic>.from(map['analysis'] ?? {}),
    );
  }
}
