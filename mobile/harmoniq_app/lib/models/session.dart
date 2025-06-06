class Session {
  final int? id;
  final String? name;
  final DateTime startTime;
  final DateTime? endTime;
  final String? detectedKey;
  final double confidenceThreshold;
  final double? totalDuration;
  final int? chordCount;
  final int? uniqueChords;
  final String? notes;

  Session({
    this.id,
    this.name,
    required this.startTime,
    this.endTime,
    this.detectedKey,
    this.confidenceThreshold = 0.7,
    this.totalDuration,
    this.chordCount,
    this.uniqueChords,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'detected_key': detectedKey,
      'confidence_threshold': confidenceThreshold,
      'total_duration': totalDuration,
      'chord_count': chordCount,
      'unique_chords': uniqueChords,
      'notes': notes,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id']?.toInt(),
      name: map['name'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      detectedKey: map['detected_key'],
      confidenceThreshold: map['confidence_threshold']?.toDouble() ?? 0.7,
      totalDuration: map['total_duration']?.toDouble(),
      chordCount: map['chord_count']?.toInt(),
      uniqueChords: map['unique_chords']?.toInt(),
      notes: map['notes'],
    );
  }

  Session copyWith({
    int? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    String? detectedKey,
    double? confidenceThreshold,
    double? totalDuration,
    int? chordCount,
    int? uniqueChords,
    String? notes,
  }) {
    return Session(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      detectedKey: detectedKey ?? this.detectedKey,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      totalDuration: totalDuration ?? this.totalDuration,
      chordCount: chordCount ?? this.chordCount,
      uniqueChords: uniqueChords ?? this.uniqueChords,
      notes: notes ?? this.notes,
    );
  }

  Duration? get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return null;
  }

  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'In progress...';
    
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return 'Session ${startTime.day}/${startTime.month}';
  }
}
