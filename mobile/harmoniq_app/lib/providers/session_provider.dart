import 'dart:async';
import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/chord_detection.dart';
import '../services/database_service.dart';
import '../services/websocket_service.dart';

enum SessionState {
  idle,
  connecting,
  recording,
  stopping,
  completed,
  error,
}

class SessionProvider extends ChangeNotifier {
  final DatabaseService _databaseService;
  final WebSocketService _webSocketService = WebSocketService();
  
  SessionProvider(this._databaseService) {
    _initializeWebSocket();
  }

  // Current session state
  SessionState _sessionState = SessionState.idle;
  Session? _currentSession;
  List<ChordDetection> _currentChordDetections = [];
  String? _currentKey;
  double _currentConfidenceThreshold = 0.7;
  
  // Real-time data
  String? _lastDetectedChord;
  double _lastConfidence = 0.0;
  double _lastVolume = 0.0;
  List<ChordDetection> _recentChords = [];
  
  // Session history
  List<Session> _recentSessions = [];
  
  StreamSubscription? _webSocketSubscription;

  // Getters
  SessionState get sessionState => _sessionState;
  Session? get currentSession => _currentSession;
  List<ChordDetection> get currentChordDetections => _currentChordDetections;
  String? get currentKey => _currentKey;
  double get currentConfidenceThreshold => _currentConfidenceThreshold;
  String? get lastDetectedChord => _lastDetectedChord;
  double get lastConfidence => _lastConfidence;
  double get lastVolume => _lastVolume;
  List<ChordDetection> get recentChords => _recentChords;
  List<Session> get recentSessions => _recentSessions;
  
  bool get isRecording => _sessionState == SessionState.recording;
  bool get canStartSession => _sessionState == SessionState.idle;
  bool get canStopSession => _sessionState == SessionState.recording;

  void _initializeWebSocket() {
    _webSocketSubscription = _webSocketService.messageStream.listen(
      _handleWebSocketMessage,
      onError: (error) {
        print('WebSocket error in provider: $error');
        _setSessionState(SessionState.error);
      },
    );
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    
    switch (type) {
      case WebSocketMessage.chordDetected:
        _handleChordDetected(ChordDetectedMessage.fromMap(message));
        break;
      case WebSocketMessage.keyDetected:
        _handleKeyDetected(KeyDetectedMessage.fromMap(message));
        break;
      case WebSocketMessage.sessionStarted:
        _handleSessionStarted(message);
        break;
      case WebSocketMessage.sessionEnded:
        _handleSessionEnded(message);
        break;
      case WebSocketMessage.sessionSummary:
        _handleSessionSummary(SessionSummaryMessage.fromMap(message));
        break;
      case WebSocketMessage.error:
        _handleError(message['message'] as String?);
        break;
      case WebSocketMessage.status:
        _handleStatus(message);
        break;
    }
  }

  void _handleChordDetected(ChordDetectedMessage message) {
    _lastDetectedChord = message.chord;
    _lastConfidence = message.confidence;
    _lastVolume = message.volume;
    
    // Create chord detection object
    final chordDetection = ChordDetection(
      sessionId: _currentSession?.id ?? 0,
      timestampMs: message.timestampMs,
      chord: message.chord,
      confidence: message.confidence,
      volume: message.volume,
      roman: message.roman,
    );
    
    // Add to current session
    _currentChordDetections.add(chordDetection);
    
    // Update recent chords (keep last 10)
    _recentChords.add(chordDetection);
    if (_recentChords.length > 10) {
      _recentChords.removeAt(0);
    }
    
    notifyListeners();
  }

  void _handleKeyDetected(KeyDetectedMessage message) {
    _currentKey = message.key;
    notifyListeners();
  }

  void _handleSessionStarted(Map<String, dynamic> message) {
    _setSessionState(SessionState.recording);
  }

  void _handleSessionEnded(Map<String, dynamic> message) {
    _setSessionState(SessionState.completed);
  }

  void _handleSessionSummary(SessionSummaryMessage message) {
    // Update current session with final data
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        totalDuration: message.duration,
        chordCount: message.chordCount,
        uniqueChords: message.uniqueChords,
        detectedKey: message.detectedKey,
      );
      
      // Save to database
      _saveCurrentSession();
    }
    
    _setSessionState(SessionState.completed);
  }

  void _handleError(String? errorMessage) {
    print('Session error: $errorMessage');
    _setSessionState(SessionState.error);
  }

  void _handleStatus(Map<String, dynamic> message) {
    // Handle status updates if needed
    print('Status: ${message['message']}');
  }

  void _setSessionState(SessionState state) {
    _sessionState = state;
    notifyListeners();
  }

  Future<bool> startSession({double? confidenceThreshold}) async {
    if (!canStartSession) return false;
    
    _setSessionState(SessionState.connecting);
    
    // Connect to WebSocket if not connected
    if (!_webSocketService.isConnected) {
      final connected = await _webSocketService.connect();
      if (!connected) {
        _setSessionState(SessionState.error);
        return false;
      }
    }
    
    // Create new session
    _currentSession = Session(
      startTime: DateTime.now(),
      confidenceThreshold: confidenceThreshold ?? _currentConfidenceThreshold,
    );
    
    // Clear previous data
    _currentChordDetections.clear();
    _recentChords.clear();
    _currentKey = null;
    _lastDetectedChord = null;
    _lastConfidence = 0.0;
    _lastVolume = 0.0;
    
    // Update threshold if provided
    if (confidenceThreshold != null) {
      _currentConfidenceThreshold = confidenceThreshold;
    }
    
    // Start session on backend
    _webSocketService.startSession(
      confidenceThreshold: _currentConfidenceThreshold,
    );
    
    return true;
  }

  Future<void> stopSession() async {
    if (!canStopSession) return;
    
    _setSessionState(SessionState.stopping);
    _webSocketService.stopSession();
  }

  void updateConfidenceThreshold(double threshold) {
    _currentConfidenceThreshold = threshold;
    if (isRecording) {
      _webSocketService.updateConfidenceThreshold(threshold);
    }
    notifyListeners();
  }

  Future<void> _saveCurrentSession() async {
    if (_currentSession == null) return;
    
    try {
      // Insert session
      final sessionId = await _databaseService.insertSession(_currentSession!);
      _currentSession = _currentSession!.copyWith(id: sessionId);
      
      // Insert chord detections
      for (final detection in _currentChordDetections) {
        await _databaseService.insertChordDetection(
          detection.copyWith(sessionId: sessionId),
        );
      }
      
      // Refresh recent sessions
      await loadRecentSessions();
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  Future<void> loadRecentSessions() async {
    try {
      _recentSessions = await _databaseService.getRecentSessions();
      notifyListeners();
    } catch (e) {
      print('Error loading recent sessions: $e');
    }
  }

  void resetSession() {
    _currentSession = null;
    _currentChordDetections.clear();
    _recentChords.clear();
    _currentKey = null;
    _lastDetectedChord = null;
    _lastConfidence = 0.0;
    _lastVolume = 0.0;
    _setSessionState(SessionState.idle);
  }

  @override
  void dispose() {
    _webSocketSubscription?.cancel();
    _webSocketService.dispose();
    super.dispose();
  }
}
