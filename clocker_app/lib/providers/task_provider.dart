import 'package:flutter/material.dart';
import '../models/task.dart';
import '../core/utils/database_factory.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String? _spacetimeId;
  final DatabaseHelperInterface _db = DatabaseFactory.create();

  List<Task> get tasks => _tasks;
  List<Task> get pendingTasks =>
      _tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<Task> get inProgressTasks =>
      _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<Task> get completedTasks =>
      _tasks.where((t) => t.status == TaskStatus.completed).toList();
  List<Task> get overdueTasks => _tasks.where((t) => t.isOverdue).toList();

  double get totalCompletedVValue =>
      completedTasks.fold(0.0, (sum, t) => sum + t.effectiveVValue);

  Future<void> loadTasks(String spacetimeId) async {
    _spacetimeId = spacetimeId;
    _tasks = await _db.getTasksForSpacetime(spacetimeId);
    notifyListeners();
  }

  Future<Task> createTask({
    required String spacetimeId,
    required String title,
    String? description,
    double vValueWeight = 1.0,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    List<String>? subtasks,
  }) async {
    final task = Task(
      spacetimeId: spacetimeId,
      title: title,
      description: description,
      vValueWeight: vValueWeight,
      priority: priority,
      dueDate: dueDate,
      subtasks: subtasks ?? [],
    );
    await _db.insertTask(task);
    _tasks.insert(0, task);
    notifyListeners();
    return task;
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) _tasks[idx] = task;
    notifyListeners();
  }

  Future<void> completeTask(Task task) async {
    final completed = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );
    await updateTask(completed);
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> addSubtask(Task task, String subtaskTitle) async {
    final updated = task.copyWith(subtasks: [...task.subtasks, subtaskTitle]);
    await updateTask(updated);
  }

  Future<void> completeSubtask(Task task, String subtaskTitle) async {
    final updated = task.copyWith(
      completedSubtasks: [...task.completedSubtasks, subtaskTitle],
    );
    await updateTask(updated);
  }

  List<Task> getTasksForToday() {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.status == TaskStatus.completed) return false;
      if (t.dueDate == null) return true;
      final diff = t.dueDate!.difference(now).inDays;
      return diff <= 1;
    }).toList();
  }

  List<Task> getMiniTasks() {
    return pendingTasks.take(3).toList();
  }
}
