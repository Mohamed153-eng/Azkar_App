// lib/database/database_helper.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/dhikr_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('azkar.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dhikr (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        category     TEXT    NOT NULL,
        text         TEXT    NOT NULL,
        source       TEXT,
        virtue       TEXT,
        repeat_count INTEGER NOT NULL DEFAULT 1,
        is_custom    INTEGER NOT NULL DEFAULT 0,
        sort_order   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE dhikr_progress (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        dhikr_id      INTEGER NOT NULL,
        session_date  TEXT    NOT NULL,
        session_type  TEXT    NOT NULL,
        current_count INTEGER NOT NULL DEFAULT 0,
        is_completed  INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (dhikr_id) REFERENCES dhikr(id) ON DELETE CASCADE,
        UNIQUE (dhikr_id, session_date, session_type)
      )
    ''');

    await db.execute('''
      CREATE TABLE stats (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        stat_date    TEXT UNIQUE NOT NULL,
        morning_done INTEGER NOT NULL DEFAULT 0,
        evening_done INTEGER NOT NULL DEFAULT 0,
        sleep_done   INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _insertDefaultAzkar(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        await txn.delete('dhikr_progress');
        await txn.delete('dhikr', where: 'is_custom = 0');
        await _insertDefaultAzkar(txn);
      });
    }
  }

  // ─── DHIKR CRUD ──────────────────────────────────────────────────────────

  Future<int> insertDhikr(Dhikr d) async {
    final db = await database;
    return db.insert('dhikr', d.toMap());
  }

  Future<List<Dhikr>> getDhikrByCategory(String category) async {
    final db = await database;
    final rows = await db.query(
      'dhikr',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(Dhikr.fromMap).toList();
  }

  Future<List<Dhikr>> getAllDhikr() async {
    final db = await database;
    final rows =
        await db.query('dhikr', orderBy: 'category, sort_order ASC, id ASC');
    return rows.map(Dhikr.fromMap).toList();
  }

  Future<void> updateDhikr(Dhikr d) async {
    final db = await database;
    await db.update('dhikr', d.toMap(), where: 'id = ?', whereArgs: [d.id]);
  }

  Future<void> deleteDhikr(int id) async {
    final db = await database;
    await db.delete('dhikr', where: 'id = ?', whereArgs: [id]);
    await db.delete('dhikr_progress', where: 'dhikr_id = ?', whereArgs: [id]);
  }

  // ─── PROGRESS ─────────────────────────────────────────────────────────────

  Future<DhikrProgress?> getProgress(
      int dhikrId, String date, String type) async {
    final db = await database;
    final rows = await db.query(
      'dhikr_progress',
      where: 'dhikr_id = ? AND session_date = ? AND session_type = ?',
      whereArgs: [dhikrId, date, type],
    );
    return rows.isEmpty ? null : DhikrProgress.fromMap(rows.first);
  }

  Future<Map<int, DhikrProgress>> getProgressMap(
      String date, String type) async {
    final db = await database;
    final rows = await db.query(
      'dhikr_progress',
      where: 'session_date = ? AND session_type = ?',
      whereArgs: [date, type],
    );
    return {for (var r in rows) r['dhikr_id'] as int: DhikrProgress.fromMap(r)};
  }

  Future<void> upsertProgress(DhikrProgress p) async {
    final db = await database;
    await db.insert(
      'dhikr_progress',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── STATS ─────────────────────────────────────────────────────────────────

  Future<void> markSessionDone(String date, String sessionType) async {
    if (!_trackedSessionTypes.contains(sessionType)) return;

    final db = await database;
    final existing =
        await db.query('stats', where: 'stat_date = ?', whereArgs: [date]);
    if (existing.isEmpty) {
      await db.insert('stats', {
        'stat_date': date,
        'morning_done': sessionType == 'morning' ? 1 : 0,
        'evening_done': sessionType == 'evening' ? 1 : 0,
        'sleep_done': sessionType == 'sleep' ? 1 : 0,
      });
    } else {
      final col = '${sessionType}_done';
      await db.rawUpdate(
        'UPDATE stats SET $col = 1 WHERE stat_date = ?',
        [date],
      );
    }
  }

  Future<void> unmarkSessionDone(String date, String sessionType) async {
    if (!_trackedSessionTypes.contains(sessionType)) return;

    final db = await database;
    final col = '${sessionType}_done';
    await db.rawUpdate(
      'UPDATE stats SET $col = 0 WHERE stat_date = ?',
      [date],
    );
  }

  Future<List<Map<String, dynamic>>> getStatsLast30Days() async {
    final db = await database;
    final from = DateTime.now().subtract(const Duration(days: 29));
    final fromStr = _fmt(from);
    return db.query(
      'stats',
      where: 'stat_date >= ?',
      whereArgs: [fromStr],
      orderBy: 'stat_date ASC',
    );
  }

  Future<int> getStreakCount() async {
    final db = await database;
    final today = _fmt(DateTime.now());
    // Walk backwards from today counting consecutive fully-done days
    int streak = 0;
    DateTime cursor = DateTime.now();
    while (true) {
      final dateStr = _fmt(cursor);
      if (dateStr == today && streak == 0) {
        // today doesn't need to be complete for streak calc – check yesterday onward
      }
      final rows =
          await db.query('stats', where: 'stat_date = ?', whereArgs: [dateStr]);
      if (rows.isEmpty) break;
      final r = rows.first;
      final allDone = r['morning_done'] == 1 &&
          r['evening_done'] == 1 &&
          r['sleep_done'] == 1;
      if (!allDone) break;
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<int> getTotalCompletions() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM stats WHERE morning_done=1 AND evening_done=1 AND sleep_done=1',
    );
    return rows.first['cnt'] as int? ?? 0;
  }

  // ─── EXPORT / IMPORT ──────────────────────────────────────────────────────

  Future<String> exportToJson() async {
    final allDhikr = await getAllDhikr();
    final db = await database;
    final allStats = await db.query('stats');
    final allProgress = await db.query('dhikr_progress');

    final payload = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'dhikr': allDhikr.map((d) => d.toMap()).toList(),
      'stats': allStats,
      'progress': allProgress,
    };
    return jsonEncode(payload);
  }

  Future<String> exportToFile() async {
    final json = await exportToJson();
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/azkar_backup_$ts.json');
    await file.writeAsString(json);
    return file.path;
  }

  Future<void> importFromJson(String jsonStr) async {
    final payload = jsonDecode(jsonStr) as Map<String, dynamic>;
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('dhikr_progress');
      await txn.delete('stats');
      await txn.delete('dhikr');

      final dhikrList = (payload['dhikr'] as List<dynamic>);
      for (final d in dhikrList) {
        final map = Map<String, dynamic>.from(d as Map);
        await txn.insert('dhikr', map,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final s in (payload['stats'] as List<dynamic>)) {
        final map = Map<String, dynamic>.from(s as Map)..remove('id');
        await txn.insert('stats', map,
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final progressList = payload['progress'] as List<dynamic>? ?? [];
      for (final p in progressList) {
        final map = Map<String, dynamic>.from(p as Map)..remove('id');
        await txn.insert(
          'dhikr_progress',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  static const Set<String> _trackedSessionTypes = {
    DhikrCategory.morning,
    DhikrCategory.evening,
    DhikrCategory.sleep,
  };

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }

  // ─── DEFAULT AZKAR SEED ───────────────────────────────────────────────────

  Future<void> _insertDefaultAzkar(DatabaseExecutor db) async {
    final jsonStr = await rootBundle.loadString('assets/azkar-data.json');
    final rows = jsonDecode(jsonStr) as List<dynamic>;

    for (int i = 0; i < rows.length; i++) {
      final row = Map<String, dynamic>.from(rows[i] as Map);
      final dhikr = Dhikr(
        category: _mapWebsiteCategory(row['category'] as String? ?? ''),
        text: row['zekr'] as String? ?? '',
        source: _blankToNull(row['reference'] as String?),
        virtue: _blankToNull(row['description'] as String?),
        repeatCount: row['count'] as int? ?? 1,
        isCustom: false,
        sortOrder: i,
      );
      await db.insert('dhikr', dhikr.toMap());
    }
  }

  String _mapWebsiteCategory(String category) {
    switch (category) {
      case 'أذكار الصباح':
        return DhikrCategory.morning;
      case 'أذكار المساء':
        return DhikrCategory.evening;
      case 'أذكار النوم':
        return DhikrCategory.sleep;
      default:
        return DhikrCategory.custom;
    }
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
