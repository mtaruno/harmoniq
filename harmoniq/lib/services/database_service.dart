import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'harmoniq.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        duration INTEGER DEFAULT 0,
        audio_file_path TEXT,
        transcription TEXT,
        confidence_threshold REAL DEFAULT 0.7,
        is_favorite INTEGER DEFAULT 0
      )
    ''');

    // Create transcription_segments table
    await db.execute('''
      CREATE TABLE transcription_segments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        text TEXT NOT NULL,
        confidence REAL NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        speaker_id TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    print('Database tables created successfully');
  }

  // Session operations
  Future<String> createSession({
    required String id,
    required String title,
    String? description,
    double confidenceThreshold = 0.7,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('sessions', {
      'id': id,
      'title': title,
      'description': description,
      'created_at': now,
      'updated_at': now,
      'confidence_threshold': confidenceThreshold,
    });

    print('Created session: $id');
    return id;
  }

  Future<Map<String, dynamic>?> getSession(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllSessions({
    bool favoritesOnly = false,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    String whereClause = favoritesOnly ? 'is_favorite = 1' : '';
    
    return await db.query(
      'sessions',
      where: whereClause.isEmpty ? null : whereClause,
      orderBy: 'updated_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<void> updateSession(String id, Map<String, dynamic> updates) async {
    final db = await database;
    updates['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'sessions',
      updates,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('Updated session: $id');
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('Deleted session: $id');
  }

  Future<void> toggleSessionFavorite(String id) async {
    final db = await database;
    final session = await getSession(id);
    if (session != null) {
      final isFavorite = session['is_favorite'] == 1;
      await updateSession(id, {'is_favorite': isFavorite ? 0 : 1});
    }
  }

  // Transcription segment operations
  Future<void> addTranscriptionSegment({
    required String sessionId,
    required String text,
    required double confidence,
    required int startTime,
    required int endTime,
    String? speakerId,
  }) async {
    final db = await database;
    await db.insert('transcription_segments', {
      'session_id': sessionId,
      'text': text,
      'confidence': confidence,
      'start_time': startTime,
      'end_time': endTime,
      'speaker_id': speakerId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<Map<String, dynamic>>> getTranscriptionSegments(String sessionId) async {
    final db = await database;
    return await db.query(
      'transcription_segments',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'start_time ASC',
    );
  }

  // Settings operations
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  // Utility methods
  Future<int> getSessionCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sessions');
    return result.first['count'] as int;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transcription_segments');
    await db.delete('sessions');
    await db.delete('settings');
    print('Cleared all data from database');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
