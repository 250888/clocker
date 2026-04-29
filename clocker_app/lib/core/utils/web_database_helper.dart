import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/spacetime.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../../models/daily_record.dart';
import '../../models/achievement.dart';
import '../../models/app_settings.dart';
import 'database_interface.dart';

DatabaseHelperInterface createDatabaseHelper() => WebDatabaseHelper();

class WebDatabaseHelper implements DatabaseHelperInterface {
  static const String _prefix = 'clocker_';

  static const String _spacetimesKey = 'spacetimes';
  static const String _tasksKey = 'tasks';
  static const String _focusSessionsKey = 'focus_sessions';
  static const String _dailyRecordsKey = 'daily_records';
  static const String _achievementsKey = 'achievements';
  static const String _settingsKey = 'settings';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<String>> _getList(String key) async {
    final prefs = await _prefs;
    return prefs.getStringList('$_prefix$key') ?? [];
  }

  Future<void> _setList(String key, List<String> value) async {
    final prefs = await _prefs;
    await prefs.setStringList('$_prefix$key', value);
  }

  // Spacetime CRUD
  Future<String> insertSpacetime(Spacetime st) async {
    final list = await _getList(_spacetimesKey);
    list.insert(0, jsonEncode(st.toMap()));
    await _setList(_spacetimesKey, list);
    return st.id;
  }

  Future<List<Spacetime>> getAllSpacetimes() async {
    final list = await _getList(_spacetimesKey);
    return list.map((s) => Spacetime.fromMap(jsonDecode(s))).toList();
  }

  Future<Spacetime?> getSpacetime(String id) async {
    final spacetimes = await getAllSpacetimes();
    try {
      return spacetimes.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateSpacetime(Spacetime st) async {
    final list = await _getList(_spacetimesKey);
    final idx = list.indexWhere((s) => jsonDecode(s)['id'] == st.id);
    if (idx >= 0) {
      list[idx] = jsonEncode(st.toMap());
      await _setList(_spacetimesKey, list);
    }
  }

  Future<void> deleteSpacetime(String id) async {
    await deleteTasksForSpacetime(id);
    await deleteFocusSessionsForSpacetime(id);
    await deleteDailyRecordsForSpacetime(id);

    final list = await _getList(_spacetimesKey);
    list.removeWhere((s) => jsonDecode(s)['id'] == id);
    await _setList(_spacetimesKey, list);
  }

  // Task CRUD
  Future<String> insertTask(Task task) async {
    final list = await _getList(_tasksKey);
    list.insert(0, jsonEncode(task.toMap()));
    await _setList(_tasksKey, list);
    return task.id;
  }

  Future<List<Task>> getTasksForSpacetime(String spacetimeId) async {
    final list = await _getList(_tasksKey);
    return list
        .map((s) => Task.fromMap(jsonDecode(s)))
        .where((t) => t.spacetimeId == spacetimeId)
        .toList();
  }

  Future<void> updateTask(Task task) async {
    final list = await _getList(_tasksKey);
    final idx = list.indexWhere((s) => jsonDecode(s)['id'] == task.id);
    if (idx >= 0) {
      list[idx] = jsonEncode(task.toMap());
      await _setList(_tasksKey, list);
    }
  }

  Future<void> deleteTask(String id) async {
    final list = await _getList(_tasksKey);
    list.removeWhere((s) => jsonDecode(s)['id'] == id);
    await _setList(_tasksKey, list);
  }

  Future<void> deleteTasksForSpacetime(String spacetimeId) async {
    final list = await _getList(_tasksKey);
    list.removeWhere((s) => jsonDecode(s)['spacetimeId'] == spacetimeId);
    await _setList(_tasksKey, list);
  }

  // FocusSession CRUD
  Future<String> insertFocusSession(FocusSession session) async {
    final list = await _getList(_focusSessionsKey);
    list.insert(0, jsonEncode(session.toMap()));
    await _setList(_focusSessionsKey, list);
    return session.id;
  }

  Future<List<FocusSession>> getFocusSessionsForSpacetime(String spacetimeId) async {
    final list = await _getList(_focusSessionsKey);
    return list
        .map((s) => FocusSession.fromMap(jsonDecode(s)))
        .where((s) => s.spacetimeId == spacetimeId)
        .toList();
  }

  Future<void> updateFocusSession(FocusSession session) async {
    final list = await _getList(_focusSessionsKey);
    final idx = list.indexWhere((s) => jsonDecode(s)['id'] == session.id);
    if (idx >= 0) {
      list[idx] = jsonEncode(session.toMap());
      await _setList(_focusSessionsKey, list);
    }
  }

  Future<void> deleteFocusSessionsForSpacetime(String spacetimeId) async {
    final list = await _getList(_focusSessionsKey);
    list.removeWhere((s) => jsonDecode(s)['spacetimeId'] == spacetimeId);
    await _setList(_focusSessionsKey, list);
  }

  // DailyRecord CRUD
  Future<String> insertDailyRecord(DailyRecord record) async {
    final list = await _getList(_dailyRecordsKey);
    list.insert(0, jsonEncode(record.toMap()));
    await _setList(_dailyRecordsKey, list);
    return record.id;
  }

  Future<List<DailyRecord>> getDailyRecordsForSpacetime(String spacetimeId) async {
    final list = await _getList(_dailyRecordsKey);
    return list
        .map((s) => DailyRecord.fromMap(jsonDecode(s)))
        .where((r) => r.spacetimeId == spacetimeId)
        .toList();
  }

  Future<DailyRecord?> getDailyRecord(String spacetimeId, DateTime date) async {
    final records = await getDailyRecordsForSpacetime(spacetimeId);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    try {
      return records.firstWhere((r) => r.date.toString().startsWith(dateStr));
    } catch (_) {
      return null;
    }
  }

  Future<void> updateDailyRecord(DailyRecord record) async {
    final list = await _getList(_dailyRecordsKey);
    final idx = list.indexWhere((s) => jsonDecode(s)['id'] == record.id);
    if (idx >= 0) {
      list[idx] = jsonEncode(record.toMap());
      await _setList(_dailyRecordsKey, list);
    }
  }

  Future<void> deleteDailyRecordsForSpacetime(String spacetimeId) async {
    final list = await _getList(_dailyRecordsKey);
    list.removeWhere((s) => jsonDecode(s)['spacetimeId'] == spacetimeId);
    await _setList(_dailyRecordsKey, list);
  }

  // Achievement CRUD
  Future<void> initAchievements() async {
    final list = await _getList(_achievementsKey);
    if (list.isEmpty) {
      for (final a in Achievement.defaultAchievements()) {
        list.add(jsonEncode(a.toMap()));
      }
      await _setList(_achievementsKey, list);
    }
  }

  Future<List<Achievement>> getAllAchievements() async {
    final list = await _getList(_achievementsKey);
    return list.map((s) => Achievement.fromMap(jsonDecode(s))).toList();
  }

  Future<void> updateAchievement(Achievement achievement) async {
    final list = await _getList(_achievementsKey);
    final idx = list.indexWhere((s) => jsonDecode(s)['id'] == achievement.id);
    if (idx >= 0) {
      list[idx] = jsonEncode(achievement.toMap());
      await _setList(_achievementsKey, list);
    }
  }

  // Settings
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await _prefs;
    await prefs.setString('$_prefix$_settingsKey', jsonEncode(settings.toMap()));
  }

  Future<AppSettings> getSettings() async {
    final prefs = await _prefs;
    final jsonStr = prefs.getString('$_prefix$_settingsKey');
    if (jsonStr == null) return AppSettings();
    return AppSettings.fromMap(jsonDecode(jsonStr));
  }

  // Clear all data
  Future<void> clearAllData() async {
    final prefs = await _prefs;
    await prefs.remove('$_prefix$_spacetimesKey');
    await prefs.remove('$_prefix$_tasksKey');
    await prefs.remove('$_prefix$_focusSessionsKey');
    await prefs.remove('$_prefix$_dailyRecordsKey');
    await prefs.remove('$_prefix$_achievementsKey');
    await prefs.remove('$_prefix$_settingsKey');
  }
}
