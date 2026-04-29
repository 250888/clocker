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
    final statusIndex = map['status'];
    final priorityIndex = map['priority'];
    return Task(
      id: map['id'] as String?,
      spacetimeId: map['spacetimeId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      vValueWeight: (map['vValueWeight'] as num?)?.toDouble() ?? 1.0,
      status: TaskStatus.values[(statusIndex is int ? statusIndex : 0).clamp(0, TaskStatus.values.length - 1)],
      priority: TaskPriority.values[(priorityIndex is int ? priorityIndex : 1).clamp(0, TaskPriority.values.length - 1)],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      dueDate:
          map['dueDate'] != null ? DateTime.parse(map['dueDate'] as String) : null,
      subtasks: map['subtasks'] != null && (map['subtasks'] as String).isNotEmpty
          ? (map['subtasks'] as String).split('||')
          : <String>[],
      completedSubtasks:
          map['completedSubtasks'] != null && (map['completedSubtasks'] as String).isNotEmpty
              ? (map['completedSubtasks'] as String).split('||')
              : <String>[],
      verificationNote: map['verificationNote'] as String?,
    );
  }
}
