class ChordDetection {
  final int? id;
  final int sessionId;
  final int timestampMs;
  final String chord;
  final double confidence;
  final double volume;
  final int? durationMs;
  final String? roman;

  ChordDetection({
    this.id,
    required this.sessionId,
    required this.timestampMs,
    required this.chord,
    required this.confidence,
    required this.volume,
    this.durationMs,
    this.roman,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'timestamp_ms': timestampMs,
      'chord': chord,
      'confidence': confidence,
      'volume': volume,
      'duration_ms': durationMs,
      'roman': roman,
    };
  }

  factory ChordDetection.fromMap(Map<String, dynamic> map) {
    return ChordDetection(
      id: map['id']?.toInt(),
      sessionId: map['session_id']?.toInt() ?? 0,
      timestampMs: map['timestamp_ms']?.toInt() ?? 0,
      chord: map['chord'] ?? '',
      confidence: map['confidence']?.toDouble() ?? 0.0,
      volume: map['volume']?.toDouble() ?? 0.0,
      durationMs: map['duration_ms']?.toInt(),
      roman: map['roman'],
    );
  }

  ChordDetection copyWith({
    int? id,
    int? sessionId,
    int? timestampMs,
    String? chord,
    double? confidence,
    double? volume,
    int? durationMs,
    String? roman,
  }) {
    return ChordDetection(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestampMs: timestampMs ?? this.timestampMs,
      chord: chord ?? this.chord,
      confidence: confidence ?? this.confidence,
      volume: volume ?? this.volume,
      durationMs: durationMs ?? this.durationMs,
      roman: roman ?? this.roman,
    );
  }

  double get timestampSeconds => timestampMs / 1000.0;
  double? get durationSeconds => durationMs != null ? durationMs! / 1000.0 : null;

  String get formattedTimestamp {
    final seconds = timestampSeconds;
    final minutes = (seconds / 60).floor();
    final remainingSeconds = (seconds % 60).floor();
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String get displayText {
    if (roman != null && roman!.isNotEmpty) {
      return '$chord ($roman)';
    }
    return chord;
  }

  bool get isHighConfidence => confidence >= 0.8;
  bool get isMediumConfidence => confidence >= 0.65 && confidence < 0.8;
  bool get isLowConfidence => confidence < 0.65;
}
