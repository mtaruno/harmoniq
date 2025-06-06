import 'package:flutter/material.dart';

class SessionAnalysisScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;

  const SessionAnalysisScreen({
    super.key,
    required this.sessionData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Analysis'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Overview Card
            _buildSessionOverviewCard(context),
            const SizedBox(height: 16),
            
            // Key Detection Card
            _buildKeyDetectionCard(context),
            const SizedBox(height: 16),
            
            // Chord Progression Timeline
            _buildChordProgressionCard(context),
            const SizedBox(height: 16),
            
            // Statistics Card
            _buildStatisticsCard(context),
            const SizedBox(height: 16),
            
            // Roman Numeral Analysis
            _buildRomanNumeralCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionOverviewCard(BuildContext context) {
    final totalChords = sessionData['total_chords'] ?? 0;
    final uniqueChords = sessionData['unique_chords'] ?? 0;
    final duration = sessionData['duration'] ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Duration', '${duration.toStringAsFixed(1)}s'),
                _buildStatItem(context, 'Total Chords', '$totalChords'),
                _buildStatItem(context, 'Unique Chords', '$uniqueChords'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyDetectionCard(BuildContext context) {
    final detectedKey = sessionData['detected_key'] ?? 'Unknown';
    final keyConfidence = sessionData['key_confidence'] ?? 0.0;
    final diatonicChords = sessionData['diatonic_chords'] as List<String>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Key Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    detectedKey,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(keyConfidence * 100).toInt()}% confidence',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (diatonicChords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Diatonic Chords:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: diatonicChords.map((chord) => Chip(
                  label: Text(chord),
                  backgroundColor: Colors.green.shade100,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChordProgressionCard(BuildContext context) {
    final chordProgression = sessionData['chord_progression'] as List<String>? ?? [];
    final romanProgression = sessionData['roman_progression'] as List<String>? ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chord Progression',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (chordProgression.isNotEmpty) ...[
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: chordProgression.length,
                  itemBuilder: (context, index) {
                    final chord = chordProgression[index];
                    final roman = index < romanProgression.length ? romanProgression[index] : '';
                    
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            chord,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          if (roman.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              roman,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.purple.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Text('No chord progression detected'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(BuildContext context) {
    final chordFrequency = sessionData['chord_frequency'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chord Usage Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (chordFrequency.isNotEmpty) ...[
              ...chordFrequency.entries.take(5).map((entry) {
                final chord = entry.key;
                final count = entry.value['count'] ?? 0;
                final percentage = entry.value['percentage'] ?? 0.0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          chord,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count (${percentage.toStringAsFixed(1)}%)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              const Text('No statistics available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRomanNumeralCard(BuildContext context) {
    final romanAnalysis = sessionData['roman_analysis'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roman Numeral Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (romanAnalysis.isNotEmpty) ...[
              ...romanAnalysis.entries.map((entry) {
                final roman = entry.key;
                final chord = entry.value['chord'] ?? '';
                final function = entry.value['function'] ?? '';
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roman,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$chord ($function)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ] else ...[
              const Text('No roman numeral analysis available'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
