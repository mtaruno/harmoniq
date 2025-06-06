import 'dart:async';
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
    _webSocketSubscription = wsService.messageStream.listen((message) async {
      print('📥 Received message: $message');
      
      final messageType = message['type'] as String? ?? 'unknown';
      print('🔔 Message type: $messageType'); // Debug log
      
      if (mounted) {
        setState(() {
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

        // Handle session summary outside of setState
        if (messageType == 'session_summary') {
          try {
            await _handleSessionSummary(message);
            if (mounted) {
              setState(() {
                _sessionActive = false;
              });
            }
          } catch (e) {
            print('Error handling session summary: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error handling session summary: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      }
    }, onError: (error) {
      print('❌ WebSocket listener error: $error');
    }, onDone: () {
      print('🔚 WebSocket listener done');
    });

    print('🔧 WebSocket listener setup complete');
  }

  Future<void> _loadRecentSessions() async {
    try {
      final dbService = context.read<DatabaseService>();
      final sessions = await dbService.getAllSessions(limit: 5);
      setState(() {
        _recentSessions = sessions;
      });
    } catch (e) {
      print('Error loading recent sessions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading sessions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _startRecording() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ WebSocket not connected. Connect first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final wsService = context.read<WebSocketService>();
    final audioService = context.read<AudioService>();
    final dbService = context.read<DatabaseService>();

    try {
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

      // Start WebSocket session
      wsService.sendMessage({
        'type': 'start_session',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Create new session in database
      _currentSessionId = await dbService.createSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Session ${DateTime.now().toString()}',
        description: 'Recording session',
      );
      _sessionStartTime = DateTime.now();

      setState(() {
        _isRecording = true;
        _sessionActive = true;
        _chordHistory.clear();
        _chordFrequency.clear();
        _totalChordsDetected = 0;
        _keyConfidence = 0.0;
        _diatonicChords.clear();
        _progressionPattern = '';
      });

      // Listen for WebSocket messages
      _webSocketSubscription = wsService.messageStream.listen((message) async {
        print('📥 Received message: $message');
        
        final messageType = message['type'] as String? ?? 'unknown';
        print('🔔 Message type: $messageType'); // Debug log
        
        if (mounted) {
          setState(() {
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
                // Handle session summary asynchronously
                _handleSessionSummary(message).then((_) {
                  // Update UI state after handling
                  if (mounted) {
                    setState(() {
                      _sessionActive = false;
                    });
                  }
                }).catchError((error) {
                  print('Error handling session summary: $error');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error handling session summary: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                });
                break;
            }

            _connectionStatus = wsService.isConnected ? 'Connected' : 'Disconnected';
            _isConnected = wsService.isConnected;
          });
        }
      });

      // Listen for audio stream
      _audioStreamSubscription = audioService.audioStream.listen((data) {
        if (_isRecording && _isConnected) {
          wsService.sendMessage({
            'type': 'audio_data',
            'data': data,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });

    } catch (e) {
      print('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final wsService = context.read<WebSocketService>();
    final audioService = context.read<AudioService>();

    try {
      // Stop WebSocket session
      wsService.sendMessage({
        'type': 'stop_session',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Stop audio recording
      await audioService.stopRecording();
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;

      // Wait for session summary before saving
      bool summaryReceived = false;
      final summarySubscription = wsService.messageStream.listen((message) {
        if (message['type'] == 'session_summary') {
          summaryReceived = true;
        }
      });

      // Wait for summary with timeout
      int attempts = 0;
      while (!summaryReceived && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      await summarySubscription.cancel();

      if (mounted) {
        setState(() {
          _isRecording = false;
          _sessionActive = false;
          _currentSessionId = null;
          _sessionStartTime = null;
        });
        _loadRecentSessions(); // Refresh sessions list
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error stopping recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
            icon: const Icon(Icons.analytics),
            onPressed: _showSessionAnalysis,
            tooltip: 'Show Session Analysis',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(_connectionStatus),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _serverUrlController,
                      decoration: const InputDecoration(
                        labelText: 'WebSocket Server URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _connectToServer,
                      child: Text(_isConnected ? 'Disconnect' : 'Connect'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recording Controls Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording Controls',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRecording ? _stopRecording : _startRecording,
                          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                          label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Live Chord Detection Card
            if (_sessionActive) Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Chord Detection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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

                    const SizedBox(height: 16),

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
                                  _progressionPattern.isEmpty ? 'Listening...' : _progressionPattern,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Chord History Card
            if (_chordHistory.isNotEmpty) Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Chords',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
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
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recent Sessions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Sessions',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadRecentSessions,
                          tooltip: 'Refresh Sessions',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_recentSessions.isEmpty)
                      const Center(
                        child: Text('No recent sessions'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentSessions.length,
                        itemBuilder: (context, index) {
                          final session = _recentSessions[index];
                          return ListTile(
                            title: Text(session['title'] ?? 'Untitled Session'),
                            subtitle: Text(session['description'] ?? 'No description'),
                            trailing: Text(
                              '${session['duration'] ?? 0}s',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () async {
                              if (session['id'] != null) {
                                await _showSessionAnalysis(session['id']);
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Debug Controls Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Controls',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Future<void> _showSessionAnalysis([String? sessionId]) async {
    try {
      final dbService = context.read<DatabaseService>();
      
      if (sessionId == null) {
        // Show a dialog to select a session
        final sessions = await dbService.getAllSessions();
        if (!mounted) return;
        
        final selectedSession = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select a Session'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return ListTile(
                    title: Text(session['title'] ?? 'Untitled Session'),
                    subtitle: Text(session['description'] ?? 'No description'),
                    onTap: () => Navigator.of(context).pop(session),
                  );
                },
              ),
            ),
          ),
        );
        
        if (selectedSession == null) return;
        sessionId = selectedSession['id'];
      }

      final session = await dbService.getSession(sessionId!);
      final segments = await dbService.getTranscriptionSegments(sessionId!);

      if (session == null) {
        throw Exception('Session not found');
      }

      // Convert segments to chord detections format
      final chordDetections = segments.map((segment) {
        final text = segment['text'].toString();
        final chord = text.split(' ')[0]; // Get chord part before (roman)
        final roman = text.contains('(') 
            ? text.split('(')[1].split(')')[0] 
            : null;

        return {
          'chord': chord,
          'roman': roman,
          'confidence': segment['confidence'] ?? 0.0,
          'timestamp': segment['start_time'] ?? 0,
        };
      }).toList();

      // Calculate chord frequency
      final chordFrequency = <String, int>{};
      for (final detection in chordDetections) {
        final chord = detection['chord'].toString();
        chordFrequency[chord] = (chordFrequency[chord] ?? 0) + 1;
      }

      // Prepare session data for analysis
      final sessionData = {
        'total_chords': chordDetections.length,
        'unique_chords': chordFrequency.length,
        'duration': session['duration'] ?? 0.0,
        'detected_key': session['description']?.toString().split('| Key: ').last ?? 'Unknown',
        'key_confidence': 0.9, // High confidence since it's from analysis
        'diatonic_chords': [], // Could be populated from backend
        'chord_progression': chordDetections.map((c) => c['chord'].toString()).toList(),
        'roman_progression': chordDetections.map((c) => c['roman']?.toString() ?? '').toList(),
        'chord_frequency': chordFrequency.map((k, v) => MapEntry(k, {
          'count': v,
          'percentage': (v / chordDetections.length * 100),
        })),
        'roman_analysis': {}, // Could be populated from backend
        'progression_pattern': '', // Could be populated from backend
      };

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SessionAnalysisScreen(
              sessionData: sessionData,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error showing session analysis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error showing session analysis: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSessionSummary(Map<String, dynamic> message) async {
    print('📊 Session summary received with ${message['chord_count']} chords');
    // Process the session summary data
    final chordHistory = message['chord_history'] as List<dynamic>? ?? [];
    print('📊 Chord history from summary: ${chordHistory.length} chords');
    print('📊 Current _chordHistory length: ${_chordHistory.length}');

    // Always process session summary data (live messages might be missed)
    if (_currentSessionId != null && _sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!).inSeconds;
      final dbService = context.read<DatabaseService>();

      // Create a summary of the chord progression
      final chordSummary = chordHistory.isNotEmpty 
          ? chordHistory.map((chord) => chord['chord']).join(' - ')
          : 'No chords detected';
      final description = 'Chords: $chordSummary${_currentKey.isNotEmpty ? ' | Key: $_currentKey' : ''}';

      try {
        // Update session with final data
        await dbService.updateSession(_currentSessionId!, {
          'duration': sessionDuration,
          'description': description,
          'transcription': chordSummary,
        });

        // Save individual chord segments
        for (int i = 0; i < chordHistory.length; i++) {
          final chord = chordHistory[i];
          await dbService.addTranscriptionSegment(
            sessionId: _currentSessionId!,
            text: '${chord['chord']}${chord['roman'] != null ? ' (${chord['roman']})' : ''}',
            confidence: chord['confidence'] ?? 0.0,
            startTime: i * 2000, // Approximate 2 seconds per chord
            endTime: (i + 1) * 2000,
          );
        }

        print('Saved session: $_currentSessionId with ${chordHistory.length} chords');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Session saved with ${chordHistory.length} chords detected'),
              backgroundColor: Colors.green,
            ),
          );

          // Prepare session data for analysis
          final sessionData = {
            'total_chords': chordHistory.length,
            'unique_chords': message['unique_chords'] ?? 0,
            'duration': sessionDuration.toDouble(),
            'detected_key': message['detected_key'] ?? '',
            'key_confidence': 0.9, // High confidence since it's from analysis
            'diatonic_chords': [], // Could be populated from backend
            'chord_progression': chordHistory.map((c) => c['chord'].toString()).toList(),
            'roman_progression': chordHistory.map((c) => c['roman']?.toString() ?? '').toList(),
            'chord_frequency': Map<String, dynamic>.from(message['analysis']?['chord_frequency'] as Map? ?? {}),
            'roman_analysis': Map<String, dynamic>.from(message['analysis']?['roman_analysis'] as Map? ?? {}),
            'progression_pattern': (message['analysis']?['patterns'] as List?)?.isNotEmpty == true
                ? message['analysis']['patterns'][0].toString()
                : '',
          };

          // Show analysis screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SessionAnalysisScreen(sessionData: sessionData),
            ),
          );
        }
      } catch (e) {
        print('Error saving session data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving session data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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
