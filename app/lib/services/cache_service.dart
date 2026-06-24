import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';

class CacheService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB('kaamkaaz_cache.db');
    return _db!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cached_jobs (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        saved_at INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> cacheJob(JobModel job) async {
    final db = await database;
    await db.insert(
      'cached_jobs',
      {
        'id': job.id,
        'data': json.encode(job.toJson()),
        'saved_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> uncacheJob(String id) async {
    final db = await database;
    await db.delete(
      'cached_jobs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<JobModel>> getCachedJobs() async {
    final db = await database;
    final result = await db.query('cached_jobs', orderBy: 'saved_at DESC');
    
    return result.map((row) {
      final dataMap = json.decode(row['data'] as String);
      return JobModel.fromJson(dataMap);
    }).toList();
  }

  static Future<void> saveJobList(List<Map<String, dynamic>> jobsData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nearby_feed', json.encode(jobsData));
    await prefs.setInt('nearby_feed_time', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>?> getJobList() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString('nearby_feed');
    final time = prefs.getInt('nearby_feed_time');
    if (dataString != null && time != null) {
      return {
        'data': json.decode(dataString),
        'cachedAt': DateTime.fromMillisecondsSinceEpoch(time),
      };
    }
    return null;
  }
}
