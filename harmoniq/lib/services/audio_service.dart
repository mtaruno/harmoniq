import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audio_session/audio_session.dart';
import 'package:path/path.dart' as path;

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isInitialized = false;
  StreamController<Uint8List>? _audioStreamController;
  Timer? _recordingTimer;

  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;

  /// Stream for real-time audio data
  Stream<Uint8List> get audioStream => 
      _audioStreamController?.stream ?? const Stream.empty();

  /// Initialize the audio service
  Future<bool> initialize() async {
    try {
      // Configure audio session
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.record,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.measurement,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Check permissions
      if (await _recorder.hasPermission()) {
        _isInitialized = true;
        print('Audio service initialized successfully');
        return true;
      } else {
        print('Audio recording permission denied');
        return false;
      }
    } catch (e) {
      print('Error initializing audio service: $e');
      return false;
    }
  }

  /// Start recording audio
  Future<bool> startRecording({
    String? outputPath,
    bool streamAudio = false,
  }) async {
    if (!_isInitialized) {
      print('Audio service not initialized');
      return false;
    }

    if (_isRecording) {
      print('Already recording');
      return false;
    }

    try {
      // Set up audio stream if needed
      if (streamAudio) {
        _audioStreamController = StreamController<Uint8List>.broadcast();
      }

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000, // 16kHz for speech recognition
        bitRate: 128000,
        numChannels: 1, // Mono
      );

      // Start recording
      if (outputPath != null) {
        await _recorder.start(config, path: outputPath);
      } else {
        // For streaming, we'll use a temporary file approach
        final tempDir = Directory.systemTemp;
        final tempPath = path.join(tempDir.path, 'temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav');
        await _recorder.start(config, path: tempPath);
      }

      _isRecording = true;

      // If streaming, set up periodic reading
      if (streamAudio && _audioStreamController != null) {
        _startAudioStreaming();
      }

      print('Started recording audio');
      return true;
    } catch (e) {
      print('Error starting recording: $e');
      return false;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    if (!_isRecording) {
      print('Not currently recording');
      return null;
    }

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      
      // Stop streaming
      _recordingTimer?.cancel();
      await _audioStreamController?.close();
      _audioStreamController = null;

      print('Stopped recording audio: $path');
      return path;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_isRecording) {
      try {
        await _recorder.pause();
        _recordingTimer?.cancel();
        print('Paused recording');
      } catch (e) {
        print('Error pausing recording: $e');
      }
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_isRecording) {
      try {
        await _recorder.resume();
        if (_audioStreamController != null) {
          _startAudioStreaming();
        }
        print('Resumed recording');
      } catch (e) {
        print('Error resuming recording: $e');
      }
    }
  }

  /// Get current amplitude (for visualizations)
  Future<double> getAmplitude() async {
    try {
      final amplitude = await _recorder.getAmplitude();
      return amplitude.current;
    } catch (e) {
      print('Error getting amplitude: $e');
      return 0.0;
    }
  }

  /// Start streaming audio data
  void _startAudioStreaming() {
    // This is a simplified approach - in a real implementation,
    // you might want to use a more sophisticated streaming method
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!_isRecording || _audioStreamController == null) {
        timer.cancel();
        return;
      }

      // In a real implementation, you would read audio chunks here
      // For now, this is a placeholder for the streaming functionality
      // The actual implementation would depend on the specific requirements
      // and the audio processing pipeline
    });
  }

  /// Read audio file as bytes
  Future<Uint8List?> readAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error reading audio file: $e');
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    stopRecording();
    _recorder.dispose();
    _recordingTimer?.cancel();
    _audioStreamController?.close();
  }
}
