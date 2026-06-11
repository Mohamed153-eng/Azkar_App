// lib/database/database_helper.dart

import 'dart:convert';
import 'dart:io';
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
      version: 1,
      onCreate: _createDB,
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
    final rows = await db.query('dhikr', orderBy: 'category, sort_order ASC, id ASC');
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

  Future<DhikrProgress?> getProgress(int dhikrId, String date, String type) async {
    final db = await database;
    final rows = await db.query(
      'dhikr_progress',
      where: 'dhikr_id = ? AND session_date = ? AND session_type = ?',
      whereArgs: [dhikrId, date, type],
    );
    return rows.isEmpty ? null : DhikrProgress.fromMap(rows.first);
  }

  Future<Map<int, DhikrProgress>> getProgressMap(String date, String type) async {
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
    final db = await database;
    final existing = await db.query('stats', where: 'stat_date = ?', whereArgs: [date]);
    if (existing.isEmpty) {
      await db.insert('stats', {
        'stat_date':    date,
        'morning_done': sessionType == 'morning' ? 1 : 0,
        'evening_done': sessionType == 'evening' ? 1 : 0,
        'sleep_done':   sessionType == 'sleep'   ? 1 : 0,
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
      final rows = await db.query('stats', where: 'stat_date = ?', whereArgs: [dateStr]);
      if (rows.isEmpty) break;
      final r = rows.first;
      final allDone = r['morning_done'] == 1 && r['evening_done'] == 1 && r['sleep_done'] == 1;
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
      // Clear existing custom azkar + progress + stats
      await txn.delete('dhikr_progress');
      await txn.delete('stats');
      await txn.delete('dhikr', where: 'is_custom = 1');

      // Re-insert dhikr (only custom ones to avoid duplicating defaults)
      final dhikrList = (payload['dhikr'] as List<dynamic>);
      for (final d in dhikrList) {
        final map = Map<String, dynamic>.from(d as Map);
        if (map['is_custom'] == 1) {
          map.remove('id');
          await txn.insert('dhikr', map, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }

      // Stats
      for (final s in (payload['stats'] as List<dynamic>)) {
        final map = Map<String, dynamic>.from(s as Map)..remove('id');
        await txn.insert('stats', map, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Progress – skip: IDs won't match after re-import of defaults
    });
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> close() async {
    final db = _database;
    if (db != null) await db.close();
    _database = null;
  }

  // ─── DEFAULT AZKAR SEED ───────────────────────────────────────────────────

  Future<void> _insertDefaultAzkar(Database db) async {
    final azkar = _defaultAzkar();
    for (int i = 0; i < azkar.length; i++) {
      await db.insert('dhikr', {...azkar[i].toMap(), 'sort_order': i});
    }
  }

  List<Dhikr> _defaultAzkar() => [
    // ═══════════════ أذكار الصباح ═══════════════
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'أَعُوذُ بِاللهِ مِنَ الشَّيْطَانِ الرَّجِيمِ\n'
          'اللهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
          'لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا '
          'بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ '
          'مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا '
          'يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      source: 'آية الكرسي – البقرة: 255',
      virtue: 'من قرأها حين يصبح أُجير من الجن حتى يمسي',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      source: 'سورة الإخلاص',
      virtue: 'تعدل ثلث القرآن',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
      source: 'سورة الفلق',
      virtue: 'تحصين من الشر والسحر والحسد',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
      source: 'سورة الناس',
      virtue: 'تحصين من وسوسة الشيطان',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ',
      source: 'حصن المسلم',
      virtue: 'من أذكار الصباح المأثورة',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'اللَّهُمَّ أَنْتَ رَبِّي لاَ إِلَهَ إِلاَّ أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لاَ يَغْفِرُ الذُّنُوبَ إِلاَّ أَنْتَ',
      source: 'سيد الاستغفار – البخاري',
      virtue: 'من قالها موقناً فمات من يومه دخل الجنة',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لاَ إِلَهَ إِلاَّ أَنْتَ',
      source: 'أبو داود',
      virtue: 'دعاء العافية في البدن والحواس',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'بِسْمِ اللهِ الَّذِي لاَ يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الأَرْضِ وَلاَ فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
      source: 'أبو داود والترمذي',
      virtue: 'لم يضره شيء',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'رَضِيتُ بِاللهِ رَبًّا، وَبِالإِسْلاَمِ دِيناً، وَبِمُحَمَّدٍ ﷺ نَبِيًّا',
      source: 'أبو داود',
      virtue: 'كان حقاً على الله أن يرضيه يوم القيامة',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
      source: 'مسلم',
      virtue: 'حُطَّت خطاياه وإن كانت مثل زبد البحر',
      repeatCount: 100,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'لاَ إِلَهَ إِلاَّ اللهُ وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
      source: 'البخاري ومسلم',
      virtue: 'كانت له عدل عشر رقاب وكُتب له مائة حسنة',
      repeatCount: 10,
    ),
    const Dhikr(
      category: DhikrCategory.morning,
      text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ',
      source: 'ابن ماجه',
      virtue: 'لم يُسأل عبد شيئاً أفضل من العفو والعافية',
      repeatCount: 1,
    ),

    // ═══════════════ أذكار المساء ═══════════════
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'أَعُوذُ بِاللهِ مِنَ الشَّيْطَانِ الرَّجِيمِ\n'
          'اللهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ '
          'لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا '
          'بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ '
          'مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا '
          'يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
      source: 'آية الكرسي – البقرة: 255',
      virtue: 'من قرأها حين يمسي أُجير من الجن حتى يصبح',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ ۝ اللَّهُ الصَّمَدُ ۝ لَمْ يَلِدْ وَلَمْ يُولَدْ ۝ وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
      source: 'سورة الإخلاص',
      virtue: 'تعدل ثلث القرآن',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ ۝ مِن شَرِّ مَا خَلَقَ ۝ وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ ۝ وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ ۝ وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
      source: 'سورة الفلق',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'بِسْمِ اللهِ الرَّحْمَنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ ۝ مَلِكِ النَّاسِ ۝ إِلَٰهِ النَّاسِ ۝ مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ ۝ الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ ۝ مِنَ الْجِنَّةِ وَالنَّاسِ',
      source: 'سورة الناس',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'اللَّهُمَّ بِكَ أَمْسَيْنَا، وَبِكَ أَصْبَحْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ الْمَصِيرُ',
      source: 'حصن المسلم',
      virtue: 'من أذكار المساء المأثورة',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'اللَّهُمَّ إِنِّي أَمْسَيْتُ أُشْهِدُكَ، وَأُشْهِدُ حَمَلَةَ عَرْشِكَ، وَمَلاَئِكَتَكَ، وَجَمِيعَ خَلْقِكَ، أَنَّكَ أَنْتَ اللهُ لاَ إِلَهَ إِلاَّ أَنْتَ وَحْدَكَ لاَ شَرِيكَ لَكَ، وَأَنَّ مُحَمَّدًا عَبْدُكَ وَرَسُولُكَ',
      source: 'أبو داود',
      virtue: 'أعتقه الله من النار',
      repeatCount: 4,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'اللَّهُمَّ مَا أَمْسَى بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ وَحْدَكَ لاَ شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ وَلَكَ الشُّكْرُ',
      source: 'أبو داود',
      virtue: 'فقد أدى شكر ليلته',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'سُبْحَانَ اللهِ وَبِحَمْدِهِ',
      source: 'مسلم',
      virtue: 'حُطَّت خطاياه وإن كانت مثل زبد البحر',
      repeatCount: 100,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'أَعُوذُ بِكَلِمَاتِ اللهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      source: 'مسلم',
      virtue: 'لم يضره شيء حتى يرتحل من تلك المنزلة',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.evening,
      text: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالآخِرَةِ',
      source: 'ابن ماجه',
      repeatCount: 1,
    ),

    // ═══════════════ أذكار النوم ═══════════════
    const Dhikr(
      category: DhikrCategory.sleep,
      text: 'بِاسْمِكَ اللَّهُمَّ أَمُوتُ وَأَحْيَا',
      source: 'البخاري',
      virtue: 'من أذكار النوم المأثورة',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.sleep,
      text: 'اللَّهُمَّ قِنِي عَذَابَكَ يَوْمَ تَبْعَثُ عِبَادَكَ',
      source: 'أبو داود',
      repeatCount: 3,
    ),
    const Dhikr(
      category: DhikrCategory.sleep,
      text: 'بِسْمِكَ رَبِّي وَضَعْتُ جَنْبِي، وَبِكَ أَرْفَعُهُ، فَإِنْ أَمْسَكْتَ نَفْسِي فَارْحَمْهَا، وَإِنْ أَرْسَلْتَهَا فَاحْفَظْهَا بِمَا تَحْفَظُ بِهِ عِبَادَكَ الصَّالِحِينَ',
      source: 'البخاري ومسلم',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.sleep,
      text: 'اللَّهُمَّ أَسْلَمْتُ نَفْسِي إِلَيْكَ، وَفَوَّضْتُ أَمْرِي إِلَيْكَ، وَوَجَّهْتُ وَجْهِي إِلَيْكَ، وَأَلْجَأْتُ ظَهْرِي إِلَيْكَ، رَغْبَةً وَرَهْبَةً إِلَيْكَ، لاَ مَلْجَأَ وَلاَ مَنْجَا مِنْكَ إِلاَّ إِلَيْكَ، آمَنْتُ بِكِتَابِكَ الَّذِي أَنْزَلْتَ، وَبِنَبِيِّكَ الَّذِي أَرْسَلْتَ',
      source: 'البخاري ومسلم',
      virtue: 'إن مات في ليلته مات على الفطرة',
      repeatCount: 1,
    ),
    const Dhikr(
      category: DhikrCategory.sleep,
      text: 'سُبْحَانَ اللهِ',
      source: 'البخاري ومسلم',
      virtue: 'خير لك من خادم',
      repeatCount: 33,
    ),
    const Dhikr(
      category: DhikrCategory.sleep,
      text: 'الْحَمْدُ للهِ',
      source: 'البخاري ومسلم',
      repeatCount: 33,
    ),
    const Dhikr(
      category: DhikrCategory.sleep,
      text: 'اللهُ أَكْبَرُ',
      source: 'البخاري ومسلم',
      repeatCount: 34,
    ),
    const Dhikr(
      category: DhikrCategory.sleep,
      text: 'آيَةُ الْكُرْسِيِّ\nاللهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ...',
      source: 'البخاري',
      virtue: 'لم يزل عليه من الله حافظ ولا يقربه شيطان حتى يصبح',
      repeatCount: 1,
    ),
  ];
}
