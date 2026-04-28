import 'package:flutter/foundation.dart' show kIsWeb;
import 'database_helper.dart';
import 'web_database_helper.dart';

abstract class DatabaseFactory {
  static DatabaseHelperInterface create() {
    if (kIsWeb) {
      return WebDatabaseHelper();
    } else {
      return DatabaseHelper();
    }
  }
}

abstract class DatabaseHelperInterface {
  Future<String> insertSpacetime(dynamic st);
  Future<List<dynamic>> getAllSpacetimes();
  Future<dynamic> getSpacetime(String id);
  Future<void> updateSpacetime(dynamic st);
  Future<void> deleteSpacetime(String id);

  Future<String> insertTask(dynamic task);
  Future<List<dynamic>> getTasksForSpacetime(String spacetimeId);
  Future<void> updateTask(dynamic task);
  Future<void> deleteTask(String id);

  Future<String> insertFocusSession(dynamic session);
  Future<List<dynamic>> getFocusSessionsForSpacetime(String spacetimeId);
  Future<void> updateFocusSession(dynamic session);

  Future<String> insertDailyRecord(dynamic record);
  Future<List<dynamic>> getDailyRecordsForSpacetime(String spacetimeId);
  Future<dynamic> getDailyRecord(String spacetimeId, DateTime date);
  Future<void> updateDailyRecord(dynamic record);

  Future<void> initAchievements();
  Future<List<dynamic>> getAllAchievements();
  Future<void> updateAchievement(dynamic achievement);

  Future<void> saveSettings(dynamic settings);
  Future<dynamic> getSettings();

  Future<void> clearAllData();
}
