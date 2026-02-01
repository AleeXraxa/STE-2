import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/voice_notes/models/voice_note.dart';

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
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'voice_notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE voice_notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        file_path TEXT NOT NULL,
        created_at TEXT NOT NULL,
        duration INTEGER NOT NULL DEFAULT 0,
        is_playing INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertVoiceNote(VoiceNote voiceNote) async {
    final db = await database;
    return await db.insert(
      'voice_notes',
      {
        'id': voiceNote.id,
        'title': voiceNote.title,
        'file_path': voiceNote.filePath,
        'created_at': voiceNote.createdAt.toIso8601String(),
        'duration': voiceNote.duration,
        'is_playing': voiceNote.isPlaying ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<VoiceNote>> getVoiceNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('voice_notes');

    return List.generate(maps.length, (i) {
      return VoiceNote(
        id: maps[i]['id'],
        title: maps[i]['title'],
        filePath: maps[i]['file_path'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        duration: maps[i]['duration'],
        isPlaying: maps[i]['is_playing'] == 1,
      );
    });
  }

  Future<int> updateVoiceNote(VoiceNote voiceNote) async {
    final db = await database;
    return await db.update(
      'voice_notes',
      {
        'title': voiceNote.title,
        'file_path': voiceNote.filePath,
        'created_at': voiceNote.createdAt.toIso8601String(),
        'duration': voiceNote.duration,
        'is_playing': voiceNote.isPlaying ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [voiceNote.id],
    );
  }

  Future<int> deleteVoiceNote(String id) async {
    final db = await database;
    return await db.delete(
      'voice_notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllVoiceNotes() async {
    final db = await database;
    return await db.delete('voice_notes');
  }

  Future<int> getVoiceNotesCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM voice_notes');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
