import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/session.dart';
import '../models/chord_detection.dart';
import '../services/database_service.dart';
import '../widgets/chord_chip.dart';
import '../theme/app_theme.dart';

class SessionSummaryScreen extends StatefulWidget {
  final int sessionId;

  const SessionSummaryScreen({
    super.key,
    required this.sessionId,
  });

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  Session? _session;
  List<ChordDetection> _chordDetections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    setState(() => _isLoading = true);
    
    try {
      final databaseService = context.read<DatabaseService>();
      
      final session = await databaseService.getSession(widget.sessionId);
      final chordDetections = await databaseService.getChordDetectionsForSession(widget.sessionId);
      
      setState(() {
        _session = session;
        _chordDetections = chordDetections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Summary')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryPink),
        ),
      );
    }

    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Session Summary')),
        body: const Center(
          child: Text('Session not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_session!.displayName),
        actions: [
          IconButton(
            onPressed: _shareSession,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session overview
            _buildSessionOverview(),
            
            const SizedBox(height: 24),
            
            // Chord timeline
            _buildChordTimeline(),
            
            const SizedBox(height: 24),
            
            // Chord frequency chart
            _buildChordFrequencyChart(),
            
            const SizedBox(height: 24),
            
            // Roman numeral analysis
            if (_session!.detectedKey != null)
              _buildRomanNumeralAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryPink),
                const SizedBox(width: 8),
                Text(
                  'Session Overview',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Duration',
                    _session!.formattedDuration,
                    Icons.timer,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Total Chords',
                    '${_chordDetections.length}',
                    Icons.music_note,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Unique Chords',
                    '${_chordDetections.map((c) => c.chord).toSet().length}',
                    Icons.library_music,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Detected Key',
                    _session!.detectedKey ?? 'Unknown',
                    Icons.key,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryPink, size: 24),
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

  Widget _buildChordTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Text(
              'Chord Timeline',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        if (_chordDetections.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No chord detections in this session'),
              ),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _chordDetections.length,
              itemBuilder: (context, index) {
                final detection = _chordDetections[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChordChip(
                    chord: detection.chord,
                    confidence: detection.confidence,
                    roman: detection.roman,
                    showRoman: true,
                    onTap: () => _showChordDetails(detection),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildChordFrequencyChart() {
    if (_chordDetections.isEmpty) return const SizedBox.shrink();
    
    final chordCounts = <String, int>{};
    for (final detection in _chordDetections) {
      chordCounts[detection.chord] = (chordCounts[detection.chord] ?? 0) + 1;
    }
    
    final sortedChords = chordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bar_chart, color: AppTheme.primaryPurple),
            const SizedBox(width: 8),
            Text(
              'Chord Frequency',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: sortedChords.take(5).map((entry) {
                final percentage = (entry.value / _chordDetections.length * 100);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.getChordColor(entry.key),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRomanNumeralAnalysis() {
    final romanNumerals = _chordDetections
        .where((d) => d.roman != null)
        .map((d) => d.roman!)
        .toList();
    
    if (romanNumerals.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.music_note, color: AppTheme.primaryMint),
            const SizedBox(width: 8),
            Text(
              'Roman Numeral Analysis',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key: ${_session!.detectedKey}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Text(
                  'Progression: ${romanNumerals.join(' → ')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showChordDetails(ChordDetection detection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chord: ${detection.chord}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Timestamp', detection.formattedTimestamp),
              _buildDetailRow('Confidence', '${(detection.confidence * 100).toStringAsFixed(1)}%'),
              _buildDetailRow('Volume', detection.volume.toStringAsFixed(3)),
              if (detection.roman != null)
                _buildDetailRow('Roman Numeral', detection.roman!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  void _shareSession() {
    // TODO: Implement session sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppTheme.primaryPink,
      ),
    );
  }
}
