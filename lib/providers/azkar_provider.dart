// lib/providers/azkar_provider.dart

import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/dhikr_model.dart';

class AzkarProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  // ── State ──────────────────────────────────────────────
  String _activeCategory = DhikrCategory.morning;
  List<Dhikr> _azkar = [];
  Map<int, DhikrProgress> _progress = {};
  bool _loading = false;

  int _streak = 0;
  int _totalCompletions = 0;
  List<Map<String, dynamic>> _last30Stats = [];

  // ── Getters ────────────────────────────────────────────
  String get activeCategory => _activeCategory;
  List<Dhikr> get azkar => _azkar;
  Map<int, DhikrProgress> get progress => _progress;
  bool get loading => _loading;
  int get streak => _streak;
  int get totalCompletions => _totalCompletions;
  List<Map<String, dynamic>> get last30Stats => _last30Stats;

  String get todayStr {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  int get completedCount =>
      _azkar.where((d) => _progress[d.id]?.isCompleted == true).length;

  int get totalCount => _azkar.length;

  double get completionPercent =>
      totalCount == 0 ? 0 : completedCount / totalCount;

  bool get sessionComplete => completedCount == totalCount && totalCount > 0;

  // ── Init / Load ────────────────────────────────────────

  Future<void> init() async {
    await loadCategory(DhikrCategory.morning);
    await refreshStats();
  }

  Future<void> loadCategory(String category) async {
    _loading = true;
    notifyListeners();

    _activeCategory = category;
    _azkar = await _db.getDhikrByCategory(category);
    _progress = await _db.getProgressMap(todayStr, category);

    _loading = false;
    notifyListeners();
  }

  Future<void> refreshStats() async {
    _streak = await _db.getStreakCount();
    _totalCompletions = await _db.getTotalCompletions();
    _last30Stats = await _db.getStatsLast30Days();
    notifyListeners();
  }

  // ── Counter ────────────────────────────────────────────

  Future<void> increment(Dhikr dhikr) async {
    final id = dhikr.id!;
    final existing = _progress[id];
    final current = existing?.currentCount ?? 0;

    if (existing?.isCompleted == true) return; // already done

    final newCount = current + 1;
    final isDone = newCount >= dhikr.repeatCount;

    final updated = DhikrProgress(
      id:           existing?.id,
      dhikrId:      id,
      sessionDate:  todayStr,
      sessionType:  _activeCategory,
      currentCount: newCount,
      isCompleted:  isDone,
    );

    _progress[id] = updated;
    await _db.upsertProgress(updated);

    if (isDone) {
      await _checkSessionComplete();
    }

    notifyListeners();
  }

  Future<void> undo(Dhikr dhikr) async {
    final id = dhikr.id!;
    final existing = _progress[id];
    if (existing == null) return;

    final wasCompleted = existing.isCompleted;
    final newCount = (existing.currentCount - 1).clamp(0, dhikr.repeatCount);
    final updated = existing.copyWith(
      currentCount: newCount,
      isCompleted: false,
    );
    _progress[id] = updated;
    await _db.upsertProgress(updated);

    if (wasCompleted) {
      await _db.unmarkSessionDone(todayStr, _activeCategory);
      await refreshStats();
    }

    notifyListeners();
  }

  Future<void> resetSession() async {
    for (final d in _azkar) {
      if (d.id == null) continue;
      final p = _progress[d.id];
      if (p != null) {
        final reset = p.copyWith(currentCount: 0, isCompleted: false);
        _progress[d.id!] = reset;
        await _db.upsertProgress(reset);
      }
    }
    await _db.unmarkSessionDone(todayStr, _activeCategory);
    await refreshStats();
    notifyListeners();
  }

  Future<void> _checkSessionComplete() async {
    if (sessionComplete) {
      await _db.markSessionDone(todayStr, _activeCategory);
      await refreshStats();
    }
  }

  // ── Custom Dhikr CRUD ─────────────────────────────────

  Future<void> addCustomDhikr({
    required String text,
    required String category,
    String? source,
    String? virtue,
    int repeatCount = 1,
  }) async {
    await _db.insertDhikr(Dhikr(
      category:    category,
      text:        text,
      source:      source,
      virtue:      virtue,
      repeatCount: repeatCount,
      isCustom:    true,
    ));
    if (category == _activeCategory) await loadCategory(category);
  }

  Future<void> updateCustomDhikr(Dhikr d) async {
    await _db.updateDhikr(d);
    await loadCategory(_activeCategory);
  }

  Future<void> deleteDhikr(int id) async {
    await _db.deleteDhikr(id);
    await loadCategory(_activeCategory);
  }

  // ── Export / Import ────────────────────────────────────

  Future<String> exportToFile() => _db.exportToFile();
  Future<String> exportToJson() => _db.exportToJson();

  Future<void> importFromJson(String json) async {
    await _db.importFromJson(json);
    await loadCategory(_activeCategory);
    await refreshStats();
  }
}
