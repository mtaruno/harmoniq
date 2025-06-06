class FavoriteProgression {
  final int? id;
  final String name;
  final String? artist;
  final String? key;
  final String chordSequence;
  final String? tags;

  FavoriteProgression({
    this.id,
    required this.name,
    this.artist,
    this.key,
    required this.chordSequence,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artist': artist,
      'key': key,
      'chord_sequence': chordSequence,
      'tags': tags,
    };
  }

  factory FavoriteProgression.fromMap(Map<String, dynamic> map) {
    return FavoriteProgression(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      artist: map['artist'],
      key: map['key'],
      chordSequence: map['chord_sequence'] ?? '',
      tags: map['tags'],
    );
  }

  FavoriteProgression copyWith({
    int? id,
    String? name,
    String? artist,
    String? key,
    String? chordSequence,
    String? tags,
  }) {
    return FavoriteProgression(
      id: id ?? this.id,
      name: name ?? this.name,
      artist: artist ?? this.artist,
      key: key ?? this.key,
      chordSequence: chordSequence ?? this.chordSequence,
      tags: tags ?? this.tags,
    );
  }

  List<String> get tagList {
    if (tags == null || tags!.isEmpty) return [];
    return tags!.split(',').map((tag) => tag.trim()).toList();
  }

  String get displayArtist {
    return artist ?? 'Unknown Artist';
  }

  String get displayKey {
    return key ?? 'Unknown Key';
  }
}
