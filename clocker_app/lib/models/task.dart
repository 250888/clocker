import 'package:uuid/uuid.dart';

enum TaskStatus { pending, inProgress, completed, abandoned }
enum TaskPriority { low, medium, high, urgent }

class Task {
  final String id;
  final String spacetimeId;
  final String title;
  final String? description;
  final double vValueWeight;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? dueDate;
  final List<String> subtasks;
  final List<String> completedSubtasks;
  final String? verificationNote;

  Task({
    String? id,
    required this.spacetimeId,
    required this.title,
    this.description,
    this.vValueWeight = 1.0,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    DateTime? createdAt,
    this.completedAt,
    this.dueDate,
    this.subtasks = const [],
    this.completedSubtasks = const [],
    this.verificationNote,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  double get completionPercentage {
    if (subtasks.isEmpty) {
      return status == TaskStatus.completed ? 1.0 : 0.0;
    }
    return completedSubtasks.length / subtasks.length;
  }

  bool get isCompleted => status == TaskStatus.completed;

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != TaskStatus.completed;
  }

  double get effectiveVValue {
    if (status != TaskStatus.completed) return 0;
    return vValueWeight;
  }

  Task copyWith({
    String? title,
    String? description,
    double? vValueWeight,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? completedAt,
    DateTime? dueDate,
    List<String>? subtasks,
    List<String>? completedSubtasks,
    String? verificationNote,
  }) {
    return Task(
      id: id,
      spacetimeId: spacetimeId,
      title: title ?? this.title,
      description: description ?? this.description,
      vValueWeight: vValueWeight ?? this.vValueWeight,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      dueDate: dueDate ?? this.dueDate,
      subtasks: subtasks ?? this.subtasks,
      completedSubtasks: completedSubtasks ?? this.completedSubtasks,
      verificationNote: verificationNote ?? this.verificationNote,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'spacetimeId': spacetimeId,
      'title': title,
      'description': description,
      'vValueWeight': vValueWeight,
      'status': status.index,
      'priority': priority.index,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'subtasks': subtasks.join('||'),
      'completedSubtasks': completedSubtasks.join('||'),
      'verificationNote': verificationNote,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      spacetimeId: map['spacetimeId'],
      title: map['title'],
      description: map['description'],
      vValueWeight: map['vValueWeight'] ?? 1.0,
      status: TaskStatus.values[map['status'] ?? 0],
      priority: TaskPriority.values[map['priority'] ?? 1],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
      dueDate:
          map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      subtasks: map['subtasks'] != null && map['subtasks'].isNotEmpty
          ? map['subtasks'].split('||')
          : [],
      completedSubtasks:
          map['completedSubtasks'] != null && map['completedSubtasks'].isNotEmpty
              ? map['completedSubtasks'].split('||')
              : [],
      verificationNote: map['verificationNote'],
    );
  }
}
