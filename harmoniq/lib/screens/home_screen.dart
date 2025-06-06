import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';

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

  final TextEditingController _serverUrlController =
      TextEditingController(text: 'ws://localhost:8000/ws');

  @override
  void initState() {
    super.initState();
    _loadRecentSessions();
    _setupWebSocketListener();
    _checkMicrophonePermission();
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
    final wsService = context.read<WebSocketService>();
    wsService.messageStream.listen((message) {
      if (mounted) {
        setState(() {
          final messageType = message['type'];

          switch (messageType) {
            case 'chord_detected':
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

              // Keep only last 20 chords
              if (_chordHistory.length > 20) {
                _chordHistory.removeAt(0);
              }
              break;

            case 'key_detected':
              _currentKey = message['key'] ?? '';
              break;

            case 'pattern_detected':
              _detectedPattern = message['pattern'] ?? '';
              break;

            case 'session_started':
              _sessionActive = true;
              _chordHistory.clear();
              break;

            case 'session_stopped':
              _sessionActive = false;
              break;

            case 'transcription':
              _lastTranscription = message['text'] ?? '';
              break;
          }

          _connectionStatus = wsService.isConnected ? 'Connected' : 'Disconnected';
          _isConnected = wsService.isConnected;
        });
      }
    });
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

            // Chord History
            if (_chordHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chord Progression',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
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

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }
}
