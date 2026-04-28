import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  Color get priorityColor {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.danger;
      case TaskPriority.high:
        return AppColors.warning;
      case TaskPriority.medium:
        return AppColors.info;
      case TaskPriority.low:
        return AppColors.textHint;
    }
  }

  String get priorityLabel {
    switch (task.priority) {
      case TaskPriority.urgent:
        return '紧急';
      case TaskPriority.high:
        return '高';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.low:
        return '低';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: task.isOverdue
            ? Border.all(color: AppColors.danger.withValues(alpha: 0.5))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GestureDetector(
                onTap: onComplete,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: task.isCompleted
                        ? AppColors.success
                        : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted
                          ? AppColors.success
                          : AppColors.textHint,
                      width: 2,
                    ),
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              color: task.isCompleted
                                  ? AppColors.textHint
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'v值: ${task.vValueWeight.toStringAsFixed(1)}h',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                          ),
                        ),
                        if (task.subtasks.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${task.completedSubtasks.length}/${task.subtasks.length}',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        if (task.isOverdue) ...[
                          const SizedBox(width: 12),
                          Text(
                            '已逾期',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: Icon(Icons.close, size: 16, color: AppColors.textHint),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
