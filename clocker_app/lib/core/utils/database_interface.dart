import '../../models/spacetime.dart';
import '../../models/task.dart';
import '../../models/focus_session.dart';
import '../../models/daily_record.dart';
import '../../models/achievement.dart';
import '../../models/app_settings.dart';

abstract class DatabaseHelperInterface {
  Future<String> insertSpacetime(Spacetime st);
  Future<List<Spacetime>> getAllSpacetimes();
  Future<Spacetime?> getSpacetime(String id);
  Future<void> updateSpacetime(Spacetime st);
  Future<void> deleteSpacetime(String id);

  Future<String> insertTask(Task task);
  Future<List<Task>> getTasksForSpacetime(String spacetimeId);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);

  Future<String> insertFocusSession(FocusSession session);
  Future<List<FocusSession>> getFocusSessionsForSpacetime(String spacetimeId);
  Future<void> updateFocusSession(FocusSession session);

  Future<String> insertDailyRecord(DailyRecord record);
  Future<List<DailyRecord>> getDailyRecordsForSpacetime(String spacetimeId);
  Future<DailyRecord?> getDailyRecord(String spacetimeId, DateTime date);
  Future<void> updateDailyRecord(DailyRecord record);

  Future<void> initAchievements();
  Future<List<Achievement>> getAllAchievements();
  Future<void> updateAchievement(Achievement achievement);

  Future<void> saveSettings(AppSettings settings);
  Future<AppSettings> getSettings();

  Future<void> clearAllData();
}
