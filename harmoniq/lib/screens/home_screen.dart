import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';
import 'session_analysis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isConnected = false;
  bool _isRecording = false;
  double _confidenceThreshold = 0.7;
  String _connectionStatus = 'Disconnected';
  String _lastTranscription = '';
  List<Map<String, dynamic>> _recentSessions = [];

  // Live chord progression data
  String _currentChord = '';
  double _currentConfidence = 0.0;
  double _currentVolume = 0.0;
  String _currentKey = '';
  String _currentRoman = '';
  String _detectedPattern = '';
  List<Map<String, dynamic>> _chordHistory = [];
  bool _sessionActive = false;
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  StreamSubscription? _audioStreamSubscription;
  StreamSubscription? _webSocketSubscription;

  // Enhanced session analytics
  Map<String, int> _chordFrequency = {};
  double _keyConfidence = 0.0;
  String _progressionPattern = '';
  List<String> _diatonicChords = [];
  int _totalChordsDetected = 0;
  bool _listenerSetup = false;

  // Demo mode
  bool _demoMode = false;
  Timer? _demoTimer;

  final TextEditingController _serverUrlController =
      TextEditingController(text: 'ws://10.0.0.228:8000/ws'); // Use your Mac's IP address

  @override
  void initState() {
    super.initState();
    _loadRecentSessions();
    _checkMicrophonePermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenerSetup) {
      print('🔧 Setting up WebSocket listener in didChangeDependencies');
      _setupWebSocketListener();
      _listenerSetup = true;
    } else {
      print('🔧 WebSocket listener already set up, skipping');
    }
  }

  Future<void> _checkMicrophonePermission() async {
    final audioService = context.read<AudioService>();
    if (!audioService.isInitialized) {
      final initialized = await audioService.initialize();
      if (!initialized && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission required for chord detection'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _setupWebSocketListener() {
    print('🔧 Setting up WebSocket listener...'); // Debug log
    final wsService = context.read<WebSocketService>();
    print('🔧 WebSocket service: $wsService'); // Debug log
    print('🔧 Message stream: ${wsService.messageStream}'); // Debug log

    // Test the stream is working
    print('🔧 Setting up message stream listener...');

    // Cancel existing subscription if any
    _webSocketSubscription?.cancel();

    // Set up new subscription
    _webSocketSubscription = wsService.messageStream.listen((message) {
      print('🔔 Received WebSocket message: $message'); // Debug log
      print('🔔 Message type: ${message['type']}'); // Debug log
      if (mounted) {
        setState(() {
          final messageType = message['type'];
          print('🔔 Processing message type: $messageType'); // Debug log

          switch (messageType) {
            case 'chord_detected':
              print('🎵 Processing chord_detected: ${message['chord']} (confidence: ${message['confidence']})'); // Debug log
              _currentChord = message['chord'] ?? '';
              _currentConfidence = (message['confidence'] ?? 0.0).toDouble();
              _currentVolume = (message['volume'] ?? 0.0).toDouble();
              _currentRoman = message['roman'] ?? '';

              // Add to chord history
              _chordHistory.add({
                'chord': _currentChord,
                'confidence': _currentConfidence,
                'volume': _currentVolume,
                'roman': _currentRoman,
                'timestamp': DateTime.now(),
              });

              // Update analytics
              _totalChordsDetected++;
              _chordFrequency[_currentChord] = (_chordFrequency[_currentChord] ?? 0) + 1;

              print('🎵 Updated UI: chord=$_currentChord, total=$_totalChordsDetected, history=${_chordHistory.length}'); // Debug log

              // Keep only last 20 chords for display
              if (_chordHistory.length > 20) {
                _chordHistory.removeAt(0);
              }
              break;

            case 'key_detected':
              _currentKey = message['key'] ?? '';
              _keyConfidence = (message['confidence'] ?? 0.0).toDouble();
              _diatonicChords = List<String>.from(message['diatonic_chords'] ?? []);
              break;

            case 'pattern_detected':
              _detectedPattern = message['pattern'] ?? '';
              _progressionPattern = message['progression'] ?? '';
              break;

            case 'session_started':
              _sessionActive = true;
              _chordHistory.clear();
              _chordFrequency.clear();
              _totalChordsDetected = 0;
              _keyConfidence = 0.0;
              _diatonicChords.clear();
              _progressionPattern = '';
              break;

            case 'session_stopped':
              _sessionActive = false;
              break;

            case 'transcription':
              _lastTranscription = message['text'] ?? '';
              break;

            case 'session_ended':
              print('🏁 Session ended: ${message['session_id']}');
              _sessionActive = false;
              break;

            case 'session_summary':
              print('📊 Session summary received with ${message['chord_count']} chords');
              // Process the session summary data
              final chordHistory = message['chord_history'] as List<dynamic>? ?? [];
              print('📊 Chord history from summary: ${chordHistory.length} chords');
              print('📊 Current _chordHistory length: ${_chordHistory.length}');

              // Always process session summary data (live messages might be missed)
              if (chordHistory.isNotEmpty) {
                print('🔄 Processing session summary data');
                setState(() {
                  // Clear existing data and use summary data
                  _chordHistory.clear();
                  _chordFrequency.clear();
                  _totalChordsDetected = 0;

                  for (final chordData in chordHistory) {
                    _chordHistory.add({
                      'chord': chordData['chord'] ?? '',
                      'confidence': (chordData['confidence'] ?? 0.0).toDouble(),
                      'volume': (chordData['volume'] ?? 0.0).toDouble(),
                      'roman': chordData['roman'] ?? '',
                      'timestamp': DateTime.now(),
                    });

                    final chord = chordData['chord'] ?? '';
                    _chordFrequency[chord] = (_chordFrequency[chord] ?? 0) + 1;
                    _totalChordsDetected++;
                  }

                  // Update current chord to the last one
                  if (chordHistory.isNotEmpty) {
                    final lastChord = chordHistory.last;
                    _currentChord = lastChord['chord'] ?? '';
                    _currentConfidence = (lastChord['confidence'] ?? 0.0).toDouble();
                    _currentVolume = (lastChord['volume'] ?? 0.0).toDouble();
                    _currentKey = message['detected_key'] ?? '';
                    _keyConfidence = 0.9; // High confidence since it's from analysis
                  }

                  print('🎵 Updated UI with ${_chordHistory.length} chords from summary');
                  print('🎵 Current chord: $_currentChord, Key: $_currentKey');
                });
              }
              break;

            case 'error':
              print('❌ Server error: ${message['message']}');
              break;

            default:
              print('❓ Unknown message type: $messageType');
              print('❓ Full message: $message');
              break;
          }

          _connectionStatus = wsService.isConnected ? 'Connected' : 'Disconnected';
          _isConnected = wsService.isConnected;
        });
      }
    }, onError: (error) {
      print('❌ WebSocket listener error: $error');
    }, onDone: () {
      print('🔚 WebSocket listener done');
    });

    print('🔧 WebSocket listener setup complete');
  }

  Future<void> _loadRecentSessions() async {
    final dbService = context.read<DatabaseService>();
    final sessions = await dbService.getAllSessions(limit: 5);
    if (mounted) {
      setState(() {
        _recentSessions = sessions;
      });
    }
  }

  Future<void> _connectToServer() async {
    final wsService = context.read<WebSocketService>();
    final success = await wsService.connect(_serverUrlController.text);
    
    if (mounted) {
      setState(() {
        _isConnected = success;
        _connectionStatus = success ? 'Connected' : 'Failed to connect';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Connected to server' : 'Failed to connect'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final wsService = context.read<WebSocketService>();
    await wsService.disconnect();
    
    if (mounted) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Disconnected';
      });
    }
  }

  Future<void> _toggleRecording() async {
    final wsService = context.read<WebSocketService>();
    final audioService = context.read<AudioService>();
    final dbService = context.read<DatabaseService>();

    if (!_isRecording) {
      // Start chord detection session
      if (_isConnected) {
        // Create session ID and start time
        _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
        _sessionStartTime = DateTime.now();

        // Send start message to WebSocket server
        wsService.sendMessage({
          'type': 'start_session',
          'confidence_threshold': _confidenceThreshold,
        });

        // Start audio recording with streaming
        final audioStarted = await audioService.startRecording(streamAudio: true);
        if (!audioStarted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to start audio recording'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Listen to audio stream and send to WebSocket
        _audioStreamSubscription = audioService.audioStream.listen((audioData) {
          if (_isRecording && _isConnected) {
            wsService.sendAudioData(audioData.toList());
          }
        });

        // Create session in database
        final sessionTitle = 'Session ${_sessionStartTime!.toString().substring(0, 19)}';
        await dbService.createSession(
          id: _currentSessionId!,
          title: sessionTitle,
          confidenceThreshold: _confidenceThreshold,
        );

        if (mounted) {
          setState(() {
            _isRecording = true;
            _sessionActive = true;
            _chordHistory.clear();
            _currentChord = '';
            _currentKey = '';
            _detectedPattern = '';
          });
        }

        print('Started session: $_currentSessionId');
      }
    } else {
      // Stop chord detection session
      if (_isConnected) {
        wsService.sendMessage({
          'type': 'stop_session',
        });
      }

      // Stop audio recording and streaming
      await audioService.stopRecording();
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Save session data to database
      if (_currentSessionId != null && _sessionStartTime != null) {
        final sessionDuration = DateTime.now().difference(_sessionStartTime!).inSeconds;

        // Create a summary of the chord progression
        final chordSummary = _chordHistory.map((chord) => chord['chord']).join(' - ');
        final description = _chordHistory.isNotEmpty
            ? 'Chords: $chordSummary${_currentKey.isNotEmpty ? ' | Key: $_currentKey' : ''}'
            : 'No chords detected';

        // Update session with final data
        await dbService.updateSession(_currentSessionId!, {
          'duration': sessionDuration,
          'description': description,
          'transcription': chordSummary,
        });

        // Save individual chord segments
        for (int i = 0; i < _chordHistory.length; i++) {
          final chord = _chordHistory[i];
          await dbService.addTranscriptionSegment(
            sessionId: _currentSessionId!,
            text: '${chord['chord']}${chord['roman'] != null ? ' (${chord['roman']})' : ''}',
            confidence: chord['confidence'] ?? 0.0,
            startTime: i * 2000, // Approximate 2 seconds per chord
            endTime: (i + 1) * 2000,
          );
        }

        print('Saved session: $_currentSessionId with ${_chordHistory.length} chords');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session saved with ${_chordHistory.length} chords detected'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _sessionActive = false;
          _currentSessionId = null;
          _sessionStartTime = null;
        });
        _loadRecentSessions(); // Refresh sessions list
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harmoniq'),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.wifi : Icons.wifi_off),
            onPressed: _isConnected ? _disconnect : _connectToServer,
            tooltip: _isConnected ? 'Disconnect' : 'Connect',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Server Connection',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _serverUrlController,
                      decoration: const InputDecoration(
                        labelText: 'WebSocket Server URL',
                        hintText: 'ws://localhost:8000/ws',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !_isConnected,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.circle : Icons.circle_outlined,
                          color: _isConnected ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(_connectionStatus),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Confidence Threshold Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidence Threshold: ${(_confidenceThreshold * 100).toInt()}%',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _confidenceThreshold,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      onChanged: (value) {
                        setState(() {
                          _confidenceThreshold = value;
                        });
                      },
                    ),
                    // Debug Test Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _simulateChordDetection(),
                            child: const Text('🧪 Test UI'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _testWebSocketConnection(),
                            child: const Text('🔗 Test WS'),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _toggleDemoMode(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _demoMode ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_demoMode ? '⏹️ Stop' : '🎭 Demo'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Live Chord Detection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Live Chord Detection',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        GestureDetector(
                          onTap: _isConnected ? _toggleRecording : null,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isRecording
                                  ? Colors.red
                                  : (_isConnected ? Theme.of(context).primaryColor : Colors.grey),
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Session Status
                    if (_sessionActive && _sessionStartTime != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          'Recording Session • Started: ${_sessionStartTime!.toString().substring(11, 19)} • ${_chordHistory.length} chords detected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Current Chord Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _sessionActive ? Colors.green.shade50 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _sessionActive ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _currentChord.isEmpty ? (_sessionActive ? 'Listening...' : 'No Chord') : _currentChord,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _sessionActive ? Colors.green.shade700 : Colors.grey.shade600,
                            ),
                          ),
                          if (_currentRoman.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Roman: $_currentRoman',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.blue.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (_currentConfidence > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Text('Confidence', style: Theme.of(context).textTheme.bodySmall),
                                    Text(
                                      '${(_currentConfidence * 100).toInt()}%',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text('Volume', style: Theme.of(context).textTheme.bodySmall),
                                    Container(
                                      width: 60,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: (_currentVolume * 10).clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Key and Pattern Info
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Key',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  _currentKey.isEmpty ? 'Detecting...' : _currentKey,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Pattern',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  _detectedPattern.isEmpty ? 'Listening...' : _detectedPattern,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (!_isConnected)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Connect to server first',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            // Enhanced Chord Progression Analysis
            if (_chordHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chord Progression',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_sessionActive)
                            ElevatedButton.icon(
                              onPressed: () => _showSessionAnalysis(),
                              icon: const Icon(Icons.analytics, size: 16),
                              label: const Text('Analyze'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Session Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatChip('Total', '$_totalChordsDetected', Colors.blue),
                          _buildStatChip('Unique', '${_chordFrequency.length}', Colors.green),
                          if (_currentKey.isNotEmpty)
                            _buildStatChip('Key', _currentKey, Colors.orange),
                          if (_keyConfidence > 0)
                            _buildStatChip('Confidence', '${(_keyConfidence * 100).toInt()}%', Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Chord Progression Timeline
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _chordHistory.length,
                          itemBuilder: (context, index) {
                            final chord = _chordHistory[index];
                            final isRecent = index >= _chordHistory.length - 3;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isRecent ? Colors.blue.shade100 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isRecent ? Colors.blue : Colors.grey,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    chord['chord'],
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isRecent ? Colors.blue.shade700 : Colors.grey.shade700,
                                    ),
                                  ),
                                  if (chord['roman'] != null && chord['roman'].isNotEmpty)
                                    Text(
                                      chord['roman'],
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.blue.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Top Chords
                      if (_chordFrequency.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Most Frequent Chords:',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: (_chordFrequency.entries.toList()
                                ..sort((a, b) => b.value.compareTo(a.value)))
                              .take(5)
                              .map((entry) => Chip(
                                    label: Text('${entry.key} (${entry.value})'),
                                    backgroundColor: Colors.green.shade100,
                                    labelStyle: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Last Transcription
            if (_lastTranscription.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Transcription',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(_lastTranscription),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),
            
            // Recent Sessions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Recent Sessions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _recentSessions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('No sessions yet')),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _recentSessions.length,
                            itemBuilder: (context, index) {
                              final session = _recentSessions[index];
                              return ListTile(
                                title: Text(session['title'] ?? 'Untitled'),
                                subtitle: Text(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    session['created_at'],
                                  ).toString().substring(0, 19),
                                ),
                                trailing: Icon(
                                  session['is_favorite'] == 1
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _simulateChordDetection() {
    // Simulate receiving a chord detection message
    final testChords = ['C', 'Am', 'F', 'G', 'Dm', 'Em'];
    final testRomans = ['I', 'vi', 'IV', 'V', 'ii', 'iii'];
    final randomIndex = DateTime.now().millisecond % testChords.length;

    setState(() {
      _sessionActive = true;
      _currentChord = testChords[randomIndex];
      _currentRoman = testRomans[randomIndex];
      _currentConfidence = 0.8 + (DateTime.now().millisecond % 20) / 100;
      _currentVolume = 0.5 + (DateTime.now().millisecond % 50) / 100;
      _currentKey = 'C major';
      _keyConfidence = 0.9;

      // Add to chord history
      _chordHistory.add({
        'chord': _currentChord,
        'confidence': _currentConfidence,
        'volume': _currentVolume,
        'roman': _currentRoman,
        'timestamp': DateTime.now(),
      });

      // Update analytics
      _totalChordsDetected++;
      _chordFrequency[_currentChord] = (_chordFrequency[_currentChord] ?? 0) + 1;

      // Keep only last 20 chords for display
      if (_chordHistory.length > 20) {
        _chordHistory.removeAt(0);
      }
    });

    print('🧪 Simulated chord: $_currentChord ($_currentRoman) - confidence: $_currentConfidence');
  }

  void _testWebSocketConnection() {
    final wsService = context.read<WebSocketService>();

    if (!wsService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ WebSocket not connected. Connect first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Test if the listener is working
    print('🔗 Testing WebSocket listener...');
    print('🔗 Listener setup flag: $_listenerSetup');

    // Send a test message
    wsService.sendMessage({
      'type': 'test_message',
      'test_data': 'Hello from Flutter!',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    print('🔗 Sent test WebSocket message');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Test message sent! Check logs for response.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _toggleDemoMode() {
    setState(() {
      _demoMode = !_demoMode;

      if (_demoMode) {
        // Start demo mode
        _sessionActive = true;
        _currentKey = 'C major';
        _keyConfidence = 0.9;
        _diatonicChords = ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'];

        // Start automatic chord simulation
        _demoTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
          _simulateChordDetection();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎭 Demo mode started! Watch the live chord detection!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Stop demo mode
        _demoTimer?.cancel();
        _demoTimer = null;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏹️ Demo mode stopped'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showSessionAnalysis() {
    if (_chordHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No chord data to analyze yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prepare session data for analysis
    final sessionData = {
      'total_chords': _totalChordsDetected,
      'unique_chords': _chordFrequency.length,
      'duration': _sessionStartTime != null
          ? DateTime.now().difference(_sessionStartTime!).inSeconds.toDouble()
          : 0.0,
      'detected_key': _currentKey,
      'key_confidence': _keyConfidence,
      'diatonic_chords': _diatonicChords,
      'chord_progression': _chordHistory.map((c) => c['chord'] as String).toList(),
      'roman_progression': _chordHistory.map((c) => c['roman'] as String? ?? '').toList(),
      'chord_frequency': _chordFrequency.map((key, value) => MapEntry(key, {
        'count': value,
        'percentage': (value / _totalChordsDetected * 100),
      })),
      'roman_analysis': <String, dynamic>{}, // Could be enhanced with more analysis
      'progression_pattern': _progressionPattern,
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SessionAnalysisScreen(sessionData: sessionData),
      ),
    );
  }

  @override
  void dispose() {
    _audioStreamSubscription?.cancel();
    _webSocketSubscription?.cancel();
    _demoTimer?.cancel();
    _serverUrlController.dispose();
    super.dispose();
  }
}
