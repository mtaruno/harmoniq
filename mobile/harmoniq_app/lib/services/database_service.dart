import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';
import '../models/chord_detection.dart';
import '../models/favorite_progression.dart';

class DatabaseService {
  static Database? _database;
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'harmoniq.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Create Session table
        await db.execute('''
          CREATE TABLE Session (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            start_time DATETIME NOT NULL,
            end_time DATETIME,
            detected_key TEXT,
            confidence_threshold REAL DEFAULT 0.7,
            total_duration REAL,
            chord_count INTEGER,
            unique_chords INTEGER,
            notes TEXT
          )
        ''');

        // Create ChordDetection table
        await db.execute('''
          CREATE TABLE ChordDetection (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            timestamp_ms INTEGER,
            chord TEXT,
            confidence REAL,
            volume REAL,
            duration_ms INTEGER,
            roman TEXT,
            FOREIGN KEY (session_id) REFERENCES Session(id) ON DELETE CASCADE
          )
        ''');

        // Create FavoriteProgression table
        await db.execute('''
          CREATE TABLE FavoriteProgression (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            artist TEXT,
            key TEXT,
            chord_sequence TEXT NOT NULL,
            tags TEXT
          )
        ''');

        // Create Settings table
        await db.execute('''
          CREATE TABLE Settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  // Session operations
  Future<int> insertSession(Session session) async {
    final db = await database;
    return await db.insert('Session', session.toMap());
  }

  Future<Session?> getSession(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Session',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Session.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Session>> getAllSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Session',
      orderBy: 'start_time DESC',
    );

    return List.generate(maps.length, (i) {
      return Session.fromMap(maps[i]);
    });
  }

  Future<List<Session>> getRecentSessions({int limit = 5}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Session',
      orderBy: 'start_time DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Session.fromMap(maps[i]);
    });
  }

  Future<void> updateSession(Session session) async {
    final db = await database;
    await db.update(
      'Session',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> deleteSession(int id) async {
    final db = await database;
    await db.delete(
      'Session',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ChordDetection operations
  Future<int> insertChordDetection(ChordDetection chordDetection) async {
    final db = await database;
    return await db.insert('ChordDetection', chordDetection.toMap());
  }

  Future<List<ChordDetection>> getChordDetectionsForSession(int sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ChordDetection',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp_ms ASC',
    );

    return List.generate(maps.length, (i) {
      return ChordDetection.fromMap(maps[i]);
    });
  }

  // FavoriteProgression operations
  Future<int> insertFavoriteProgression(FavoriteProgression progression) async {
    final db = await database;
    return await db.insert('FavoriteProgression', progression.toMap());
  }

  Future<List<FavoriteProgression>> getAllFavoriteProgressions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('FavoriteProgression');

    return List.generate(maps.length, (i) {
      return FavoriteProgression.fromMap(maps[i]);
    });
  }

  Future<void> deleteFavoriteProgression(int id) async {
    final db = await database;
    await db.delete(
      'FavoriteProgression',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Settings operations
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'Settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  // Utility methods
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('ChordDetection');
    await db.delete('Session');
    await db.delete('FavoriteProgression');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
