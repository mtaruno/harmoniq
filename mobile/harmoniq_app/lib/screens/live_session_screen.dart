import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/session_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chord_chip.dart';
import '../widgets/confidence_slider.dart';
import '../widgets/volume_indicator.dart';
import '../theme/app_theme.dart';

class LiveSessionScreen extends StatefulWidget {
  const LiveSessionScreen({super.key});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> 
    with TickerProviderStateMixin {
  late AnimationController _recordingController;
  late Animation<double> _recordingAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Recording indicator animation
    _recordingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _recordingAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _recordingController,
      curve: Curves.easeInOut,
    ));
    
    _recordingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _recordingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Live Session'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showStopConfirmation(context),
        ),
        actions: [
          Consumer<SessionProvider>(
            builder: (context, sessionProvider, child) {
              return AnimatedBuilder(
                animation: _recordingAnimation,
                builder: (context, child) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: sessionProvider.isRecording 
                                ? Colors.red.withOpacity(_recordingAnimation.value)
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sessionProvider.isRecording ? 'Recording' : 'Stopped',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<SessionProvider>(
        builder: (context, sessionProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status section
                _buildStatusSection(context, sessionProvider),
                
                const SizedBox(height: 24),
                
                // Confidence threshold slider
                _buildConfidenceSection(context, sessionProvider),
                
                const SizedBox(height: 24),
                
                // Current chord display
                _buildCurrentChordSection(context, sessionProvider),
                
                const SizedBox(height: 24),
                
                // Recent chords timeline
                _buildRecentChordsSection(context, sessionProvider),
                
                const SizedBox(height: 24),
                
                // Session stats
                _buildSessionStatsSection(context, sessionProvider),
                
                const SizedBox(height: 40),
                
                // Stop button
                _buildStopButton(context, sessionProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(BuildContext context, SessionProvider sessionProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.mic, color: AppTheme.primaryPink),
                const SizedBox(width: 8),
                Text(
                  'Microphone Status',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                VolumeIndicator(volume: sessionProvider.lastVolume),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.key, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Detected Key:',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLavender.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sessionProvider.currentKey ?? 'Detecting...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceSection(BuildContext context, SessionProvider sessionProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: AppTheme.primaryPurple),
                const SizedBox(width: 8),
                Text(
                  'Confidence Threshold',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ConfidenceSlider(
              value: sessionProvider.currentConfidenceThreshold,
              onChanged: (value) {
                sessionProvider.updateConfidenceThreshold(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentChordSection(BuildContext context, SessionProvider sessionProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Current Chord',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            
            const SizedBox(height: 16),
            
            if (sessionProvider.lastDetectedChord != null)
              ChordChip(
                chord: sessionProvider.lastDetectedChord!,
                confidence: sessionProvider.lastConfidence,
                isLarge: true,
                showConfidence: true,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Listening...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentChordsSection(BuildContext context, SessionProvider sessionProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Chords',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        
        const SizedBox(height: 12),
        
        if (sessionProvider.recentChords.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No chords detected yet\nStart playing to see them here!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sessionProvider.recentChords.length,
              itemBuilder: (context, index) {
                final chord = sessionProvider.recentChords[index];
                final isAboveThreshold = chord.confidence >= 
                    sessionProvider.currentConfidenceThreshold;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Opacity(
                    opacity: isAboveThreshold ? 1.0 : 0.4,
                    child: ChordChip(
                      chord: chord.chord,
                      confidence: chord.confidence,
                      roman: chord.roman,
                      showRoman: context.read<SettingsProvider>().showRomanNumerals,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSessionStatsSection(BuildContext context, SessionProvider sessionProvider) {
    final session = sessionProvider.currentSession;
    final duration = session != null 
        ? DateTime.now().difference(session.startTime)
        : Duration.zero;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              'Duration',
              '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
              Icons.timer,
            ),
            _buildStatItem(
              context,
              'Chords',
              '${sessionProvider.currentChordDetections.length}',
              Icons.music_note,
            ),
            _buildStatItem(
              context,
              'Unique',
              '${sessionProvider.currentChordDetections.map((c) => c.chord).toSet().length}',
              Icons.library_music,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryPink),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStopButton(BuildContext context, SessionProvider sessionProvider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: sessionProvider.canStopSession 
            ? () => _stopSession(context)
            : null,
        icon: const Icon(Icons.stop),
        label: const Text('Stop Session'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _showStopConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Stop Session?'),
          content: const Text('Are you sure you want to stop the current session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _stopSession(context);
              },
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _stopSession(BuildContext context) async {
    final sessionProvider = context.read<SessionProvider>();
    await sessionProvider.stopSession();
    
    if (mounted) {
      context.pop();
    }
  }
}
